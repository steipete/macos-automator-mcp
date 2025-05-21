import AppKit
import XCTest
import Testing
@testable import AXorcist

// Refactored TextEdit setup logic into an @MainActor async function
@MainActor
private func setupTextEditAndGetInfo() async throws -> (pid: pid_t, axAppElement: AXUIElement?) {
    let textEditBundleId = "com.apple.TextEdit"
    var app: NSRunningApplication? = NSRunningApplication.runningApplications(withBundleIdentifier: textEditBundleId).first
    
    if app == nil {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: textEditBundleId) else {
            throw TestError.generic("Could not find URL for TextEdit application.")
        }
        
        print("Attempting to launch TextEdit from URL: \(url.path)")
        // Use the older launchApplication API which sometimes is more robust in test environments
        // despite deprecation. Configure for async and no activation initially.
        let configuration: [NSWorkspace.LaunchConfigurationKey: Any] = [:] // Empty config for older API
        do {
            app = try NSWorkspace.shared.launchApplication(at: url, 
                                                             options: [.async, .withoutActivation], 
                                                             configuration: configuration)
            print("launchApplication call completed. App PID if returned: \(app?.processIdentifier ?? -1)")
        } catch {
            throw TestError.appNotRunning("Failed to launch TextEdit using launchApplication(at:options:configuration:): \(error.localizedDescription)")
        }

        // Wait for the app to appear in running applications list
        var launchedApp: NSRunningApplication? = nil
        for attempt in 1...10 { // Retry for up to 10 * 0.5s = 5 seconds
            launchedApp = NSRunningApplication.runningApplications(withBundleIdentifier: textEditBundleId).first
            if launchedApp != nil { 
                print("TextEdit found running after launch, attempt \(attempt).")
                break
            }
            try await Task.sleep(for: .milliseconds(500))
            print("Waiting for TextEdit to appear in running list... attempt \(attempt)")
        }
        
        guard let runningAppAfterLaunch = launchedApp else {
             throw TestError.appNotRunning("TextEdit did not appear in running applications list after launch attempt.")
        }
        app = runningAppAfterLaunch // Assign the found app
    }

    guard let runningApp = app else {
        // This should be redundant now due to the guard above, but as a final safety.
        throw TestError.appNotRunning("TextEdit is unexpectedly nil before activation checks.")
    }

    let pid = runningApp.processIdentifier
    let axAppElement = AXUIElementCreateApplication(pid)

    // Activate and ensure a window
    if !runningApp.isActive {
        runningApp.activate(options: [.activateAllWindows])
        try await Task.sleep(for: .seconds(1.5)) // Wait for activation
    }

    var window: AnyObject?
    let resultCopyAttribute = AXUIElementCopyAttributeValue(axAppElement, ApplicationServices.kAXWindowsAttribute as CFString, &window)
    if resultCopyAttribute != AXError.success || (window as? [AXUIElement])?.isEmpty ?? true {
        let appleScript = """
        tell application "System Events"
            tell process "TextEdit"
                set frontmost to true
                keystroke "n" using command down
            end tell
        end tell
        """
        var errorDict: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            scriptObject.executeAndReturnError(&errorDict)
            if let error = errorDict {
                throw TestError.appleScriptError("Failed to create new document in TextEdit: \(error)")
            }
            try await Task.sleep(for: .seconds(2)) // Wait for new document window
        }
    }
    
    // Re-check activation
    if !runningApp.isActive {
        runningApp.activate(options: [.activateAllWindows])
        try await Task.sleep(for: .seconds(1))
    }

    // Optional: Confirm focused element directly (for debugging setup)
    var cfFocusedElement: CFTypeRef?
    let status = AXUIElementCopyAttributeValue(axAppElement, ApplicationServices.kAXFocusedUIElementAttribute as CFString, &cfFocusedElement)
    if status == AXError.success, cfFocusedElement != nil {
        print("AX API successfully got a focused element during setup.")
    } else {
        print("AX API did not get a focused element during setup. Status: \(status.rawValue). This might be okay.")
    }
    
    return (pid, axAppElement)
}

