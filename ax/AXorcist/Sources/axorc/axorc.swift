import Foundation
import AXorcist
import ArgumentParser

let AXORC_VERSION = "0.1.2a-config_fix"

@main // Add @main if this is the executable's entry point
struct AXORCCommand: AsyncParsableCommand { // Changed to AsyncParsableCommand
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

    mutating func run() async throws {
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

        print("AXORC_JSON_OUTPUT_PREFIX:::")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        if let errorToReport = detailedInputError, receivedJsonString == nil {
            let errResponse = ErrorResponse(command_id: "input_error", error: ErrorResponse.ErrorDetail(message: errorToReport), debug_logs: debug ? localDebugLogs : nil)
            if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
            return
        }

        guard let jsonToProcess = receivedJsonString, !jsonToProcess.isEmpty else {
            let finalErrorMsg = detailedInputError ?? "No JSON data successfully processed. Last input state: \(inputSourceDescription)."
            var errorLogs = localDebugLogs; errorLogs.append(finalErrorMsg)
            let errResponse = ErrorResponse(command_id: "no_json_data", error: ErrorResponse.ErrorDetail(message: finalErrorMsg), debug_logs: debug ? errorLogs : nil)
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
                
                let details: String?
                if let payloadData = jsonToProcess.data(using: .utf8),
                   let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
                   let payloadDict = payload["payload"] as? [String: Any],
                   let payloadMessage = payloadDict["message"] as? String {
                    details = payloadMessage
                } else {
                    details = nil
                }
                
                let successResponse = SimpleSuccessResponse(
                    command_id: commandEnvelope.command_id,
                    success: true, // Explicitly true
                    status: "pong", 
                    message: successMessage,
                    details: details,
                    debug_logs: debug ? currentLogs : nil
                )
                if let data = try? encoder.encode(successResponse), let str = String(data: data, encoding: .utf8) { print(str) }
            
            case .getFocusedElement:
                let axInstance = AXorcist()
                var handlerLogs = currentLogs

                let commandIDForResponse = commandEnvelope.command_id
                let appIdentifierForHandler = commandEnvelope.application 
                let requestedAttributesForHandler = commandEnvelope.attributes 

                // Directly await the MainActor function. operationResult is non-optional.
                let operationResult: HandlerResponse = await axInstance.handleGetFocusedElement(
                    for: appIdentifierForHandler,
                    requestedAttributes: requestedAttributesForHandler,
                    isDebugLoggingEnabled: commandEnvelope.debug_logging ?? debug, 
                    currentDebugLogs: &handlerLogs 
                )
                // No semaphore needed

                // operationResult is now non-optional, so we can use it directly.
                let actualResponse = operationResult 
                let finalDebugLogs = debug || (commandEnvelope.debug_logging ?? false) ? handlerLogs : nil
                
                fputs("[axorc DEBUG] Attempting to encode QueryResponse...\n", stderr)
                let queryResponse = QueryResponse(
                    command_id: commandIDForResponse,
                    success: actualResponse.error == nil,
                    command: commandEnvelope.command.rawValue, 
                    handlerResponse: actualResponse,          
                    debug_logs: finalDebugLogs
                )

                do {
                    let data = try encoder.encode(queryResponse)
                    fputs("[axorc DEBUG] QueryResponse encoded to data. Size: \(data.count)\n", stderr)
                    if let str = String(data: data, encoding: .utf8) {
                        fputs("[axorc DEBUG] QueryResponse data converted to string. Length: \(str.count). Printing to stdout.\n", stderr)
                        print(str) // STDOUT
                    } else {
                        fputs("[axorc DEBUG] Failed to convert QueryResponse data to UTF8 string.\n", stderr)
                        let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Failed to convert QueryResponse data to string (UTF8)")
                        let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                        if let errData = try? encoder.encode(errResponse), let errStr = String(data: errData, encoding: .utf8) { print(errStr) }
                    }
                } catch {
                    fputs("[axorc DEBUG] Explicitly CAUGHT error during QueryResponse encoding: \(error)\n", stderr)
                    fputs("[axorc DEBUG] Error localizedDescription: \(error.localizedDescription)\n", stderr)
                    if let encodingError = error as? EncodingError {
                        fputs("[axorc DEBUG] EncodingError context: \(encodingError)\n", stderr)
                    }

                    let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Caught error during QueryResponse encoding: \(error.localizedDescription)")
                    let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                }
            
            case .getAttributes:
                guard let locatorForHandler = commandEnvelope.locator else {
                    let errorMsg = "getAttributes command requires a locator but none was provided"
                    currentLogs.append(errorMsg)
                    let errResponse = ErrorResponse(command_id: commandEnvelope.command_id, error: ErrorResponse.ErrorDetail(message: errorMsg), debug_logs: debug ? currentLogs : nil)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                    return
                }
                
                let axInstance = AXorcist()
                var handlerLogs = currentLogs
                
                let commandIDForResponse = commandEnvelope.command_id
                let appIdentifierForHandler = commandEnvelope.application
                let requestedAttributesForHandler = commandEnvelope.attributes
                let pathHintForHandler = commandEnvelope.path_hint
                let maxDepthForHandler = commandEnvelope.max_elements
                let outputFormatForHandler = commandEnvelope.output_format
                
                // Call the new handleGetAttributes method
                let operationResult: HandlerResponse = await axInstance.handleGetAttributes(
                    for: appIdentifierForHandler,
                    locator: locatorForHandler,
                    requestedAttributes: requestedAttributesForHandler,
                    pathHint: pathHintForHandler,
                    maxDepth: maxDepthForHandler,
                    outputFormat: outputFormatForHandler,
                    isDebugLoggingEnabled: commandEnvelope.debug_logging ?? debug,
                    currentDebugLogs: &handlerLogs
                )
                
                let actualResponse = operationResult
                let finalDebugLogs = debug || (commandEnvelope.debug_logging ?? false) ? handlerLogs : nil
                
                fputs("[axorc DEBUG] Attempting to encode QueryResponse for getAttributes...\n", stderr)
                let queryResponse = QueryResponse(
                    command_id: commandIDForResponse,
                    success: actualResponse.error == nil,
                    command: commandEnvelope.command.rawValue,
                    handlerResponse: actualResponse,
                    debug_logs: finalDebugLogs
                )
                
                do {
                    let data = try encoder.encode(queryResponse)
                    fputs("[axorc DEBUG] QueryResponse encoded to data. Size: \(data.count)\n", stderr)
                    if let str = String(data: data, encoding: .utf8) {
                        fputs("[axorc DEBUG] QueryResponse data converted to string. Length: \(str.count). Printing to stdout.\n", stderr)
                        print(str) // STDOUT
                    } else {
                        fputs("[axorc DEBUG] Failed to convert QueryResponse data to UTF8 string.\n", stderr)
                        let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Failed to convert QueryResponse data to string (UTF8)")
                        let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                        if let errData = try? encoder.encode(errResponse), let errStr = String(data: errData, encoding: .utf8) { print(errStr) }
                    }
                } catch {
                    fputs("[axorc DEBUG] Explicitly CAUGHT error during QueryResponse encoding for getAttributes: \(error)\n", stderr)
                    fputs("[axorc DEBUG] Error localizedDescription: \(error.localizedDescription)\n", stderr)
                    if let encodingError = error as? EncodingError {
                        fputs("[axorc DEBUG] EncodingError context: \(encodingError)\n", stderr)
                    }

                    let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Caught error during QueryResponse encoding: \(error.localizedDescription)")
                    let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                }
            
            case .query:
                guard let locatorForHandler = commandEnvelope.locator else {
                    let errorMsg = "query command requires a locator but none was provided"
                    currentLogs.append(errorMsg)
                    let errResponse = ErrorResponse(command_id: commandEnvelope.command_id, error: ErrorResponse.ErrorDetail(message: errorMsg), debug_logs: debug ? currentLogs : nil)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                    return
                }
                
                let axInstance = AXorcist()
                var handlerLogs = currentLogs
                
                let commandIDForResponse = commandEnvelope.command_id
                let appIdentifierForHandler = commandEnvelope.application
                let requestedAttributesForHandler = commandEnvelope.attributes
                let pathHintForHandler = commandEnvelope.path_hint
                let maxDepthForHandler = commandEnvelope.max_elements
                let outputFormatForHandler = commandEnvelope.output_format
                
                // Call the new handleQuery method
                let operationResult: HandlerResponse = await axInstance.handleQuery(
                    for: appIdentifierForHandler,
                    locator: locatorForHandler,
                    pathHint: pathHintForHandler,
                    maxDepth: maxDepthForHandler,
                    requestedAttributes: requestedAttributesForHandler,
                    outputFormat: outputFormatForHandler,
                    isDebugLoggingEnabled: commandEnvelope.debug_logging ?? debug,
                    currentDebugLogs: &handlerLogs
                )
                
                let actualResponse = operationResult
                let finalDebugLogs = debug || (commandEnvelope.debug_logging ?? false) ? handlerLogs : nil
                
                fputs("[axorc DEBUG] Attempting to encode QueryResponse for query...\n", stderr)
                let queryResponse = QueryResponse(
                    command_id: commandIDForResponse,
                    success: actualResponse.error == nil,
                    command: commandEnvelope.command.rawValue,
                    handlerResponse: actualResponse,
                    debug_logs: finalDebugLogs
                )
                
                do {
                    let data = try encoder.encode(queryResponse)
                    fputs("[axorc DEBUG] QueryResponse encoded to data. Size: \(data.count)\n", stderr)
                    if let str = String(data: data, encoding: .utf8) {
                        fputs("[axorc DEBUG] QueryResponse data converted to string. Length: \(str.count). Printing to stdout.\n", stderr)
                        print(str) // STDOUT
                    } else {
                        fputs("[axorc DEBUG] Failed to convert QueryResponse data to UTF8 string.\n", stderr)
                        let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Failed to convert QueryResponse data to string (UTF8)")
                        let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                        if let errData = try? encoder.encode(errResponse), let errStr = String(data: errData, encoding: .utf8) { print(errStr) }
                    }
                } catch {
                    fputs("[axorc DEBUG] Explicitly CAUGHT error during QueryResponse encoding for query: \(error)\n", stderr)
                    fputs("[axorc DEBUG] Error localizedDescription: \(error.localizedDescription)\n", stderr)
                    if let encodingError = error as? EncodingError {
                        fputs("[axorc DEBUG] EncodingError context: \(encodingError)\n", stderr)
                    }

                    let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Caught error during QueryResponse encoding: \(error.localizedDescription)")
                    let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                }
            
            case .describeElement:
                guard let locatorForHandler = commandEnvelope.locator else {
                    let errorMsg = "describeElement command requires a locator but none was provided"
                    currentLogs.append(errorMsg)
                    let errResponse = ErrorResponse(command_id: commandEnvelope.command_id, error: ErrorResponse.ErrorDetail(message: errorMsg), debug_logs: debug ? currentLogs : nil)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                    return
                }
                
                let axInstance = AXorcist()
                var handlerLogs = currentLogs
                
                let commandIDForResponse = commandEnvelope.command_id
                let appIdentifierForHandler = commandEnvelope.application
                let pathHintForHandler = commandEnvelope.path_hint
                let maxDepthForHandler = commandEnvelope.max_elements
                let outputFormatForHandler = commandEnvelope.output_format
                
                // Call the new handleDescribeElement method
                let operationResult: HandlerResponse = await axInstance.handleDescribeElement(
                    for: appIdentifierForHandler,
                    locator: locatorForHandler,
                    pathHint: pathHintForHandler,
                    maxDepth: maxDepthForHandler,
                    outputFormat: outputFormatForHandler,
                    isDebugLoggingEnabled: commandEnvelope.debug_logging ?? debug,
                    currentDebugLogs: &handlerLogs
                )
                
                let actualResponse = operationResult
                let finalDebugLogs = debug || (commandEnvelope.debug_logging ?? false) ? handlerLogs : nil
                
                fputs("[axorc DEBUG] Attempting to encode QueryResponse for describeElement...\n", stderr)
                let queryResponse = QueryResponse(
                    command_id: commandIDForResponse,
                    success: actualResponse.error == nil,
                    command: commandEnvelope.command.rawValue,
                    handlerResponse: actualResponse,
                    debug_logs: finalDebugLogs
                )
                
                do {
                    let data = try encoder.encode(queryResponse)
                    fputs("[axorc DEBUG] QueryResponse encoded to data. Size: \(data.count)\n", stderr)
                    if let str = String(data: data, encoding: .utf8) {
                        fputs("[axorc DEBUG] QueryResponse data converted to string. Length: \(str.count). Printing to stdout.\n", stderr)
                        print(str) // STDOUT
                    } else {
                        fputs("[axorc DEBUG] Failed to convert QueryResponse data to UTF8 string.\n", stderr)
                        let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Failed to convert QueryResponse data to string (UTF8)")
                        let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                        if let errData = try? encoder.encode(errResponse), let errStr = String(data: errData, encoding: .utf8) { print(errStr) }
                    }
                } catch {
                    fputs("[axorc DEBUG] Explicitly CAUGHT error during QueryResponse encoding for describeElement: \(error)\n", stderr)
                    fputs("[axorc DEBUG] Error localizedDescription: \(error.localizedDescription)\n", stderr)
                    if let encodingError = error as? EncodingError {
                        fputs("[axorc DEBUG] EncodingError context: \(encodingError)\n", stderr)
                    }

                    let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Caught error during QueryResponse encoding: \(error.localizedDescription)")
                    let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                }
            
            case .performAction:
                guard let locatorForHandler = commandEnvelope.locator else {
                    let errorMsg = "performAction command requires a locator but none was provided"
                    currentLogs.append(errorMsg)
                    let errResponse = ErrorResponse(command_id: commandEnvelope.command_id, error: ErrorResponse.ErrorDetail(message: errorMsg), debug_logs: debug ? currentLogs : nil)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                    return
                }
                guard let actionNameForHandler = commandEnvelope.action_name else {
                    let errorMsg = "performAction command requires an action_name but none was provided"
                    currentLogs.append(errorMsg)
                    let errResponse = ErrorResponse(command_id: commandEnvelope.command_id, error: ErrorResponse.ErrorDetail(message: errorMsg), debug_logs: debug ? currentLogs : nil)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                    return
                }
                
                let axInstance = AXorcist()
                var handlerLogs = currentLogs
                
                let commandIDForResponse = commandEnvelope.command_id
                let appIdentifierForHandler = commandEnvelope.application
                let pathHintForHandler = commandEnvelope.path_hint
                let actionValueForHandler = commandEnvelope.action_value // This is AnyCodable?

                // Call the new handlePerformAction method
                let operationResult: HandlerResponse = await axInstance.handlePerformAction(
                    for: appIdentifierForHandler,
                    locator: locatorForHandler,
                    pathHint: pathHintForHandler,
                    actionName: actionNameForHandler,
                    actionValue: actionValueForHandler,
                    isDebugLoggingEnabled: commandEnvelope.debug_logging ?? debug,
                    currentDebugLogs: &handlerLogs
                )
                
                let actualResponse = operationResult
                let finalDebugLogs = debug || (commandEnvelope.debug_logging ?? false) ? handlerLogs : nil
                
                fputs("[axorc DEBUG] Attempting to encode QueryResponse for performAction...\n", stderr)
                let queryResponse = QueryResponse(
                    command_id: commandIDForResponse,
                    success: actualResponse.error == nil,
                    command: commandEnvelope.command.rawValue,
                    handlerResponse: actualResponse,
                    debug_logs: finalDebugLogs
                )
                
                do {
                    let data = try encoder.encode(queryResponse)
                    fputs("[axorc DEBUG] QueryResponse encoded to data. Size: \(data.count)\n", stderr)
                    if let str = String(data: data, encoding: .utf8) {
                        fputs("[axorc DEBUG] QueryResponse data converted to string. Length: \(str.count). Printing to stdout.\n", stderr)
                        print(str) // STDOUT
                    } else {
                        fputs("[axorc DEBUG] Failed to convert QueryResponse data to UTF8 string.\n", stderr)
                        let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Failed to convert QueryResponse data to string (UTF8)")
                        let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                        if let errData = try? encoder.encode(errResponse), let errStr = String(data: errData, encoding: .utf8) { print(errStr) }
                    }
                } catch {
                    fputs("[axorc DEBUG] Explicitly CAUGHT error during QueryResponse encoding for performAction: \(error)\n", stderr)
                    fputs("[axorc DEBUG] Error localizedDescription: \(error.localizedDescription)\n", stderr)
                    if let encodingError = error as? EncodingError {
                        fputs("[axorc DEBUG] EncodingError context: \(encodingError)\n", stderr)
                    }

                    let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Caught error during QueryResponse encoding: \(error.localizedDescription)")
                    let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                }
            
            case .extractText:
                guard let locatorForHandler = commandEnvelope.locator else {
                    let errorMsg = "extractText command requires a locator but none was provided"
                    currentLogs.append(errorMsg)
                    let errResponse = ErrorResponse(command_id: commandEnvelope.command_id, error: ErrorResponse.ErrorDetail(message: errorMsg), debug_logs: debug ? currentLogs : nil)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                    return
                }

                let axInstance = AXorcist()
                var handlerLogs = currentLogs

                let commandIDForResponse = commandEnvelope.command_id
                let appIdentifierForHandler = commandEnvelope.application
                let pathHintForHandler = commandEnvelope.path_hint

                let operationResult: HandlerResponse = await axInstance.handleExtractText(
                    for: appIdentifierForHandler,
                    locator: locatorForHandler,
                    pathHint: pathHintForHandler,
                    isDebugLoggingEnabled: commandEnvelope.debug_logging ?? debug,
                    currentDebugLogs: &handlerLogs
                )

                let actualResponse = operationResult
                let finalDebugLogs = debug || (commandEnvelope.debug_logging ?? false) ? handlerLogs : nil

                fputs("[axorc DEBUG] Attempting to encode QueryResponse for extractText...\n", stderr)
                let queryResponse = QueryResponse(
                    command_id: commandIDForResponse,
                    success: actualResponse.error == nil,
                    command: commandEnvelope.command.rawValue,
                    handlerResponse: actualResponse,
                    debug_logs: finalDebugLogs
                )

                do {
                    let data = try encoder.encode(queryResponse)
                    fputs("[axorc DEBUG] QueryResponse encoded to data. Size: \(data.count)\n", stderr)
                    if let str = String(data: data, encoding: .utf8) {
                        fputs("[axorc DEBUG] QueryResponse data converted to string. Length: \(str.count). Printing to stdout.\n", stderr)
                        print(str) // STDOUT
                    } else {
                        fputs("[axorc DEBUG] Failed to convert QueryResponse data to UTF8 string.\n", stderr)
                        let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Failed to convert QueryResponse data to string (UTF8)")
                        let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                        if let errData = try? encoder.encode(errResponse), let errStr = String(data: errData, encoding: .utf8) { print(errStr) }
                    }
                } catch {
                    fputs("[axorc DEBUG] Explicitly CAUGHT error during QueryResponse encoding for extractText: \(error)\n", stderr)
                    fputs("[axorc DEBUG] Error localizedDescription: \(error.localizedDescription)\n", stderr)
                    if let encodingError = error as? EncodingError {
                        fputs("[axorc DEBUG] EncodingError context: \(encodingError)\n", stderr)
                    }

                    let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Caught error during QueryResponse encoding: \(error.localizedDescription)")
                    let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                }
            
            case .batch:
                // The main commandEnvelope is for the batch itself.
                // Sub-commands are now directly in commandEnvelope.sub_commands.
                guard let subCommands = commandEnvelope.sub_commands, !subCommands.isEmpty else {
                    let errorMsg = "Batch command received, but 'sub_commands' array is missing or empty."
                    currentLogs.append(errorMsg)
                    let errResponse = ErrorResponse(command_id: commandEnvelope.command_id, error: ErrorResponse.ErrorDetail(message: errorMsg), debug_logs: debug ? currentLogs : nil)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                    return
                }
                
                currentLogs.append("Processing batch command. Batch ID: \(commandEnvelope.command_id), Number of sub-commands: \(subCommands.count)")

                let axInstance = AXorcist()
                var handlerLogs = currentLogs // batch handler will append to this

                // Call the handleBatchCommands method
                let batchHandlerResponses: [HandlerResponse] = await axInstance.handleBatchCommands(
                    batchCommandID: commandEnvelope.command_id, // Use the main command's ID for the batch
                    subCommands: subCommands,                 // Pass the array of CommandEnvelopes
                    isDebugLoggingEnabled: commandEnvelope.debug_logging ?? debug, // Use overall debug flag
                    currentDebugLogs: &handlerLogs
                )
                
                // Convert each HandlerResponse into a QueryResponse
                var batchQueryResponses: [QueryResponse] = []
                var overallSuccess = true
                for (index, subHandlerResponse) in batchHandlerResponses.enumerated() {
                    // The subCommandEnvelope for ID and type.
                    // Make sure subCommands array is not empty and index is valid.
                    guard index < subCommands.count else {
                        // This should not happen if batchHandlerResponses lines up with subCommands
                        let errorMsg = "Mismatch between subCommands and batchHandlerResponses count."
                        currentLogs.append(errorMsg)
                        // Consider how to report this internal error
                        continue 
                    }
                    let subCommandEnvelope = subCommands[index]
                    
                    let subQueryResponse = QueryResponse(
                        command_id: subCommandEnvelope.command_id, // Use sub-command's ID
                        success: subHandlerResponse.error == nil,
                        command: subCommandEnvelope.command.rawValue, // Use sub-command's type
                        handlerResponse: subHandlerResponse,
                        debug_logs: nil // Individual sub-command logs are part of HandlerResponse.
                                        // QueryResponse's init handles this for its 'error' or 'data'.
                                        // The overall batch debug log will be separate.
                    )
                    batchQueryResponses.append(subQueryResponse)
                    if subHandlerResponse.error != nil {
                        overallSuccess = false
                    }
                }
                
                let finalDebugLogsForBatch = debug || (commandEnvelope.debug_logging ?? false) ? handlerLogs : nil
                
                let batchOperationResponse = BatchOperationResponse(
                    command_id: commandEnvelope.command_id, // ID of the overall batch from the main envelope
                    success: overallSuccess,
                    results: batchQueryResponses,
                    debug_logs: finalDebugLogsForBatch
                )

                do {
                    let data = try encoder.encode(batchOperationResponse)
                    if let str = String(data: data, encoding: .utf8) {
                        print(str)
                    } else {
                        let errorMsg = "Failed to convert BatchOperationResponse to UTF8 string."
                        currentLogs.append(errorMsg) // Log to main logs
                        fputs("[axorc DEBUG] \(errorMsg)\n", stderr)
                        // Fallback to a simple error if top-level encoding fails
                        let errResponse = ErrorResponse(command_id: commandEnvelope.command_id, error: ErrorResponse.ErrorDetail(message: errorMsg), debug_logs: finalDebugLogsForBatch)
                        if let errData = try? encoder.encode(errResponse), let errStr = String(data: errData, encoding: .utf8) { print(errStr) }
                    }
                } catch {
                    let errorMsg = "Failed to encode BatchOperationResponse: \(error.localizedDescription)"
                    currentLogs.append(errorMsg) // Log to main logs
                    fputs("[axorc DEBUG] \(errorMsg) - Error: \(error)\n", stderr)
                    // Fallback to a simple error
                    let errResponse = ErrorResponse(command_id: commandEnvelope.command_id, error: ErrorResponse.ErrorDetail(message: errorMsg), debug_logs: finalDebugLogsForBatch)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                }
            
            case .collectAll:
                let axInstance = AXorcist()
                let handlerLogs = currentLogs // Changed var to let

                let commandIDForResponse = commandEnvelope.command_id
                let appIdentifierForHandler = commandEnvelope.application
                let locatorForHandler = commandEnvelope.locator // Optional for collectAll
                let pathHintForHandler = commandEnvelope.path_hint
                let maxDepthForHandler = commandEnvelope.max_elements
                let requestedAttributesForHandler = commandEnvelope.attributes
                let outputFormatForHandler = commandEnvelope.output_format

                // Call handleCollectAll, passing handlerLogs as non-inout
                let operationResult: HandlerResponse = await axInstance.handleCollectAll(
                    for: appIdentifierForHandler,
                    locator: locatorForHandler,
                    pathHint: pathHintForHandler,
                    maxDepth: maxDepthForHandler,
                    requestedAttributes: requestedAttributesForHandler,
                    outputFormat: outputFormatForHandler,
                    isDebugLoggingEnabled: commandEnvelope.debug_logging ?? debug,
                    currentDebugLogs: handlerLogs // Pass as [String]
                )

                // operationResult.debug_logs now contains all logs from the handler
                // including the initial handlerLogs plus anything new from handleCollectAll.
                let finalDebugLogs = (debug || (commandEnvelope.debug_logging ?? false)) ? operationResult.debug_logs : nil

                fputs("[axorc DEBUG] Attempting to encode QueryResponse for collectAll...\n", stderr)
                let queryResponse = QueryResponse(
                    command_id: commandIDForResponse,
                    success: operationResult.error == nil,
                    command: commandEnvelope.command.rawValue,
                    handlerResponse: operationResult,
                    debug_logs: finalDebugLogs
                )

                do {
                    let data = try encoder.encode(queryResponse)
                    fputs("[axorc DEBUG] QueryResponse encoded to data. Size: \(data.count)\n", stderr)
                    if let str = String(data: data, encoding: .utf8) {
                        fputs("[axorc DEBUG] QueryResponse data converted to string. Length: \(str.count). Printing to stdout.\n", stderr)
                        print(str) // STDOUT
                    } else {
                        fputs("[axorc DEBUG] Failed to convert QueryResponse data to UTF8 string.\n", stderr)
                        let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Failed to convert QueryResponse data to string (UTF8)")
                        let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                        if let errData = try? encoder.encode(errResponse), let errStr = String(data: errData, encoding: .utf8) { print(errStr) }
                    }
                } catch {
                    fputs("[axorc DEBUG] Explicitly CAUGHT error during QueryResponse encoding for collectAll: \(error)\n", stderr)
                    fputs("[axorc DEBUG] Error localizedDescription: \(error.localizedDescription)\n", stderr)
                    if let encodingError = error as? EncodingError {
                        fputs("[axorc DEBUG] EncodingError context: \(encodingError)\n", stderr)
                    }

                    let errorDetailForResponse = ErrorResponse.ErrorDetail(message: "Caught error during QueryResponse encoding: \(error.localizedDescription)")
                    let errResponse = ErrorResponse(command_id: commandIDForResponse, error: errorDetailForResponse, debug_logs: finalDebugLogs)
                    if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
                }
            
            default:
                let errorMsg = "Unhandled command type: \(commandEnvelope.command)"
                currentLogs.append(errorMsg)
                let errResponse = ErrorResponse(command_id: commandEnvelope.command_id, error: ErrorResponse.ErrorDetail(message: errorMsg), debug_logs: debug ? currentLogs : nil)
                if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
            }
        } catch {
            var errorLogs = localDebugLogs
            let basicErrorMessage = "JSON decoding error: \(error.localizedDescription)"
            errorLogs.append(basicErrorMessage)
            
            let detailedErrorMessage: String
            if let decodingError = error as? DecodingError {
                 errorLogs.append("Decoding error details: \(decodingError.humanReadableDescription)")
                 detailedErrorMessage = "Failed to decode JSON command (DecodingError): \(decodingError.humanReadableDescription)"
            } else {
                 detailedErrorMessage = "Failed to decode JSON command: \(error.localizedDescription)"
            }

            let errResponse = ErrorResponse(command_id: "decode_error", error: ErrorResponse.ErrorDetail(message: detailedErrorMessage), debug_logs: debug ? errorLogs : nil)
            if let data = try? encoder.encode(errResponse), let str = String(data: data, encoding: .utf8) { print(str) }
        }
    }
}

