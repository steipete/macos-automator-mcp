import Foundation
import AXorcist
import ArgumentParser

let AXORC_VERSION = "0.1.2a-config_fix"

struct AXORCCommand: ParsableCommand { 
    static let configuration = CommandConfiguration(
        commandName: "axorc", // commandName must come before abstract
        abstract: "AXORC CLI - Handles JSON commands via various input methods. Version \\(AXORC_VERSION)"
    )

    @Flag(name: .long, help: "Enable debug logging for the command execution.")
    var debug: Bool = false

    @Flag(name: .long, help: "Read JSON payload from STDIN.")
    var stdin: Bool = false

    @Option(name: .long, help: "Read JSON payload from the specified file path.")
    var file: String?

    @Argument(help: "Read JSON payload directly from this string argument. If other input flags (--stdin, --file) are used, this argument is ignored.")
    var directPayload: String? = nil

    mutating func run() throws {
        var localDebugLogs: [String] = [] 
        if debug {
            localDebugLogs.append("Debug logging enabled by --debug flag.")
        }

        var receivedJsonString: String? = nil
        var inputSourceDescription: String = "Unspecified"
        var detailedInputError: String? = nil

        let activeInputFlags = (stdin ? 1 : 0) + (file != nil ? 1 : 0)
        let positionalPayloadProvided = directPayload != nil && !(directPayload?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

        if activeInputFlags > 1 {
            detailedInputError = "Error: Multiple input flags specified (--stdin, --file). Only one is allowed."
            inputSourceDescription = detailedInputError!
        } else if stdin {
            inputSourceDescription = "STDIN"
            let stdInputHandle = FileHandle.standardInput
            let stdinData = stdInputHandle.readDataToEndOfFile() 
            if let str = String(data: stdinData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
                receivedJsonString = str
                localDebugLogs.append("Successfully read \(str.count) chars from STDIN.")
            } else {
                detailedInputError = "Warning: STDIN flag specified, but no data or empty data received."
                localDebugLogs.append(detailedInputError!)
            }
        } else if let filePath = file {
            inputSourceDescription = "File: \(filePath)"
            do {
                let fileContent = try String(contentsOfFile: filePath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
                if fileContent.isEmpty {
                    detailedInputError = "Error: File '\(filePath)' is empty."
                } else {
                    receivedJsonString = fileContent
                    localDebugLogs.append("Successfully read from file: \(filePath)")
                }
            } catch {
                detailedInputError = "Error: Failed to read from file '\(filePath)': \(error.localizedDescription)" 
            }
            if detailedInputError != nil { localDebugLogs.append(detailedInputError!) }
        } else if let payload = directPayload, positionalPayloadProvided {
            inputSourceDescription = "Direct Argument Payload"
            receivedJsonString = payload.trimmingCharacters(in: .whitespacesAndNewlines)
            localDebugLogs.append("Using direct argument payload. Length: \(receivedJsonString?.count ?? 0)")
        } else if directPayload != nil && !positionalPayloadProvided { 
             detailedInputError = "Error: Direct argument payload was provided but was an empty string."
             inputSourceDescription = detailedInputError!
             localDebugLogs.append(detailedInputError!)
        } else {
            detailedInputError = "No JSON input method specified or chosen method yielded no data."
            inputSourceDescription = detailedInputError!
            localDebugLogs.append(detailedInputError!)
        }
        if detailedInputError != nil { localDebugLogs.append(detailedInputError!) }

        let errorStringForDisplay = detailedInputError ?? "None"

        print("AXORC_JSON_OUTPUT_PREFIX:::")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        if let errorToReport = detailedInputError, receivedJsonString == nil {
            let errResponse = ErrorResponse(command_id: "input_error", error: errorToReport, debug_logs: debug ? localDebugLogs : nil)
            if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
            return
        }

        guard let jsonToProcess = receivedJsonString, !jsonToProcess.isEmpty else {
            let finalErrorMsg = detailedInputError ?? "No JSON data successfully processed. Last input state: \\(inputSourceDescription)."
            var errorLogs = localDebugLogs; errorLogs.append(finalErrorMsg)
            let errResponse = ErrorResponse(command_id: "no_json_data", error: finalErrorMsg, debug_logs: debug ? errorLogs : nil)
            if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
            return
        }
        
        do {
            let commandEnvelope = try JSONDecoder().decode(CommandEnvelope.self, from: Data(jsonToProcess.utf8))
            var currentLogs = localDebugLogs 
            currentLogs.append("Decoded CommandEnvelope. Type: \(commandEnvelope.command), ID: \(commandEnvelope.command_id)")

            switch commandEnvelope.command {
            case .ping:
                let prefix = "Ping handled by AXORCCommand. Input source: "
                let messageValue = inputSourceDescription
                let successMessage = prefix + messageValue
                currentLogs.append(successMessage)
                let successResponse = SimpleSuccessResponse(
                    command_id: commandEnvelope.command_id,
                    status: "pong", 
                    message: successMessage, 
                    debug_logs: debug ? currentLogs : nil
                )
                if let data = try? encoder.encode(successResponse), let str = String(data: data, encoding: .utf8) { print(str) }
            
            case .getFocusedElement:
                let axInstance = AXorcist()
                var handlerLogs = currentLogs

                let semaphore = DispatchSemaphore(value: 0)
                var operationResult: HandlerResponse? 

                let commandIDForResponse = commandEnvelope.command_id
                let appIdentifierForHandler = commandEnvelope.application 
                let requestedAttributesForHandler = commandEnvelope.attributes 

                Task { [debug] in // Explicitly capture debug from self by value
                    operationResult = await axInstance.handleGetFocusedElement(
                        for: appIdentifierForHandler,
                        requestedAttributes: requestedAttributesForHandler,
                        isDebugLoggingEnabled: commandEnvelope.debug_logging ?? debug, // Now uses the captured debug
                        currentDebugLogs: &handlerLogs 
                    )
                    semaphore.signal()
                }
                
                semaphore.wait()

                if let actualResponse = operationResult {
                    let finalDebugLogs = debug || (commandEnvelope.debug_logging ?? false) ? handlerLogs : nil 
                    let queryResponse = QueryResponse(
                        command_id: commandIDForResponse, 
                        attributes: actualResponse.data?.attributes, 
                        error: actualResponse.error,
                        debug_logs: finalDebugLogs
                    )
                    if let data = try? encoder.encode(queryResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                } else {
                    let errorMsg = "Operation for .getFocusedElement returned no result."
                    handlerLogs.append(errorMsg) 
                    let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorMsg, debug_logs: debug || (commandEnvelope.debug_logging ?? false) ? handlerLogs : nil)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                }
            
            default:
                let errorMsg = "Unhandled command type: \\(commandEnvelope.command)"
                currentLogs.append(errorMsg)
                let errResponse = ErrorResponse(command_id: commandEnvelope.command_id, error: errorMsg, debug_logs: debug ? currentLogs : nil)
                if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
            }
        } catch {
            var errorLogs = localDebugLogs; errorLogs.append("JSON decoding error: \\(error.localizedDescription)")
            let errResponse = ErrorResponse(command_id: "decode_error", error: "Failed to decode JSON command: \\(error.localizedDescription)", debug_logs: debug ? errorLogs : nil)
            if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
        }
    }
}

/*
struct AXORC: ParsableCommand { ... old content ... }
*/