@MainActor
private func closeTextEdit() async {
    let textEditBundleId = "com.apple.TextEdit"
    guard let textEdit = NSRunningApplication.runningApplications(withBundleIdentifier: textEditBundleId).first else {
        return // Not running
    }
    
    textEdit.terminate()
    // Give it a moment to terminate gracefully
    for _ in 0..<5 { // Check for up to 2.5 seconds
        if textEdit.isTerminated { break }
        try? await Task.sleep(for: .milliseconds(500))
    }
    
    if !textEdit.isTerminated {
        textEdit.forceTerminate()
        try? await Task.sleep(for: .milliseconds(500)) // Brief pause after force terminate
    }
}

private func runAXORCCommand(arguments: [String]) throws -> (String?, String?, Int32) {
    let axorcUrl = productsDirectory.appendingPathComponent("axorc")

    let process = Process()
    process.executableURL = axorcUrl
    process.arguments = arguments

    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    try process.run()
    process.waitUntilExit()

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

    let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Strip the AXORC_JSON_OUTPUT_PREFIX if present
    let cleanOutput = stripJSONPrefix(from: output)
    
    return (cleanOutput, errorOutput, process.terminationStatus)
}

// Helper to create a temporary file with content
private func createTempFile(content: String) throws -> String {
    let tempDir = FileManager.default.temporaryDirectory
    let fileName = UUID().uuidString + ".json"
    let fileURL = tempDir.appendingPathComponent(fileName)
    try content.write(to: fileURL, atomically: true, encoding: .utf8)
    return fileURL.path
}

// Helper to strip the JSON output prefix from axorc output
private func stripJSONPrefix(from output: String?) -> String? {
    guard let output = output else { return nil }
    let prefix = "AXORC_JSON_OUTPUT_PREFIX:::"
    if output.hasPrefix(prefix) {
        return String(output.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return output
}

// Function to run axorc with STDIN input
private func runAXORCCommandWithStdin(inputJSON: String, arguments: [String]) throws -> (String?, String?, Int32) {
    let axorcUrl = productsDirectory.appendingPathComponent("axorc")

    let process = Process()
    process.executableURL = axorcUrl
    // Ensure --stdin is included if not already present, as axorc.swift now uses it as a flag
    var effectiveArguments = arguments
    if !effectiveArguments.contains("--stdin") {
        effectiveArguments.append("--stdin")
    }
    process.arguments = effectiveArguments
    
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    let inputPipe = Pipe()

    process.standardOutput = outputPipe
    process.standardError = errorPipe
    process.standardInput = inputPipe

    try process.run()

    // Write to STDIN
    if let inputData = inputJSON.data(using: .utf8) {
        try inputPipe.fileHandleForWriting.write(contentsOf: inputData)
        inputPipe.fileHandleForWriting.closeFile() // Close STDIN to signal EOF
    } else {
        // Handle error: inputJSON could not be converted to Data
        inputPipe.fileHandleForWriting.closeFile() // Still close it
        // Consider throwing an error or logging
        print("Warning: Could not convert inputJSON to Data for STDIN.")
    }
    
    process.waitUntilExit()

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

    let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    
    let cleanOutput = stripJSONPrefix(from: output)
    
    return (cleanOutput, errorOutput, process.terminationStatus)
}

// MARK: - Codable Structs for Testing

// Based on axorc.swift and AXorcist.swift
enum CommandType: String, Codable {
    case ping
    case getFocusedElement
    // Add other command types as they are implemented in axorc
    case collectAll, query, describeElement, getAttributes, performAction, extractText, batch
}

struct CommandEnvelope: Codable {
    let command_id: String
    let command: CommandType
    let application: String?
    let attributes: [String]?
    let payload: [String: AnyCodable]? // Using AnyCodable for flexibility
    let debug_logging: Bool?

    init(command_id: String, command: CommandType, application: String? = nil, attributes: [String]? = nil, payload: [String: AnyCodable]? = nil, debug_logging: Bool? = nil) {
        self.command_id = command_id
        self.command = command
        self.application = application
        self.attributes = attributes
        self.payload = payload
        self.debug_logging = debug_logging
    }
}

// Matches SimpleSuccessResponse implicitly defined in axorc.swift for ping
struct SimpleSuccessResponse: Codable {
    let command_id: String
    let success: Bool // Assuming true for success responses
    let status: String? // e.g., "pong"
    let message: String
    let details: String?
    let debug_logs: [String]?

    // Adding an explicit init to match how it might be constructed if `success` is always true for this type
    init(command_id: String, success: Bool = true, status: String?, message: String, details: String?, debug_logs: [String]?) {
        self.command_id = command_id
        self.success = success
        self.status = status
        self.message = message
        self.details = details
        self.debug_logs = debug_logs
    }
}

// Matches ErrorResponse implicitly defined in axorc.swift
struct ErrorResponse: Codable {
    let command_id: String
    let success: Bool // Assuming false for error responses
    let error: ErrorDetail // Changed from String to ErrorDetail struct

    struct ErrorDetail: Codable { // Nested struct for error message
        let message: String
    }
    let debug_logs: [String]?
    
    // Custom init if needed, for now relying on synthesized one after struct change
     init(command_id: String, success: Bool = false, error: ErrorDetail, debug_logs: [String]?) {
        self.command_id = command_id
        self.success = success
        self.error = error
        self.debug_logs = debug_logs
    }
}


// For AXElement.attributes which can be [String: Any]
// Using a simplified AnyCodable for testing purposes
struct AnyCodable: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = ()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any?]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}


