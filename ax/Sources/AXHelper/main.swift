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
    ax Accessibility Helper v\(AX_BINARY_VERSION)
    Communicates via JSON on stdin/stdout.
    Input JSON: See CommandEnvelope in AXModels.swift
    Output JSON: See response structs (QueryResponse, etc.) in AXModels.swift
    """
    print(helpText)
    exit(0)
}

do {
    try checkAccessibilityPermissions() // This needs to be called from main
} catch let error as AXToolError {
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

debug("ax binary version: \(AX_BINARY_VERSION) starting main loop.") // And this debug line

while let line = readLine(strippingNewline: true) {
    commandSpecificDebugLoggingEnabled = false // Reset for each command
    collectedDebugLogs = [] // Reset for each command
    resetDebugLogContextForNewCommand() // Reset the version header log flag
    var currentCommandId: String = "unknown_line_parse_error" // Default command_id

    guard let jsonData = line.data(using: .utf8) else {
        let errorResponse = ErrorResponse(command_id: currentCommandId, error: "Invalid input: Not UTF-8", debug_logs: nil)
        sendResponse(errorResponse)
        continue
    }

    // Attempt to pre-decode command_id for error reporting robustness
    // This struct can be defined locally or globally if used in more places.
    struct CommandIdExtractor: Decodable { let command_id: String }
    if let partialCmd = try? decoder.decode(CommandIdExtractor.self, from: jsonData) {
        currentCommandId = partialCmd.command_id
    } else {
        // If even partial decoding for command_id fails, keep the default or log more specifically.
        debug("Failed to pre-decode command_id from input: \(line)")
        // currentCommandId remains "unknown_line_parse_error" or a more specific default
    }

    do {
        let cmdEnvelope = try decoder.decode(CommandEnvelope.self, from: jsonData)
        currentCommandId = cmdEnvelope.command_id // Update with the definite command_id

        if cmdEnvelope.debug_logging == true {
            commandSpecificDebugLoggingEnabled = true
            debug("Command-specific debug logging explicitly enabled for this request.")
        }

        let response: Codable
        switch cmdEnvelope.command { // Use the CommandType enum directly
        case .query:
            response = try handleQuery(cmd: cmdEnvelope, isDebugLoggingEnabled: commandSpecificDebugLoggingEnabled)
        case .collectAll: // Matches CommandType.collectAll (raw value "collect_all")
            response = try handleCollectAll(cmd: cmdEnvelope, isDebugLoggingEnabled: commandSpecificDebugLoggingEnabled)
        case .performAction: // Matches CommandType.performAction (raw value "perform_action")
            response = try handlePerform(cmd: cmdEnvelope, isDebugLoggingEnabled: commandSpecificDebugLoggingEnabled)
        case .extractText: // Matches CommandType.extractText (raw value "extract_text")
            response = try handleExtractText(cmd: cmdEnvelope, isDebugLoggingEnabled: commandSpecificDebugLoggingEnabled)
        // No default case needed if all CommandType cases are handled.
        // If CommandType could have more cases not handled here, a default would be required.
        // For now, assuming all defined commands in CommandType will have a handler.
        // If an unknown string comes from JSON, decoding CommandEnvelope itself would fail earlier.
        }
        
        sendResponse(response, commandId: currentCommandId) // Use currentCommandId
    } catch let error as AXToolError {
        debug("Error (AXToolError) for command \(currentCommandId): \(error.description)")
        let errorResponse = ErrorResponse(command_id: currentCommandId, error: error.description, debug_logs: collectedDebugLogs.isEmpty ? nil : collectedDebugLogs)
        sendResponse(errorResponse)
        // Consider exiting with error.exitCode if appropriate for the context
    } catch let error as DecodingError {
        debug("Decoding error for command \(currentCommandId): \(error.localizedDescription). Raw input: \(line)")
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
        let finalError = AXToolError.jsonDecodingFailed(error) // Wrap in AXToolError
        let errorResponse = ErrorResponse(command_id: currentCommandId, error: "\(finalError.description) Details: \(detailedError)", debug_logs: collectedDebugLogs.isEmpty ? nil : collectedDebugLogs)
        sendResponse(errorResponse)
    } catch { // Catch any other errors, including encoding errors from sendResponse itself if they were rethrown
        debug("Unhandled/Generic error for command \(currentCommandId): \(error.localizedDescription)")
        // Wrap generic swift errors into our AXToolError.genericError
        let toolError = AXToolError.genericError("Unhandled Swift error: \(error.localizedDescription)")
        let errorResponse = ErrorResponse(command_id: currentCommandId, error: toolError.description, debug_logs: collectedDebugLogs.isEmpty ? nil : collectedDebugLogs)
        sendResponse(errorResponse)
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
        let toolError = AXToolError.jsonEncodingFailed(error)
        let errorDetails = String(describing: error).replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n") // Basic escaping
        let finalCommandId = effectiveCommandId ?? "unknown_encoding_error"
        // Using the description from AXToolError and adding specific details.
        let errorMsg = "{\"command_id\":\"\(finalCommandId)\",\"error\":\"\(toolError.description) Specifics: \(errorDetails)\"}\n"
        fputs(errorMsg, stderr)
        fflush(stderr)
        // Optionally, rethrow or handle more gracefully if this function can throw.
        // For now, just printing to stderr as a last resort.
    }
}

