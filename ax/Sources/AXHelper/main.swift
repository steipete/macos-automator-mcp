import Foundation
import ApplicationServices     // AXUIElement*
import AppKit                 // NSRunningApplication, NSWorkspace
import CoreGraphics           // For CGPoint, CGSize etc.

fputs("AX_SWIFT_TOP_SCOPE_FPUTS_STDERR\n", stderr) // For initial stderr check by caller

// MARK: - Main Loop

let decoder = JSONDecoder()
let encoder = JSONEncoder()
// encoder.outputFormatting = .prettyPrinted // Temporarily remove for testing

if CommandLine.arguments.contains("--help") || CommandLine.arguments.contains("-h") {
    let helpText = """
    ax Accessibility Helper v\(BINARY_VERSION)

    Accepts a single JSON command conforming to CommandEnvelope (see Models.swift).
    Input can be provided in one of three ways:
    1. STDIN: If no arguments are provided, reads a single JSON object from stdin.
       The JSON can be multi-line. This is the default interactive/piped mode.
    2. File Path Argument: If a single argument is provided and it is a valid path
       to a file, the tool will read the JSON command from that file.
       Example: ax /path/to/your/command.json
    3. Direct JSON String Argument: If a single argument is provided and it is NOT
       a file path, the tool will attempt to parse the argument directly as a
       JSON string.
       Example: ax '{ "command_id": "test", "command": "query", ... }'

    Output is a single JSON response (see response structs in Models.swift) on stdout.
    """
    print(helpText)
    exit(0)
}

do {
    try checkAccessibilityPermissions() // This needs to be called from main
} catch let error as AccessibilityError {
    // Handle permission error specifically at startup
    let errorResponse = ErrorResponse(command_id: "startup_permissions_check", error: error.description, debug_logs: nil)
    sendResponse(errorResponse)
    exit(error.exitCode) // Exit with a specific code for permission errors
} catch {
    // Catch any other unexpected error during permission check
    let errorResponse = ErrorResponse(command_id: "startup_permissions_check_unexpected", error: "Unexpected error during startup permission check: \(error.localizedDescription)", debug_logs: nil)
    sendResponse(errorResponse)
    exit(1)
}

debug("ax binary version: \(BINARY_VERSION) starting main loop.") // And this debug line

// Function to process a single command from Data
@MainActor
func processCommandData(_ jsonData: Data, initialCommandId: String = "unknown_input_source_error") {
    commandSpecificDebugLoggingEnabled = false // Reset for each command
    collectedDebugLogs = [] // Reset for each command
    resetDebugLogContextForNewCommand() // Reset the version header log flag
    var currentCommandId: String = initialCommandId

    // Attempt to pre-decode command_id for error reporting robustness
    struct CommandIdExtractor: Decodable { let command_id: String }
    if let partialCmd = try? decoder.decode(CommandIdExtractor.self, from: jsonData) {
        currentCommandId = partialCmd.command_id
    } else {
        debug("Failed to pre-decode command_id from provided data.")
    }

    do {
        let cmdEnvelope = try decoder.decode(CommandEnvelope.self, from: jsonData)
        currentCommandId = cmdEnvelope.command_id // Update with the definite command_id

        if cmdEnvelope.debug_logging == true {
            commandSpecificDebugLoggingEnabled = true
            debug("Command-specific debug logging explicitly enabled for this request.")
        }

        let response: Codable
        switch cmdEnvelope.command {
        case .query:
            response = try handleQuery(cmd: cmdEnvelope, isDebugLoggingEnabled: commandSpecificDebugLoggingEnabled)
        case .collectAll:
            response = try handleCollectAll(cmd: cmdEnvelope, isDebugLoggingEnabled: commandSpecificDebugLoggingEnabled)
        case .performAction:
            response = try handlePerform(cmd: cmdEnvelope, isDebugLoggingEnabled: commandSpecificDebugLoggingEnabled)
        case .extractText:
            response = try handleExtractText(cmd: cmdEnvelope, isDebugLoggingEnabled: commandSpecificDebugLoggingEnabled)
        }
        
        sendResponse(response, commandId: currentCommandId)
    } catch let error as AccessibilityError {
        debug("Error (AccessibilityError) for command \(currentCommandId): \(error.description)")
        let errorResponse = ErrorResponse(command_id: currentCommandId, error: error.description, debug_logs: collectedDebugLogs.isEmpty ? nil : collectedDebugLogs)
        sendResponse(errorResponse)
    } catch let error as DecodingError {
        let inputString = String(data: jsonData, encoding: .utf8) ?? "Invalid UTF-8 data"
        debug("Decoding error for command \(currentCommandId): \(error.localizedDescription). Raw input: \(inputString)")
        let detailedError: String
        switch error {
        case .typeMismatch(let type, let context):
            detailedError = "Type mismatch for key '\(context.codingPath.last?.stringValue ?? "unknown key")' (expected \(type)). Path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Details: \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            detailedError = "Value not found for key '\(context.codingPath.last?.stringValue ?? "unknown key")' (expected \(type)). Path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Details: \(context.debugDescription)"
        case .keyNotFound(let key, let context):
            detailedError = "Key not found: '\(key.stringValue)'. Path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Details: \(context.debugDescription)"
        case .dataCorrupted(let context):
            detailedError = "Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Details: \(context.debugDescription)"
        @unknown default:
            detailedError = "Unknown decoding error: \(error.localizedDescription)"
        }
        let finalError = AccessibilityError.jsonDecodingFailed(error)
        let errorResponse = ErrorResponse(command_id: currentCommandId, error: "\(finalError.description) Details: \(detailedError)", debug_logs: collectedDebugLogs.isEmpty ? nil : collectedDebugLogs)
        sendResponse(errorResponse)
    } catch {
        debug("Unhandled/Generic error for command \(currentCommandId): \(error.localizedDescription)")
        let toolError = AccessibilityError.genericError("Unhandled Swift error: \(error.localizedDescription)")
        let errorResponse = ErrorResponse(command_id: currentCommandId, error: toolError.description, debug_logs: collectedDebugLogs.isEmpty ? nil : collectedDebugLogs)
        sendResponse(errorResponse)
    }
}

