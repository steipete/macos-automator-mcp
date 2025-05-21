import Foundation
import AXorcist
import ArgumentParser

// Updated BIARY_VERSION to a more descriptive name
let AXORC_BINARY_VERSION = "0.9.0" // Example version

// --- Global Options Definition ---
struct GlobalOptions: ParsableArguments {
    @Flag(name: .long, help: "Enable detailed debug logging for AXORC operations.")
    var debugAxCli: Bool = false
}

// --- Grouped options for Locator ---
struct LocatorOptions: ParsableArguments {
    @Option(name: .long, help: "Element criteria as key-value pairs (e.g., 'Key1=Value1;Key2=Value2'). Pairs separated by ';', key/value by '='.")
    var criteria: String?

    @Option(name: .long, parsing: .upToNextOption, help: "Path hint for locator's root element (e.g., --root-path-hint 'rolename[index]').")
    var rootPathHint: [String] = []
    
    @Option(name: .long, help: "Filter elements to only those supporting this action (e.g., AXPress).")
    var requireAction: String?

    @Flag(name: .long, help: "If true, all criteria in --criteria must match. Default: any match.")
    var matchAll: Bool = false

    // Updated based on user feedback: --computed-name (implies contains), removed --computed-name-equals from CLI
    @Option(name: .long, help: "Match elements where the computed name contains this string.")
    var computedName: String? 
    // var computedNameEquals: String? // Removed as per user feedback for a simpler --computed-name

}

@main
struct AXORC: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "AXORC - macOS Accessibility Inspector & Executor.",
        version: AXORC_BINARY_VERSION,
        subcommands: [JsonCommand.self, QueryCommand.self], // Restored JsonCommand
        defaultSubcommand: JsonCommand.self // Restored default
    )

    @OptionGroup var globalOptions: GlobalOptions

    mutating func run() throws {
        fputs("--- AXORC.run() ENTERED ---\n", stderr)
        fflush(stderr)
        if globalOptions.debugAxCli {
             fputs("--- AXORC.run() globalOptions.debugAxCli is TRUE ---\n", stderr)
             fflush(stderr)
        } else {
             fputs("--- AXORC.run() globalOptions.debugAxCli is FALSE ---\n", stderr)
             fflush(stderr)
        }
        // If no subcommand is specified, and a default is set, ArgumentParser runs the default.
        // If a subcommand is specified, its run() is called.
        // If no subcommand and no default, help is shown.
        fputs("--- AXORC.run() EXITING ---\n", stderr)
        fflush(stderr)
    }
}