// MARK: - Codable Structs for axorc responses and CommandEnvelope
// These should align with structs in AXorcistIntegrationTests.swift

struct SimpleSuccessResponse: Codable {
    let command_id: String
    let success: Bool
    let status: String? // e.g., "pong"
    let message: String
    let details: String?
    let debug_logs: [String]?
}

struct ErrorResponse: Codable {
    let command_id: String
    var success: Bool = false // Default to false for errors
    struct ErrorDetail: Codable {
        let message: String
    }
    let error: ErrorDetail
    let debug_logs: [String]?
}

// AXElement as received from AXorcist library and to be encoded in QueryResponse
// This is a pass-through structure. AXorcist.AXElement should be Codable itself.
// If AXorcist.AXElement is not Codable, then this needs to be manually constructed.
// For now, assume AXorcist.AXElement is Codable or can be easily made so.
// The properties (attributes, path) must match what AXorcist.AXElement provides.
struct AXElementForEncoding: Codable {
    let attributes: [String: AnyCodable]? // This will now use AXorcist.AnyCodable
    let path: [String]?

    init(from axElement: AXElement) { // axElement is AXorcist.AXElement
        self.attributes = axElement.attributes // Directly assign
        self.path = axElement.path
    }
}

struct QueryResponse: Codable {
    let command_id: String
    let success: Bool
    let command: String // Name of the command, e.g., "getFocusedElement"
    let data: AXElementForEncoding? // Contains the AX element's data, adapted for encoding
    let error: ErrorResponse.ErrorDetail?
    let debug_logs: [String]?
    