struct AXElementData: Codable { // Renamed from AXElement to avoid conflict if AXorcist.AXElement is imported
    let attributes: [String: AnyCodable]? // Dictionary of attributes
    let path: [String]? // Optional path from root
    // Add other fields like role, description if they become part of the AXElement structure in axorc output

    // Explicit init to allow nil for attributes and path
    init(attributes: [String: AnyCodable]? = nil, path: [String]? = nil) {
        self.attributes = attributes
        self.path = path
    }
}

// Matches QueryResponse implicitly defined in axorc.swift for getFocusedElement
struct QueryResponse: Codable {
    let command_id: String
    let success: Bool
    let command: String // e.g., "getFocusedElement"
    let data: AXElementData? // This will contain the AX element's data
    // let attributes: [String: AnyCodable]? // This was redundant with data.attributes in axorc.swift, remove if also removed there
    let error: ErrorDetail? // Changed from String?
    let debug_logs: [String]?
}


// MARK: - Test Cases

@Test("Test Ping via STDIN")
func testPingViaStdin() async throws {
    let inputJSON = """
    {
        "command_id": "test_ping_stdin",
        "command": "ping",
        "payload": {
            "message": "Hello from testPingViaStdin"
        }
    }
    """
    let (output, errorOutput, terminationStatus) = try runAXORCCommandWithStdin(inputJSON: inputJSON, arguments: ["--stdin"])

    #expect(terminationStatus == 0, "axorc command failed with status \(terminationStatus). Error: \(errorOutput ?? "N/A")")
    #expect(errorOutput == nil || errorOutput!.isEmpty, "Expected no error output, but got: \(errorOutput!)")
    
    guard let output else {
        #expect(Bool(false), "Output was nil")
        return
    }

    let responseData = Data(output.utf8)
    let decodedResponse = try JSONDecoder().decode(SimpleSuccessResponse.self, from: responseData)
    #expect(decodedResponse.success == true)
    #expect(decodedResponse.message == "Ping handled by AXORCCommand. Input source: STDIN", "Unexpected success message: \(decodedResponse.message)")
    #expect(decodedResponse.details == "Hello from testPingViaStdin")
}