struct JsonCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "json",
        abstract: "Process a command from a JSON payload (STDIN, file, or direct argument)."
    )

    @Argument(help: "Optional: Path to a JSON file or the JSON string itself. If omitted, reads from STDIN.")
    var input: String?

    @OptionGroup var globalOptions: GlobalOptions

    @MainActor
    mutating func run() async throws {
        fputs("--- JsonCommand.run() ENTERED ---\n", stderr)
        fflush(stderr)

        var isDebugLoggingEnabled = globalOptions.debugAxCli
        var currentDebugLogs: [String] = []

        if isDebugLoggingEnabled {
            currentDebugLogs.append("Debug logging enabled for JsonCommand via global --debug-ax-cli flag.")
        }
        
        let permissionStatus = AXorcist.getPermissionsStatus(checkAutomationFor: [], isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)

        if !permissionStatus.canUseAccessibility {
            let messages = permissionStatus.overallErrorMessages
            let errorDetail = messages.isEmpty ? "Permissions not sufficient." : messages.joined(separator: "; ")
            let errorResponse = AXorcist.ErrorResponse(
                command_id: "permission_check_failed",
                error: "Accessibility permission check failed: \(errorDetail)",
                debug_logs: permissionStatus.overallErrorMessages
            )
            sendResponse(errorResponse)
            throw ExitCode.failure
        }

        var commandInputJSON: String?
        
        if isDebugLoggingEnabled {
            var determinedInputSource: String = "Unknown"
            if let inputValue = input {
                if FileManager.default.fileExists(atPath: inputValue) {
                    determinedInputSource = "File (\(inputValue))"
                } else {
                    determinedInputSource = "Direct Argument"
                }
            } else if !isSTDINEmpty() { 
                 determinedInputSource = "STDIN"
            }
            currentDebugLogs.append("axorc v\(AXORC_BINARY_VERSION) processing 'json' command. Input via: \(determinedInputSource).")
        }

        if let inputValue = input {
            if FileManager.default.fileExists(atPath: inputValue) {
                do {
                    commandInputJSON = try String(contentsOfFile: inputValue, encoding: .utf8)
                } catch {
                    let errorResponse = AXorcist.ErrorResponse(command_id: "file_read_error", error: "Failed to read command from file '\(inputValue)': \(error.localizedDescription)")
                    sendResponse(errorResponse)
                    throw ExitCode.failure
                }
            } else {
                commandInputJSON = inputValue
            }
        } else {
            if !isSTDINEmpty() {
                var inputData = Data()
                while let line = readLine(strippingNewline: false) {
                    inputData.append(Data(line.utf8))
                }
                commandInputJSON = String(data: inputData, encoding: .utf8)
            } else {
                let errorResponse = AXorcist.ErrorResponse(command_id: "no_input", error: "No command input provided for 'json' command. Expecting JSON via STDIN, a file path, or as a direct argument.")
                sendResponse(errorResponse)
                throw ExitCode.failure
            }
        }

        if isDebugLoggingEnabled {
            if let json = commandInputJSON, json.count < 1024 {
                 currentDebugLogs.append("Received Command JSON: \(json)")
            } else if commandInputJSON != nil {
                 currentDebugLogs.append("Received Command JSON: (Too large to log)")
            }
        }

        guard let jsonDataToProcess = commandInputJSON?.data(using: .utf8) else {
            let errorResponse = AXorcist.ErrorResponse(command_id: "input_encoding_error", error: "Command input was nil or could not be UTF-8 encoded for 'json' command.")
            sendResponse(errorResponse)
            throw ExitCode.failure
        }
        
        await processCommandData(jsonDataToProcess, isDebugLoggingEnabled: &isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
    }
}