// Main execution logic
if CommandLine.arguments.count > 1 {
    // Argument(s) provided. First argument (CommandLine.arguments[1]) is the potential file path or JSON string.
    let argument = CommandLine.arguments[1]
    var commandData: Data?

    // Attempt to read as a file path first
    if FileManager.default.fileExists(atPath: argument) {
        do {
            let fileURL = URL(fileURLWithPath: argument)
            commandData = try Data(contentsOf: fileURL)
            debug("Successfully read command from file: \(argument)")
        } catch {
            let errorResponse = ErrorResponse(command_id: "cli_file_read_error", error: "Failed to read command from file '\(argument)': \(error.localizedDescription)", debug_logs: nil)
            sendResponse(errorResponse)
            exit(1)
        }
    } else {
        // If not a file, try to interpret the argument directly as JSON string
        if let data = argument.data(using: .utf8) {
            commandData = data
            debug("Interpreting command directly from argument string.")
        } else {
            let errorResponse = ErrorResponse(command_id: "cli_arg_encoding_error", error: "Failed to encode command argument '\(argument)' to UTF-8 data.", debug_logs: nil)
            sendResponse(errorResponse)
            exit(1)
        }
    }

    if let data = commandData {
        processCommandData(data, initialCommandId: "cli_command")
        exit(0) 
    } else {
        // This case should ideally not be reached if file read or string interpretation was successful or errored out.
        let errorResponse = ErrorResponse(command_id: "cli_no_data_error", error: "Could not obtain command data from argument: \(argument)", debug_logs: nil)
        sendResponse(errorResponse)
        exit(1)
    }

} else {
    // No arguments, read from STDIN (existing behavior)
    debug("No command-line arguments detected. Reading from STDIN.")

    var stdinData: Data? = nil
    if isatty(STDIN_FILENO) == 0 { // Check if STDIN is not a TTY (i.e., it's a pipe or redirection)
        debug("STDIN is a pipe or redirection. Reading all available data.")
        // Read all data from stdin if it's a pipe
        // This approach might be too simplistic if stdin is very large or never closes for some reason.
        // For typical piped JSON, it should be okay.
        var accumulatedData = Data()
        let stdin = FileHandle.standardInput
        while true {
            let data = stdin.availableData
            if data.isEmpty {
                break // End of file or no more data currently available
            }
            accumulatedData.append(data)
        }
        if !accumulatedData.isEmpty {
            stdinData = accumulatedData
        } else {
            debug("No data read from piped STDIN.")
            // Allow to fall through to readLine behavior just in case, or exit? For now, fall through.
        }
    }

    if let data = stdinData {
        // Process the single block of data read from pipe
        processCommandData(data, initialCommandId: "stdin_piped_command")
        debug("Finished processing piped STDIN data.")
    } else {
        // Fallback to line-by-line reading if not a pipe or if pipe was empty
        // This is the original behavior for interactive TTY or if pipe read failed to get data.
        debug("STDIN is a TTY or pipe was empty. Reading line by line.")
        while let line = readLine(strippingNewline: true) {
            guard let jsonData = line.data(using: .utf8) else {
                let errorResponse = ErrorResponse(command_id: "stdin_invalid_input_line", error: "Invalid input from STDIN line: Not UTF-8", debug_logs: nil)
                sendResponse(errorResponse)
                continue
            }
            processCommandData(jsonData, initialCommandId: "stdin_line_command")
        }
        debug("Finished reading from STDIN line by line.")
    }
}