@Test("Test Ping via --file")
func testPingViaFile() async throws {
    let payloadMessage = "Hello from testPingViaFile"
    let inputJSON = """
    {
        "command_id": "test_ping_file",
        "command": "ping",
        "payload": { "message": "\(payloadMessage)" }
    }
    """
    let tempFilePath = try createTempFile(content: inputJSON)
    defer { try? FileManager.default.removeItem(atPath: tempFilePath) }

    // axorc needs --file flag
    let (output, errorOutput, terminationStatus) = try runAXORCCommand(arguments: ["--file", tempFilePath])

    #expect(terminationStatus == 0, "axorc command failed with status \(terminationStatus). Error: \(errorOutput ?? "N/A")")
    #expect(errorOutput == nil || errorOutput!.isEmpty, "Expected no error output, but got: \(errorOutput ?? "N/A")")
    
    guard let output else {
        #expect(Bool(false), "Output was nil")
        return
    }

    let responseData = Data(output.utf8)
    // Use the updated SimpleSuccessResponse for decoding
    let decodedResponse = try JSONDecoder().decode(SimpleSuccessResponse.self, from: responseData)
    #expect(decodedResponse.success == true)
    #expect(decodedResponse.message.lowercased().contains("file: \(tempFilePath.lowercased())"), "Message should contain file path. Got: \(decodedResponse.message)")
    #expect(decodedResponse.details == payloadMessage)
}


@Test("Test Ping via direct positional argument")
func testPingViaDirectPayload() async throws {
    let payloadMessage = "Hello from testPingViaDirectPayload"
    // Ensure the JSON string is compact and valid for a command-line argument
    let inputJSON = "{\"command_id\":\"test_ping_direct\",\"command\":\"ping\",\"payload\":{\"message\":\"\(payloadMessage)\"}}"

    let (output, errorOutput, terminationStatus) = try runAXORCCommand(arguments: [inputJSON]) // No --stdin or --file for direct

    #expect(terminationStatus == 0, "axorc command failed with status \(terminationStatus). Error: \(errorOutput ?? "N/A")")
    #expect(errorOutput == nil || errorOutput!.isEmpty, "Expected no error output, but got: \(errorOutput ?? "N/A")")
    
    guard let output else {
        #expect(Bool(false), "Output was nil")
        return
    }

    let responseData = Data(output.utf8)
    let decodedResponse = try JSONDecoder().decode(SimpleSuccessResponse.self, from: responseData)
    #expect(decodedResponse.success == true)
    #expect(decodedResponse.message.contains("Direct Argument Payload"), "Unexpected success message: \(decodedResponse.message)")
    #expect(decodedResponse.details == payloadMessage)
}

@Test("Test Error: Multiple Input Methods (stdin and file)")
func testErrorMultipleInputMethods() async throws {
    let inputJSON = """
    {
        "command_id": "test_error_multiple_inputs",
        "command": "ping",
        "payload": { "message": "This should not be processed" }
    }
    """
    let tempFilePath = try createTempFile(content: "{}") // Empty JSON for file
    defer { try? FileManager.default.removeItem(atPath: tempFilePath) }

    // Pass arguments that trigger multiple inputs, including --stdin for runAXORCCommandWithStdin
    let (output, errorOutput, terminationStatus) = try runAXORCCommandWithStdin(inputJSON: inputJSON, arguments: ["--file", tempFilePath]) // --stdin is added by the helper

    // axorc.swift now prints error to STDOUT and exits 0
    #expect(terminationStatus == 0, "axorc command should return 0 with error on stdout. Status: \(terminationStatus). Error STDOUT: \(output ?? "nil"). Error STDERR: \(errorOutput ?? "nil")")
    
    guard let output, !output.isEmpty else {
        #expect(Bool(false), "Output was nil or empty")
        return
    }
    
    // Use the updated ErrorResponse for decoding
    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: Data(output.utf8))
    #expect(errorResponse.success == false)
    #expect(errorResponse.error.message.contains("Multiple input flags specified"), "Unexpected error message: \(errorResponse.error.message)")
}


