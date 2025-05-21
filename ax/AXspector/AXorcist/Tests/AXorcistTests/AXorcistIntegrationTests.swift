import Testing
import Foundation
import AppKit // For NSWorkspace, NSRunningApplication
import AXorcist // Import the new library

// MARK: - Test Struct
@MainActor
struct AXHelperIntegrationTests {

    let axBinaryPath = ".build/debug/ax" // Path to the CLI binary, relative to package root (ax/)

    // Helper to run the ax binary with a JSON command
    func runAXCommand(jsonCommand: String) throws -> (output: String, errorOutput: String, exitCode: Int32) {
        let process = Process()
        
        // Assumes `swift test` is run from the package root directory (e.g., /Users/steipete/Projects/macos-automator-mcp/ax)
        let packageRootPath = FileManager.default.currentDirectoryPath 
        let fullExecutablePath = packageRootPath + "/" + axBinaryPath
        
        process.executableURL = URL(fileURLWithPath: fullExecutablePath)
        process.arguments = [jsonCommand]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
        
        return (output, errorOutput, process.terminationStatus)
    }

    // Helper to launch TextEdit
    func launchTextEdit() async throws -> NSRunningApplication {
        let textEditURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.TextEdit")!
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.addsToRecentItems = false 
        
        let app = try await NSWorkspace.shared.openApplication(at: textEditURL, configuration: configuration)
        try await Task.sleep(for: .seconds(2)) // Wait for launch
        
        let ensureDocumentScript = """
        tell application "TextEdit"
            activate
            if not (exists document 1) then
                make new document
            end if
            if (exists window 1) then
                set index of window 1 to 1
            end if
        end tell
        """
        var errorInfo: NSDictionary? = nil
        if let scriptObject = NSAppleScript(source: ensureDocumentScript) {
            let _ = scriptObject.executeAndReturnError(&errorInfo)
            if let error = errorInfo {
                throw AXTestError.appleScriptError("Failed to ensure TextEdit document: \(error)")
            }
        }
        try await Task.sleep(for: .seconds(1))
        return app
    }

    // Helper to quit TextEdit
    func quitTextEdit(app: NSRunningApplication) async {
        let appIdentifier = app.bundleIdentifier ?? "com.apple.TextEdit"
        let quitScript = """
        tell application id "\(appIdentifier)"
            quit saving no
        end tell
        """
        var errorInfo: NSDictionary? = nil
        if let scriptObject = NSAppleScript(source: quitScript) {
            let _ = scriptObject.executeAndReturnError(&errorInfo)
            if let error = errorInfo {
                print("AppleScript error quitting TextEdit: \(error)")
            }
        }
        var attempt = 0
        while !app.isTerminated && attempt < 10 {
            try? await Task.sleep(for: .milliseconds(500))
            attempt += 1
        }
        if !app.isTerminated {
            print("Warning: TextEdit did not terminate gracefully after tests.")
        }
    }

    // Custom error for tests
    enum AXTestError: Error, CustomStringConvertible {
        case appLaunchFailed(String)
        case axCommandFailed(String)
        case jsonDecodingFailed(String)
        case appleScriptError(String)

        var description: String {
            switch self {
            case .appLaunchFailed(let msg): return "App launch failed: \(msg)"
            case .axCommandFailed(let msg): return "AX command failed: \(msg)"
            case .jsonDecodingFailed(let msg): return "JSON decoding failed: \(msg)"
            case .appleScriptError(let msg): return "AppleScript error: \(msg)"
            }
        }
    }
    
    // Decoder for parsing JSON responses
    let decoder = JSONDecoder()

    @Test("Launch TextEdit, Query Main Window, and Quit")
    func testLaunchAndQueryTextEdit() async throws {
        // try await Task.sleep(for: .seconds(3)) // Diagnostic sleep - removed for now

        let textEditApp = try await launchTextEdit()
        #expect(textEditApp.isTerminated == false, "TextEdit should be running after launch")

        defer {
            Task { await quitTextEdit(app: textEditApp) }
        }

        let queryCommand = """
        {
            "command_id": "test_query_textedit",
            "command": "query",
            "application": "com.apple.TextEdit",
            "locator": {
                "criteria": { "AXRole": "AXWindow", "AXMain": "true" }
            },
            "attributes": ["AXTitle", "AXIdentifier", "AXFrame"],
            "output_format": "json_string",
            "debug_logging": true
        }
        """
        let (output, errorOutputFromAX_query, exitCodeQuery) = try runAXCommand(jsonCommand: queryCommand)
        if exitCodeQuery != 0 || output.isEmpty {
            print("AX Command Error Output (STDERR) for query_textedit: ---BEGIN---")
            print(errorOutputFromAX_query)
            print("---END---")
        }
        #expect(exitCodeQuery == 0, "ax query command should exit successfully. AX STDERR: \(errorOutputFromAX_query)")
        #expect(!output.isEmpty, "ax command should produce output.")

        guard let responseData = output.data(using: .utf8) else {
            let dataConversionErrorMsg = "Failed to convert ax output to Data. Output: " + output
            throw AXTestError.jsonDecodingFailed(dataConversionErrorMsg)
        }
        
        let queryResponse = try decoder.decode(QueryResponse.self, from: responseData)
        #expect(queryResponse.error == nil, "QueryResponse should not have an error. See console for details.")
        #expect(queryResponse.attributes != nil, "QueryResponse should have attributes.")

        if let attrsContainerValue = queryResponse.attributes?["json_representation"]?.value,
           let attrsContainer = attrsContainerValue as? String,
           let attrsData = attrsContainer.data(using: .utf8) {
            let decodedAttrs = try? JSONSerialization.jsonObject(with: attrsData, options: []) as? [String: Any]
            #expect(decodedAttrs != nil, "Failed to decode json_representation string")
            #expect(decodedAttrs?["AXTitle"] is String, "AXTitle should be a string in decoded attributes")
        } else {
            #expect(false, "json_representation not found or not a string in attributes")
        }
    }