    // Custom initializer to bridge from HandlerResponse (from AXorcist module)
    init(command_id: String, success: Bool, command: String, handlerResponse: HandlerResponse, debug_logs: [String]?) {
        self.command_id = command_id
        self.success = success
        self.command = command
        if let axElement = handlerResponse.data {
            self.data = AXElementForEncoding(from: axElement) // Convert here
        } else {
            self.data = nil
        }
        if let errorMsg = handlerResponse.error {
            self.error = ErrorResponse.ErrorDetail(message: errorMsg)
        } else {
            self.error = nil
        }
        self.debug_logs = debug_logs
    }
}

struct BatchOperationResponse: Codable {
    let command_id: String
    let success: Bool
    let results: [QueryResponse]
    let debug_logs: [String]?
}

// Helper for DecodingError display
extension DecodingError {
    var humanReadableDescription: String {
        switch self {
        case .typeMismatch(let type, let context): return "Type mismatch for \(type): \(context.debugDescription) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .valueNotFound(let type, let context): return "Value not found for \(type): \(context.debugDescription) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .keyNotFound(let key, let context): return "Key not found: \(key.stringValue) at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)"
        case .dataCorrupted(let context): return "Data corrupted: \(context.debugDescription) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        @unknown default: return self.localizedDescription
        }
    }
}

/*
struct AXORC: ParsableCommand { ... old content ... }
*/