@Test("Test Error: No Input Provided for Ping")
func testErrorNoInputProvidedForPing() async throws {
    // Run axorc with no input flags or direct payload
    let (output, errorOutput, terminationStatus) = try runAXORCCommand(arguments: [])

    #expect(terminationStatus == 0, "axorc should return 0 with error on stdout. Status: \(terminationStatus). Error STDOUT: \(output ?? "nil"). Error STDERR: \(errorOutput ?? "nil")")

    guard let output, !output.isEmpty else {
        #expect(Bool(false), "Output was nil or empty for no input test.")
        return
    }
    
    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: Data(output.utf8))
    #expect(errorResponse.success == false)
    #expect(errorResponse.command_id == "input_error", "Expected command_id to be input_error, got \(errorResponse.command_id)")
    #expect(errorResponse.error.message.contains("No JSON input method specified"), "Unexpected error message for no input: \(errorResponse.error.message)")
}

// The original failing test, now adapted
@Test("Launch TextEdit, Get Focused Element via STDIN")
func testLaunchAndQueryTextEdit() async throws {
    // Close TextEdit if it's running from a previous test
    await closeTextEdit() // Now async and @MainActor
    try await Task.sleep(for: .milliseconds(500)) // Pause after closing

    // Setup TextEdit (launch, activate, ensure window) - this is @MainActor
    let (pid, _) = try await setupTextEditAndGetInfo()
    #expect(pid != 0, "PID should not be zero after TextEdit setup")
    // axAppElement from setupTextEditAndGetInfo is not directly used hereafter, but setup ensures app is ready.

    // Prepare the JSON command for axorc
    let commandId = "focused_textedit_test_\(UUID().uuidString)"
    let attributesToFetch: [String] = [
        ApplicationServices.kAXRoleAttribute as String, 
        ApplicationServices.kAXRoleDescriptionAttribute as String, 
        ApplicationServices.kAXValueAttribute as String, 
        "AXPlaceholderValue" // Custom attribute
    ]

    let commandEnvelope = CommandEnvelope(
        command_id: commandId,
        command: .getFocusedElement,
        application: "com.apple.TextEdit",
        attributes: attributesToFetch,
        debug_logging: true
    )

    let encoder = JSONEncoder()
    let inputJSONData = try encoder.encode(commandEnvelope)
    guard let inputJSON = String(data: inputJSONData, encoding: .utf8) else {
        throw TestError.generic("Failed to encode CommandEnvelope to JSON string")
    }
    
    print("Input JSON for axorc:\n\(inputJSON)")

    let (output, errorOutput, terminationStatus) = try runAXORCCommandWithStdin(inputJSON: inputJSON, arguments: ["--debug"])

    print("axorc STDOUT:\n\(output ?? "nil")")
    print("axorc STDERR:\n\(errorOutput ?? "nil")")
    print("axorc Termination Status: \(terminationStatus)")

    #expect(terminationStatus == 0, "axorc command failed with status \(terminationStatus). Error Output: \(errorOutput ?? "N/A")")

    guard let outputJSON = output, !outputJSON.isEmpty else {
        throw TestError.generic("axorc output was nil or empty. STDERR: \(errorOutput ?? "N/A")")
    }

    let decoder = JSONDecoder()
    // Ensure outputJSON is a non-optional String here before using .utf8
    guard let responseData = outputJSON.data(using: .utf8) else { // Using String.data directly
        throw TestError.generic("Failed to convert axorc output string to Data. Output: \(outputJSON)")
    }
    
    let queryResponse: QueryResponse
    do {
        queryResponse = try decoder.decode(QueryResponse.self, from: responseData)
    } catch {
        print("JSON Decoding Error: \(error)")
        print("Problematic JSON string from axorc: \(outputJSON)") // Print the problematic JSON
        throw TestError.generic("Failed to decode QueryResponse from axorc: \(error.localizedDescription). Original JSON: \(outputJSON)")
    }

    #expect(queryResponse.success == true, "axorc command was not successful. Error: \(queryResponse.error?.message ?? "Unknown error"). Logs: \(queryResponse.debug_logs?.joined(separator: "\n") ?? "")")
    #expect(queryResponse.command_id == commandId)
    #expect(queryResponse.command == CommandType.getFocusedElement.rawValue) // Compare with rawValue

    guard let elementData = queryResponse.data else {
        throw TestError.generic("QueryResponse data is nil. Error: \(queryResponse.error?.message ?? "N/A"). Logs: \(queryResponse.debug_logs?.joined(separator: "\n") ?? "")")
    }

    // Validate attributes (example)
    // Cast kAXTextAreaRole (CFString) to String for comparison
    // Use ApplicationServices for standard AX constants
    let expectedRole = ApplicationServices.kAXTextAreaRole as String
    let actualRole = elementData.attributes?[ApplicationServices.kAXRoleAttribute as String]?.value as? String
    #expect(actualRole == expectedRole, "Focused element role should be '\(expectedRole)'. Got: '\(actualRole ?? "nil")'. Attributes: \(elementData.attributes?.keys.map { $0 } ?? [])")
    
    // Use ApplicationServices.kAXValueAttribute and cast to String for key
    #expect(elementData.attributes?.keys.contains(ApplicationServices.kAXValueAttribute as String) == true, "Focused element attributes should contain kAXValueAttribute as it was requested.")

    if let logs = queryResponse.debug_logs, !logs.isEmpty {
        print("axorc Debug Logs:")
        logs.forEach { print($0) }
    }
    
    // Clean up TextEdit
    await closeTextEdit() // Now async and @MainActor
}