struct QueryCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "query", 
        abstract: "Query accessibility elements based on specified criteria."
    )

    @OptionGroup var globalOptions: GlobalOptions
    @OptionGroup var locatorOptions: LocatorOptions // Restored

    @Option(name: .shortAndLong, help: "Application: bundle ID (e.g., com.apple.TextEdit), name (e.g., \"TextEdit\"), or 'frontmost'.")
    var application: String?

    @Option(name: .long, parsing: .upToNextOption, help: "Path hint to navigate UI tree (e.g., --path-hint 'rolename[index]' 'rolename[index]').")
    var pathHint: [String] = []
    
    @Option(name: .long, parsing: .upToNextOption, help: "Array of attribute names to fetch for matching elements.")
    var attributesToFetch: [String] = []

    @Option(name: .long, help: "Maximum number of elements to return.")
    var maxElements: Int?

    @Option(name: .long, help: "Output format: 'smart', 'verbose', 'text', 'json'. Default: 'smart'.") 
    var outputFormat: String? // Will be mapped to AXorcist.OutputFormat

    @Option(name: [.long, .customShort("f")], help: "Path to a JSON file defining the entire query operation (CommandEnvelope). Overrides other CLI options for query.")
    var inputFile: String?

    @Flag(name: .long, help: "Read the JSON query definition (CommandEnvelope) from STDIN. Overrides other CLI options for query.")
    var stdin: Bool = false

    // Synchronous run method
    mutating func run() throws {
        let semaphore = DispatchSemaphore(value: 0)
        var taskOutcome: Result<Void, Error>?
        
        let commandState = self 

        Task {
            do {
                try await commandState.performQueryLogic()
                taskOutcome = .success(())
            } catch {
                taskOutcome = .failure(error)
            }
            semaphore.signal()
        }
        
        semaphore.wait() 

        switch taskOutcome {
        case .success:
            return 
        case .failure(let error):
            if error is ExitCode {
                throw error
            } else {
                fputs("QueryCommand.run: Unhandled error from performQueryLogic: \(error.localizedDescription)\n", stderr); fflush(stderr)
                throw ExitCode.failure
            }
        case nil:
            fputs("Error: Task outcome was nil after semaphore wait. This should not happen.\n", stderr)
            throw ExitCode.failure
        }
    }

    // Asynchronous and @MainActor logic method
    @MainActor
    private func performQueryLogic() async throws { // Non-mutating
        var isDebugLoggingEnabled = globalOptions.debugAxCli
        var currentDebugLogs: [String] = [] 

        if isDebugLoggingEnabled {
            currentDebugLogs.append("Debug logging enabled for QueryCommand via global --debug-ax-cli flag.")
        }

        let permissionStatus = AXorcist.getPermissionsStatus(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        if !permissionStatus.canUseAccessibility {
            let messages = permissionStatus.overallErrorMessages
            let errorDetail = messages.isEmpty ? "Permissions not sufficient for QueryCommand." : messages.joined(separator: "; ")
            let errorResponse = AXorcist.ErrorResponse(
                command_id: "query_permission_check_failed",
                error: "Accessibility permission check failed: \(errorDetail)",
                debug_logs: currentDebugLogs + permissionStatus.overallErrorMessages 
            )
            sendResponse(errorResponse)
            throw ExitCode.failure
        }

        if let filePath = inputFile {
            if isDebugLoggingEnabled { currentDebugLogs.append("Input source: File ('\(filePath)')") }
            do {
                let fileContents = try String(contentsOfFile: filePath, encoding: .utf8)
                guard let jsonData = fileContents.data(using: .utf8) else {
                    let errResp = AXorcist.ErrorResponse(command_id: "cli_query_file_encoding_error", error: "Failed to encode file contents to UTF-8 data from \(filePath).")
                    sendResponse(errResp); throw ExitCode.failure
                }
                await processCommandData(jsonData, isDebugLoggingEnabled: &isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
                return 
            } catch {
                let errResp = AXorcist.ErrorResponse(command_id: "cli_query_file_read_error", error: "Failed to read or process query from file '\(filePath)': \(error.localizedDescription)")
                sendResponse(errResp); throw ExitCode.failure
            }
        } else if stdin {
            if isDebugLoggingEnabled { currentDebugLogs.append("Input source: STDIN") }
            if isSTDINEmpty() {
                let errResp = AXorcist.ErrorResponse(command_id: "cli_query_stdin_empty", error: "--stdin flag was given, but STDIN is empty.")
                sendResponse(errResp); throw ExitCode.failure
            }
            var inputData = Data()
            while let line = readLine(strippingNewline: false) { 
                inputData.append(Data(line.utf8))
            }
            guard !inputData.isEmpty else {
                 let errResp = AXorcist.ErrorResponse(command_id: "cli_query_stdin_no_data", error: "--stdin flag was given, but no data could be read from STDIN.")
                sendResponse(errResp); throw ExitCode.failure
            }
            await processCommandData(inputData, isDebugLoggingEnabled: &isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            return 
        }

        if isDebugLoggingEnabled { currentDebugLogs.append("Input source: CLI arguments") }

        var parsedCriteria: [String: String] = [:]
        if let criteriaString = locatorOptions.criteria, !criteriaString.isEmpty {
            let pairs = criteriaString.split(separator: ";")
            for pair in pairs {
                let keyValue = pair.split(separator: "=", maxSplits: 1)
                if keyValue.count == 2 {
                    parsedCriteria[String(keyValue[0])] = String(keyValue[1])
                } else {
                    if isDebugLoggingEnabled { currentDebugLogs.append("Warning: Malformed criteria pair '\(pair)' will be ignored.") }
                }
            }
        }

        var axOutputFormat: AXorcist.OutputFormat = .smart 
        if let fmtStr = outputFormat?.lowercased() {
            switch fmtStr {
            case "smart": axOutputFormat = .smart
            case "verbose": axOutputFormat = .verbose
            case "text": axOutputFormat = .text_content
            case "json": axOutputFormat = .json_string
            default:
                if isDebugLoggingEnabled { currentDebugLogs.append("Warning: Unknown output format '\(fmtStr)'. Defaulting to 'smart'.") }
            }
        }
        
        let locator = AXorcist.Locator(
            match_all: locatorOptions.matchAll,
            criteria: parsedCriteria,
            root_element_path_hint: locatorOptions.rootPathHint.isEmpty ? nil : locatorOptions.rootPathHint,
            requireAction: locatorOptions.requireAction,
            computed_name_contains: locatorOptions.computedName
        )

        let commandID = "cli_query_" + UUID().uuidString.prefix(8)
        let envelope = AXorcist.CommandEnvelope(
            command_id: commandID,
            command: .query,
            application: self.application, 
            locator: locator,
            attributes: attributesToFetch.isEmpty ? nil : attributesToFetch,
            path_hint: pathHint.isEmpty ? nil : pathHint,
            debug_logging: isDebugLoggingEnabled,
            max_elements: maxElements,
            output_format: axOutputFormat
        )
        
        if isDebugLoggingEnabled {
            currentDebugLogs.append("Constructed CommandEnvelope for AXorcist.handleQuery with command_id: \(commandID)")
        }

        let queryResponseCodable = try AXorcist.handleQuery(cmd: envelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        
        sendResponse(queryResponseCodable, commandIdForError: commandID)
    }
}

private func isSTDINEmpty() -> Bool {
    let stdinFileDescriptor = FileHandle.standardInput.fileDescriptor
    var flags = fcntl(stdinFileDescriptor, F_GETFL, 0)
    flags |= O_NONBLOCK
    _ = fcntl(stdinFileDescriptor, F_SETFL, flags)

    let byte = UnsafeMutablePointer<CChar>.allocate(capacity: 1)
    defer { byte.deallocate() }
    let bytesRead = read(stdinFileDescriptor, byte, 1)

    return bytesRead <= 0
}

@MainActor
func processCommandData(_ jsonData: Data, isDebugLoggingEnabled: inout Bool, currentDebugLogs: inout [String]) async {
    let decoder = JSONDecoder()
    var commandID: String = "unknown_command_id"

    do {
        var tempEnvelopeForID: AXorcist.CommandEnvelope?
        do {
            tempEnvelopeForID = try decoder.decode(AXorcist.CommandEnvelope.self, from: jsonData)
            commandID = tempEnvelopeForID?.command_id ?? "id_decode_failed"
            if tempEnvelopeForID?.debug_logging == true && !isDebugLoggingEnabled {
                 isDebugLoggingEnabled = true
                 currentDebugLogs.append("Debug logging was enabled by 'debug_logging: true' in the JSON payload.")
            }
        } catch {
            if isDebugLoggingEnabled {
                currentDebugLogs.append("Failed to decode input JSON as CommandEnvelope to extract command_id initially. Error: \(String(reflecting: error))")
            }
        }

        if isDebugLoggingEnabled {
             currentDebugLogs.append("Processing command with assumed/decoded ID '\(commandID)'. Raw JSON (first 256 bytes): \(String(data: jsonData.prefix(256), encoding: .utf8) ?? "non-utf8 data")")
        }
        
        let envelope = try decoder.decode(AXorcist.CommandEnvelope.self, from: jsonData)
        commandID = envelope.command_id

        var finalEnvelope = envelope
        if isDebugLoggingEnabled && finalEnvelope.debug_logging != true {
            finalEnvelope = AXorcist.CommandEnvelope(
                command_id: envelope.command_id,
                command: envelope.command,
                application: envelope.application,
                locator: envelope.locator,
                action: envelope.action,
                value: envelope.value,
                attribute_to_set: envelope.attribute_to_set,
                attributes: envelope.attributes,
                path_hint: envelope.path_hint,
                debug_logging: true,
                max_elements: envelope.max_elements,
                output_format: envelope.output_format,
                perform_action_on_child_if_needed: envelope.perform_action_on_child_if_needed
            )
        }

        if isDebugLoggingEnabled {
             currentDebugLogs.append("Successfully decoded CommandEnvelope. Command: '\(finalEnvelope.command)', ID: '\(finalEnvelope.command_id)'. Effective debug_logging for AXorcist: \(finalEnvelope.debug_logging ?? false).")
        }

        let response: any Codable
        let startTime = DispatchTime.now()

        switch finalEnvelope.command {
        case .query:
            response = try AXorcist.handleQuery(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .performAction:
            response = try AXorcist.handlePerform(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .getAttributes:
            response = try AXorcist.handleGetAttributes(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .batch:
            response = try AXorcist.handleBatch(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .describeElement:
             response = try AXorcist.handleDescribeElement(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .getFocusedElement:
            response = try AXorcist.handleGetFocusedElement(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .collectAll:
            response = try AXorcist.handleCollectAll(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .extractText:
            response = try AXorcist.handleExtractText(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        @unknown default:
            throw AXorcist.AccessibilityError.invalidCommand("Unsupported command type: \(finalEnvelope.command.rawValue)")
        }
        
        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000_000
        
        if isDebugLoggingEnabled {
            currentDebugLogs.append("Command '\(commandID)' processed in \(String(format: "%.3f", timeInterval)) seconds.")
        }

        if var loggableResponse = response as? LoggableResponseProtocol {
            if isDebugLoggingEnabled && !currentDebugLogs.isEmpty {
                 loggableResponse.debug_logs = (loggableResponse.debug_logs ?? []) + currentDebugLogs
            }
            sendResponse(loggableResponse, commandIdForError: commandID)
        } else {
            if isDebugLoggingEnabled && !currentDebugLogs.isEmpty {
                // We have logs but can't attach them to this response type.
                // We could print them to stderr here, or accept they are lost for this specific response.
                // For now, let's just send the original response.
                // Consider: fputs("Orphaned debug logs for non-loggable response \(commandID): \(currentDebugLogs.joined(separator: "\n"))\n", stderr)
            }
            sendResponse(response, commandIdForError: commandID)
        }

    } catch let decodingError as DecodingError {
        var errorDetails = "Decoding error: \(decodingError.localizedDescription)."
        if isDebugLoggingEnabled {
            currentDebugLogs.append("Full decoding error: \(String(reflecting: decodingError))")
            switch decodingError {
            case .typeMismatch(let type, let context):
                errorDetails += " Type mismatch for '\(type)' at path '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'. Context: \(context.debugDescription)"
            case .valueNotFound(let type, let context):
                errorDetails += " Value not found for type '\(type)' at path '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'. Context: \(context.debugDescription)"
            case .keyNotFound(let key, let context):
                errorDetails += " Key not found: '\(key.stringValue)' at path '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'. Context: \(context.debugDescription)"
            case .dataCorrupted(let context):
                errorDetails += " Data corrupted at path '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'. Context: \(context.debugDescription)"
            @unknown default:
                errorDetails += " An unknown decoding error occurred."
            }
        }
        let finalErrorString = "Failed to decode the JSON command input. Error: \(decodingError.localizedDescription). Details: \(errorDetails)"
        let errResponse = AXorcist.ErrorResponse(command_id: commandID, 
                                                 error: finalErrorString, 
                                                 debug_logs: isDebugLoggingEnabled ? currentDebugLogs : nil)
        sendResponse(errResponse)
    } catch let axError as AXorcist.AccessibilityError {
        let errResponse = AXorcist.ErrorResponse(command_id: commandID, 
                                                 error: "Error processing command: \(axError.localizedDescription)", 
                                                 debug_logs: isDebugLoggingEnabled ? currentDebugLogs : nil)
        sendResponse(errResponse)
    } catch {
        let errResponse = AXorcist.ErrorResponse(command_id: commandID, 
                                                 error: "An unexpected error occurred: \(error.localizedDescription)", 
                                                 debug_logs: isDebugLoggingEnabled ? currentDebugLogs : nil)
        sendResponse(errResponse)
    }
}

func sendResponse<T: Codable>(_ response: T, commandIdForError: String? = nil) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    var dataToSend: Data?

    if var errorResp = response as? AXorcist.ErrorResponse, let cmdId = commandIdForError {
        if errorResp.command_id == "unknown_command_id" || errorResp.command_id.isEmpty {
            errorResp.command_id = cmdId
        }
        dataToSend = try? encoder.encode(errorResp)
    } else if let loggable = response as? LoggableResponseProtocol {
        dataToSend = try? encoder.encode(loggable)
    } else {
        dataToSend = try? encoder.encode(response)
    }

    guard let data = dataToSend, let jsonString = String(data: data, encoding: .utf8) else {
        let fallbackError = AXorcist.ErrorResponse(
            command_id: commandIdForError ?? "serialization_error",
            error: "Failed to serialize the response to JSON."
        )
        if let errorData = try? encoder.encode(fallbackError), let errorJsonString = String(data: errorData, encoding: .utf8) {
            print(errorJsonString)
            fflush(stdout)
        } else {
            print("{\"command_id\": \"\(commandIdForError ?? "critical_error")\", \"error\": \"Critical: Failed to serialize any response.\"}")
            fflush(stdout)
        }
        return
    }

    print(jsonString)
    fflush(stdout)
}

public protocol LoggableResponseProtocol: Codable {
    var debug_logs: [String]? { get set }
}

