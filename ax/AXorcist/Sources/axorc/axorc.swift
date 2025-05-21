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
            let finalErrorMsg = detailedInputError ?? "No JSON data successfully processed. Last input state: \\(inputSourceDescription)."
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
            
            default:
                let errorMsg = "Unhandled command type: \\(commandEnvelope.command)"
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

enum CommandType: String, Codable {
    case ping
    case getFocusedElement
    // Add other command types as they are implemented and handled in AXORCCommand
    case collectAll, query, describeElement, getAttributes, performAction, extractText, batch
}

struct CommandEnvelope: Codable {
    let command_id: String
    let command: CommandType
    let application: String?
    let attributes: [String]?
    // If payload is flexible, use [String: AnyCodable]? where AnyCodable is a helper struct/enum
    // For simplicity here if only ping uses it with a known structure:
    let payload: [String: String]? // Example: {"message": "hello"} for ping
    let debug_logging: Bool?
}

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
    let success: Bool = false // Default to false for errors
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
        if let originalAttributes = axElement.attributes { // originalAttributes is [String: AXorcist.AnyCodable]?
            var processedAttributes: [String: AnyCodable] = [:] // Will store [String: AXorcist.AnyCodable]
            for (key, outerAnyCodable) in originalAttributes { // outerAnyCodable is AXorcist.AnyCodable
                // Check if the value within AnyCodable is an AttributeData struct from the AXorcist module.
                // AttributeData itself is public and Codable, and defined in AXorcist module.
                if let attributeData = outerAnyCodable.value as? AttributeData {
                    // If it is AttributeData, its .value property is the actual AnyCodable we want.
                    processedAttributes[key] = attributeData.value 
                } else {
                    // Otherwise, the outerAnyCodable itself holds the primitive value directly.
                    processedAttributes[key] = outerAnyCodable
                }
            }
            self.attributes = processedAttributes
        } else {
            self.attributes = nil
        }
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