@MainActor
func sendResponse(_ response: Codable, commandId: String? = nil) {
    var responseToSend = response
    var effectiveCommandId = commandId

    // Inject command_id and debug_logs if the response type supports it
    // This uses reflection (Mirror) but a more robust way would be a protocol.
    if var responseWithFields = responseToSend as? ErrorResponse {
        if commandSpecificDebugLoggingEnabled, !collectedDebugLogs.isEmpty {
            responseWithFields.debug_logs = collectedDebugLogs
        }
        if effectiveCommandId == nil { effectiveCommandId = responseWithFields.command_id } else { responseWithFields.command_id = effectiveCommandId! }
        responseToSend = responseWithFields
    } else if var responseWithFields = responseToSend as? QueryResponse {
        if commandSpecificDebugLoggingEnabled, !collectedDebugLogs.isEmpty {
            responseWithFields.debug_logs = collectedDebugLogs
        }
        if effectiveCommandId == nil { effectiveCommandId = responseWithFields.command_id } else { responseWithFields.command_id = effectiveCommandId! }
        responseToSend = responseWithFields
    } else if var responseWithFields = responseToSend as? MultiQueryResponse {
        if commandSpecificDebugLoggingEnabled, !collectedDebugLogs.isEmpty {
            responseWithFields.debug_logs = collectedDebugLogs
        }
         if effectiveCommandId == nil { effectiveCommandId = responseWithFields.command_id } else { responseWithFields.command_id = effectiveCommandId! }
        responseToSend = responseWithFields
    } else if var responseWithFields = responseToSend as? PerformResponse {
        if commandSpecificDebugLoggingEnabled, !collectedDebugLogs.isEmpty {
            responseWithFields.debug_logs = collectedDebugLogs
        }
        if effectiveCommandId == nil { effectiveCommandId = responseWithFields.command_id } else { responseWithFields.command_id = effectiveCommandId! }
        responseToSend = responseWithFields
    } else if var responseWithFields = responseToSend as? TextContentResponse {
        if commandSpecificDebugLoggingEnabled, !collectedDebugLogs.isEmpty {
            responseWithFields.debug_logs = collectedDebugLogs
        }
        if effectiveCommandId == nil { effectiveCommandId = responseWithFields.command_id } else { responseWithFields.command_id = effectiveCommandId! }
        responseToSend = responseWithFields
    }
    // Ensure command_id is set for ErrorResponse even if not directly passed
    else if var errorResp = responseToSend as? ErrorResponse, effectiveCommandId != nil {
        errorResp.command_id = effectiveCommandId!
        responseToSend = errorResp
    }


    do {
        var data = try encoder.encode(responseToSend)
        // Append newline character if not already present
        if let lastChar = data.last, lastChar != UInt8(ascii: "\n") {
            data.append(UInt8(ascii: "\n"))
        }
        FileHandle.standardOutput.write(data)
        fflush(stdout) // Ensure the output is flushed immediately
        // debug("Sent response for commandId \(effectiveCommandId ?? "N/A"): \(String(data: data, encoding: .utf8) ?? "non-utf8 data")")
    } catch {
        // Fallback for encoding errors. This is a critical failure.
        // Constructing a simple JSON string to avoid using the potentially failing encoder.
        let toolError = AccessibilityError.jsonEncodingFailed(error)
        let errorDetails = String(describing: error).replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n") // Basic escaping
        let finalCommandId = effectiveCommandId ?? "unknown_encoding_error"
        // Using the description from AccessibilityError and adding specific details.
        let errorMsg = "{\"command_id\":\"\(finalCommandId)\",\"error\":\"\(toolError.description) Specifics: \(errorDetails)\"}\n"
        fputs(errorMsg, stderr)
        fflush(stderr)
        // Optionally, rethrow or handle more gracefully if this function can throw.
        // For now, just printing to stderr as a last resort.
    }
}