    @Test("Type Text into TextEdit and Verify")
    func testTypeTextAndVerifyInTextEdit() async throws {
        try await Task.sleep(for: .seconds(3)) // Diagnostic sleep - kept for now, can be removed later

        let textEditApp = try await launchTextEdit()
        #expect(textEditApp.isTerminated == false, "TextEdit should be running for typing test")

        defer {
            Task { await quitTextEdit(app: textEditApp) }
        }

        let dateForText = Date()
        let textToSet = "Hello from Swift Testing! Timestamp: \(dateForText)"
        let escapedTextToSet = textToSet.replacingOccurrences(of: "\"", with: "\\\"")
        let setTextScript = """
        tell application "TextEdit"
            activate
            if not (exists document 1) then make new document
            set text of front document to "\(escapedTextToSet)"
        end tell
        """
        var scriptErrorInfo: NSDictionary? = nil
        if let scriptObject = NSAppleScript(source: setTextScript) {
            let _ = scriptObject.executeAndReturnError(&scriptErrorInfo)
            if let error = scriptErrorInfo {
                throw AXTestError.appleScriptError("Failed to set text in TextEdit: \(error)")
            }
        }
        try await Task.sleep(for: .seconds(1))

        textEditApp.activate(options: [.activateAllWindows])
        try await Task.sleep(for: .milliseconds(500)) // Give activation a moment

        let extractCommand = """
        {
            "command_id": "test_extract_textedit",
            "command": "extract_text",
            "application": "com.apple.TextEdit",
            "locator": {
                "criteria": { "AXRole": "AXTextArea" } 
            },
            "debug_logging": true
        }
        """
        let (output, errorOutputFromAX, exitCode) = try runAXCommand(jsonCommand: extractCommand)
        
        if exitCode != 0 || output.isEmpty {
            print("AX Command Error Output (STDERR) for extract_text: ---BEGIN---")
            print(errorOutputFromAX)
            print("---END---")
        }

        #expect(exitCode == 0, "ax extract_text command should exit successfully. See console for STDERR if this failed. AX STDERR: \(errorOutputFromAX)")
        #expect(!output.isEmpty, "ax extract_text command should produce output for extraction. AX STDERR: \(errorOutputFromAX)")
        
        guard let responseData = output.data(using: .utf8) else {
            let extractDataErrorMsg = "Failed to convert ax extract_text output to Data. Output: " + output + ". AX STDERR: " + errorOutputFromAX
            throw AXTestError.jsonDecodingFailed(extractDataErrorMsg)
        }
        
        let textResponse = try decoder.decode(TextContentResponse.self, from: responseData)
        if let error = textResponse.error {
            print("TextResponse Error: \(error)")
            print("AX Command Error Output (STDERR) for extract_text with TextResponse error: ---BEGIN---")
            print(errorOutputFromAX)
            print("---END---")
            if let debugLogs = textResponse.debug_logs, !debugLogs.isEmpty {
                print("TextResponse DEBUG LOGS: ---BEGIN---")
                debugLogs.forEach { print($0) }
                print("---END DEBUG LOGS---")
            } else {
                print("TextResponse DEBUG LOGS: None or empty.")
            }
        }
        #expect(textResponse.error == nil, "TextContentResponse should not have an error. Error: \(textResponse.error ?? "nil"). AX STDERR: \(errorOutputFromAX)")
        #expect(textResponse.text_content != nil, "TextContentResponse should have text_content. AX STDERR: \(errorOutputFromAX)")
        
        let extractedText = textResponse.text_content?.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(extractedText == textToSet, "Extracted text '\(extractedText ?? "nil")' should match '\(textToSet)'. AX STDERR: \(errorOutputFromAX)")
    }
}

// To run these tests:
// 1. Ensure the `ax` binary is built (as part of the package): `