// TestError enum definition
enum TestError: Error, CustomStringConvertible {
    case appNotRunning(String)
    case axError(String)
    case appleScriptError(String)
    case generic(String)

    var description: String {
        switch self {
        case .appNotRunning(let s): return "AppNotRunning: \(s)"
        case .axError(let s): return "AXError: \(s)"
        case .appleScriptError(let s): return "AppleScriptError: \(s)"
        case .generic(let s): return "GenericTestError: \(s)"
        }
    }
}

// Products directory helper (if not already present from previous steps)
var productsDirectory: URL {
  #if os(macOS)
    // First, try the .xctest bundle method (works well in Xcode)
    for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
        return bundle.bundleURL.deletingLastPathComponent()
    }
    
    // Fallback for SPM command-line tests if .xctest bundle isn't found as expected.
    // This navigates up from the test file to the package root, then to .build/debug.
    let currentFileURL = URL(fileURLWithPath: #filePath)
    // Assuming Tests/AXorcistTests/AXorcistIntegrationTests.swift structure:
    // currentFileURL.deletingLastPathComponent() // AXorcistTests directory
    //   .deletingLastPathComponent() // Tests directory
    //   .deletingLastPathComponent() // AXorcist package root directory
    let packageRootPath = currentFileURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    
    // Try common build paths for SwiftPM
    let buildPathsToTry = [
        packageRootPath.appendingPathComponent(".build/debug"),
        packageRootPath.appendingPathComponent(".build/arm64-apple-macosx/debug"),
        packageRootPath.appendingPathComponent(".build/x86_64-apple-macosx/debug")
    ]
    
    let fileManager = FileManager.default
    for path in buildPathsToTry {
        // Check if the directory exists and contains the axorc executable
        if fileManager.fileExists(atPath: path.appendingPathComponent("axorc").path) {
            return path
        }
    }

    fatalError("couldn\'t find the products directory via Bundle or SPM fallback. Package root guessed as: \(packageRootPath.path). Searched paths: \(buildPathsToTry.map { $0.path }.joined(separator: ", "))")
  #else
    return Bundle.main.bundleURL
  #endif
} 