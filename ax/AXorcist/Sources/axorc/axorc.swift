import Foundation
import AXorcist
import ArgumentParser

// Updated BIARY_VERSION to a more descriptive name
let AXORC_BINARY_VERSION = "0.9.0" // Example version

// --- Global Options Definition ---
struct GlobalOptions: ParsableArguments {
    @Flag(name: .long, help: "Enable detailed debug logging for AXORC operations.")
    var debug: Bool = false
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

// --- Input method definitions (restored here, before JsonCommand uses them) ---
struct StdinInput: ParsableArguments {
    @Flag(name: .long, help: "Read JSON payload from STDIN.")
    var stdin: Bool = false
}

struct FileInput: ParsableArguments {
    @Option(name: .long, help: "Path to a JSON file.")
    var file: String?
}

struct PayloadInput: ParsableArguments {
    @Option(name: .long, help: "JSON payload as a string.")
    var payload: String?
}

@main
struct AXORC: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "AXORC - macOS Accessibility Inspector & Executor.",
        version: AXORC_BINARY_VERSION,
        subcommands: [JsonCommand.self, QueryCommand.self],
        defaultSubcommand: JsonCommand.self
    )

    @OptionGroup var globalOptions: GlobalOptions

    // @Flag(name: .long, help: "Read JSON payload from STDIN (moved to AXORC for test).")
    // var stdin: Bool = false // Remove this from AXORC

    // Restore original AXORC.run()
    mutating func run() throws {
        fputs("--- AXORC.run() ENTERED ---\n", stderr)
        fflush(stderr)
        if globalOptions.debug {
             fputs("--- AXORC.run() globalOptions.debug is TRUE ---\n", stderr)
             fflush(stderr)
        } else {
             fputs("--- AXORC.run() globalOptions.debug is FALSE ---\n", stderr)
             fflush(stderr)
        }
        // If no subcommand is specified, and a default is set, ArgumentParser runs the default.
        // If a subcommand is specified, its run() is called.
        // If no subcommand and no default, help is shown.
        fputs("--- AXORC.run() EXITING ---\n", stderr)
        fflush(stderr)
    }
}

// Restore JsonCommand struct definition
struct JsonCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "json",
        abstract: "Process a command from a JSON payload. Use --stdin, --file <path>, or --payload '<json>'."
    )

    @OptionGroup var globalOptions: GlobalOptions
    
    @OptionGroup var stdinInputOptions: StdinInput
    @OptionGroup var fileInputOptions: FileInput
    @OptionGroup var payloadInputOptions: PayloadInput

    // Restored run() method
    mutating func run() throws {
        var localCurrentDebugLogs: [String] = []
        var localIsDebugLoggingEnabled = globalOptions.debug

        if localIsDebugLoggingEnabled {
            localCurrentDebugLogs.append("Debug logging enabled for JsonCommand via global --debug flag.")
            fputs("[JsonCommand.run] Debug logging is ON.\n", stderr); fflush(stderr)
        }
        
        fputs("[JsonCommand.run] [DEBUG_PRINT_INSERTION_POINT_1]\n", stderr); fflush(stderr)

        // Synchronous Permission Check
        fputs("[JsonCommand.run] PRE - Permission Check (Direct Sync Call).\n", stderr); fflush(stderr)
        let permissionStatusCheck = AXorcist.getPermissionsStatus(
            checkAutomationFor: [], // Assuming no specific app for initial check, or adjust as needed
            isDebugLoggingEnabled: localIsDebugLoggingEnabled,
            currentDebugLogs: &localCurrentDebugLogs
        )
        fputs("[JsonCommand.run] POST - Permission Check (Direct Sync Call). Status: \(permissionStatusCheck.canUseAccessibility), Errors: \(permissionStatusCheck.overallErrorMessages.joined(separator: "; "))\n", stderr); fflush(stderr)

        if !permissionStatusCheck.canUseAccessibility {
            let messages = permissionStatusCheck.overallErrorMessages
            let errorDetail = messages.isEmpty ? "Permissions not sufficient." : messages.joined(separator: "; ")
            let errorResponse = AXorcist.ErrorResponse(
                command_id: "json_cmd_perm_check_failed",
                error: "Accessibility permission check failed: \(errorDetail)",
                debug_logs: localCurrentDebugLogs + permissionStatusCheck.overallErrorMessages
            )
            sendResponse(errorResponse) // sendResponse already adds prefix and prints
            throw ExitCode.failure
        }
        
        fputs("[JsonCommand.run] [DEBUG_PRINT_INSERTION_POINT_2]\n", stderr); fflush(stderr)

        // Input JSON Acquisition
        fputs("[JsonCommand.run] PRE - Input JSON Acquisition.\n", stderr); fflush(stderr)
        var commandInputJSON: String?
        var activeInputMethods = 0
        var chosenMethodDetails: String = "none"

        if stdinInputOptions.stdin { activeInputMethods += 1; chosenMethodDetails = "--stdin flag" }
        if fileInputOptions.file != nil { activeInputMethods += 1; chosenMethodDetails = "--file flag" }
        if payloadInputOptions.payload != nil { activeInputMethods += 1; chosenMethodDetails = "--payload flag" }

        if activeInputMethods == 0 {
            if !isSTDINEmpty() {
                chosenMethodDetails = "implicit STDIN (not empty)"
                if localIsDebugLoggingEnabled { localCurrentDebugLogs.append("JsonCommand: No input flag, defaulting to STDIN as it has content.") }
                fputs("[JsonCommand.run] Reading from implicit STDIN as no flags set and STDIN not empty.\n", stderr); fflush(stderr)
                var inputData = Data()
                let stdinFileHandle = FileHandle.standardInput
                // This can block if STDIN is open but no data is sent.
                // For CLI, this is usually fine. For tests, ensure data is piped *before* process launch or handle this.
                inputData = stdinFileHandle.readDataToEndOfFile()
                if !inputData.isEmpty {
                    commandInputJSON = String(data: inputData, encoding: .utf8)
                    if commandInputJSON == nil && localIsDebugLoggingEnabled {
                        localCurrentDebugLogs.append("JsonCommand: Failed to decode implicit STDIN data as UTF-8.")
                    }
                } else {
                    localCurrentDebugLogs.append("JsonCommand: STDIN was checked (implicit), but was empty or became empty.")
                    fputs("[JsonCommand.run] Implicit STDIN was or became empty.\n", stderr); fflush(stderr)
                    // No error yet, will be caught by commandInputJSON == nil check later
                }
            } else {
                chosenMethodDetails = "no input flags and STDIN empty"
                localCurrentDebugLogs.append("JsonCommand: No input flags and STDIN is also empty.")
                fputs("[JsonCommand.run] No input flags and STDIN is empty. Erroring out.\n", stderr); fflush(stderr)
                let errorResponse = AXorcist.ErrorResponse(command_id: "no_input_method_sync", error: "No input specified (e.g., --stdin, --file, --payload) and STDIN is empty.", debug_logs: localCurrentDebugLogs)
                sendResponse(errorResponse); throw ExitCode.failure
            }
        } else if activeInputMethods > 1 {
            localCurrentDebugLogs.append("JsonCommand: Multiple input methods specified: stdin=\(stdinInputOptions.stdin), file=\(fileInputOptions.file != nil), payload=\(payloadInputOptions.payload != nil).")
            fputs("[JsonCommand.run] Multiple input methods specified. Erroring out.\n", stderr); fflush(stderr)
            let errorResponse = AXorcist.ErrorResponse(command_id: "multiple_input_methods_sync", error: "Multiple input methods. Use only one of --stdin, --file, or --payload.", debug_logs: localCurrentDebugLogs)
            sendResponse(errorResponse); throw ExitCode.failure
        } else { // Exactly one input method specified by flag
            if stdinInputOptions.stdin {
                chosenMethodDetails = "--stdin flag explicit"
                if localIsDebugLoggingEnabled { localCurrentDebugLogs.append("JsonCommand: Input via --stdin flag.") }
                fputs("[JsonCommand.run] Reading from STDIN via --stdin flag.\n", stderr); fflush(stderr)
                var inputData = Data(); let fh = FileHandle.standardInput; inputData = fh.readDataToEndOfFile()
                if !inputData.isEmpty { commandInputJSON = String(data: inputData, encoding: .utf8) }
                else {
                    localCurrentDebugLogs.append("JsonCommand: --stdin flag given, but STDIN was empty.")
                    fputs("[JsonCommand.run] --stdin flag given, but STDIN was empty. Erroring out.\n", stderr); fflush(stderr)
                    let err = AXorcist.ErrorResponse(command_id: "stdin_flag_no_data_sync", error: "--stdin flag used, but STDIN was empty.", debug_logs: localCurrentDebugLogs); sendResponse(err); throw ExitCode.failure
                }
            } else if let filePath = fileInputOptions.file {
                chosenMethodDetails = "--file '\(filePath)'"
                if localIsDebugLoggingEnabled { localCurrentDebugLogs.append("JsonCommand: Input via --file '\(filePath)'.") }
                fputs("[JsonCommand.run] Reading from file: \(filePath).\n", stderr); fflush(stderr)
                do { commandInputJSON = try String(contentsOfFile: filePath, encoding: .utf8) }
                catch {
                    localCurrentDebugLogs.append("JsonCommand: Failed to read file '\(filePath)': \(error)")
                    fputs("[JsonCommand.run] Failed to read file '\(filePath)': \(error). Erroring out.\n", stderr); fflush(stderr)
                    let err = AXorcist.ErrorResponse(command_id: "file_read_error_sync", error: "Failed to read file '\(filePath)': \(error.localizedDescription)", debug_logs: localCurrentDebugLogs); sendResponse(err); throw ExitCode.failure
                }
            } else if let payloadStr = payloadInputOptions.payload {
                chosenMethodDetails = "--payload string"
                if localIsDebugLoggingEnabled { localCurrentDebugLogs.append("JsonCommand: Input via --payload string.") }
                fputs("[JsonCommand.run] Using payload from --payload string.\n", stderr); fflush(stderr)
                commandInputJSON = payloadStr
            } else {
                // This case should not be reached if activeInputMethods == 1
                localCurrentDebugLogs.append("JsonCommand: Internal logic error in input method selection (activeInputMethods=1 but no known flag matched).")
                fputs("[JsonCommand.run] Internal logic error in input method selection. Erroring out.\n", stderr); fflush(stderr)
                let err = AXorcist.ErrorResponse(command_id: "internal_input_logic_error_sync", error: "Internal input logic error.", debug_logs: localCurrentDebugLogs); sendResponse(err); throw ExitCode.failure
            }
        }
        
        fputs("[JsonCommand.run] POST - Input JSON Acquisition. Method: \(chosenMethodDetails). JSON acquired: \(commandInputJSON != nil).\n", stderr); fflush(stderr)

        guard let finalCommandInputJSON = commandInputJSON, let jsonDataToProcess = finalCommandInputJSON.data(using: .utf8) else {
            localCurrentDebugLogs.append("JsonCommand: Command input JSON was nil or could not be UTF-8 encoded. Chosen method was: \(chosenMethodDetails).")
            fputs("[JsonCommand.run] ERROR - commandInputJSON is nil or not UTF-8. Erroring out.\n", stderr); fflush(stderr)
            let errorResponse = AXorcist.ErrorResponse(command_id: "input_json_nil_or_encoding_error_sync", error: "Input JSON was nil or could not be UTF-8 encoded after using method: \(chosenMethodDetails).", debug_logs: localCurrentDebugLogs)
            sendResponse(errorResponse); throw ExitCode.failure
        }
        
        fputs("[JsonCommand.run] [DEBUG_PRINT_INSERTION_POINT_3]\n", stderr); fflush(stderr)

        // Process Command Data via Task.detached
        fputs("[JsonCommand.run] PRE - processCommandData Task (Task.detached).\n", stderr); fflush(stderr)
        let processSemaphore = DispatchSemaphore(value: 0)
        var processTaskOutcome: Result<Void, Error>?
        // Copy current logs to be passed to the task; task will append to its copy
        var tempLogsForTask = localCurrentDebugLogs 
        var tempIsDebugEnabledForTask = localIsDebugLoggingEnabled

        Task.detached {
            fputs("[JsonCommand.run][Task.detached] Entered async block for processCommandData.\n", stderr); fflush(stderr)
            // processCommandData will handle its own errors by calling sendResponse and throwing if needed.
            // However, we still need to capture any general Swift error from the await or if processCommandData itself throws
            // an unexpected error type *before* it calls sendResponse.
            // The `processCommandData` function itself is non-throwing in its signature but calls throwing AXorcist handlers.
            // It catches errors from those handlers and calls sendResponse.
            // So, we mainly expect this Task not to throw here unless something fundamental in processCommandData is broken.
            await processCommandData(jsonDataToProcess,
                                     isDebugLoggingEnabled: &tempIsDebugEnabledForTask,
                                     currentDebugLogs: &tempLogsForTask)
            // If processCommandData completed (even if it internally handled an error and called sendResponse),
            // we mark this task wrapper as successful. The actual success/failure of the command
            // is communicated via the JSON response.
            processTaskOutcome = .success(())
            fputs("[JsonCommand.run][Task.detached] Exiting async block. Signalling semaphore.\n", stderr); fflush(stderr)
            processSemaphore.signal()
        }
        
        fputs("[JsonCommand.run] Waiting on processSemaphore for processCommandData task...\n", stderr); fflush(stderr)
        processSemaphore.wait()
        fputs("[JsonCommand.run] processSemaphore signalled. processCommandData task finished.\n", stderr); fflush(stderr)
        
        // Merge logs from the task back to main logs, avoiding duplicates
        // (though with inout, tempLogsForTask should reflect all changes)
        localCurrentDebugLogs = tempLogsForTask
        localIsDebugLoggingEnabled = tempIsDebugEnabledForTask


        if case .failure(let error) = processTaskOutcome { // Should be rare given processCommandData's error handling
            localCurrentDebugLogs.append("JsonCommand: Critical failure in processCommandData Task.detached wrapper: \(error.localizedDescription)")
            fputs("[JsonCommand.run] CRITICAL ERROR in processCommandData Task.detached wrapper: \(error.localizedDescription). This is unexpected.\n", stderr); fflush(stderr)
            let errorResponse = AXorcist.ErrorResponse(
                command_id: "process_cmd_task_wrapper_error",
                error: "Async task wrapper for command processing failed: \(error.localizedDescription)",
                debug_logs: localCurrentDebugLogs
            )
            sendResponse(errorResponse)
            throw ExitCode.failure
        } else if processTaskOutcome == nil { // Should not happen
             localCurrentDebugLogs.append("JsonCommand: processCommandData task outcome was unexpectedly nil.")
            fputs("[JsonCommand.run] CRITICAL ERROR: processCommandData task outcome was nil. This should not happen.\n", stderr); fflush(stderr)
            let errorResponse = AXorcist.ErrorResponse(
                command_id: "process_cmd_nil_outcome",
                error: "Internal error: Command processing task outcome not set.",
                debug_logs: localCurrentDebugLogs
            )
            sendResponse(errorResponse)
            throw ExitCode.failure
        }
        
        fputs("[JsonCommand.run] [DEBUG_PRINT_INSERTION_POINT_4]\n", stderr); fflush(stderr)
        // If we've reached here, processCommandData has finished and (should have) already sent its response.
        // JsonCommand.run() itself doesn't produce a response beyond what processCommandData does.
        fputs("[JsonCommand.run] EXITING successfully from synchronous run (processCommandData handled response).\n", stderr); fflush(stderr)
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
    var stdinQuery: Bool = false // Renamed to avoid conflict if merged with JsonCommand one day

    // Synchronous run method
    mutating func run() throws {
        let semaphore = DispatchSemaphore(value: 0)
        var taskOutcome: Result<Void, Error>?
        
        // Capture self for use in the Task. 
        // ArgumentParser properties are generally safe to capture by value for async tasks if they are not mutated by the task itself.
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
            return // Success, performQueryLogic handled response or exit
        case .failure(let error):
            if error is ExitCode { // If performQueryLogic threw an ExitCode, rethrow it
                throw error
            } else {
                // For other errors, log and throw a generic failure
                fputs("QueryCommand.run: Unhandled error from performQueryLogic: \(error.localizedDescription)\n", stderr); fflush(stderr)
                throw ExitCode.failure
            }
        case nil:
            // This case should ideally not be reached if semaphore logic is correct
            fputs("Error: Task outcome was nil after semaphore wait in QueryCommand. This should not happen.\n", stderr)
            throw ExitCode.failure
        }
    }

    // Asynchronous and @MainActor logic method
    @MainActor
    private func performQueryLogic() async throws { // Non-mutating (self is a captured let constant)
        var isDebugLoggingEnabled = globalOptions.debug
        var currentDebugLogs: [String] = [] 

        if isDebugLoggingEnabled {
            currentDebugLogs.append("Debug logging enabled for QueryCommand via global --debug flag.")
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
            if isDebugLoggingEnabled { currentDebugLogs.append("Input source for QueryCommand: File ('\(filePath)')") }
            do {
                let fileContents = try String(contentsOfFile: filePath, encoding: .utf8)
                guard let jsonData = fileContents.data(using: .utf8) else {
                    let errResp = AXorcist.ErrorResponse(command_id: "cli_query_file_encoding_error", error: "Failed to encode file contents to UTF-8 data from \(filePath).")
                    sendResponse(errResp); throw ExitCode.failure
                }
                // processCommandData is designed to take jsonData and call the appropriate AXorcist handler based on the decoded command.
                // For QueryCommand, this means it will decode a CommandEnvelope and call AXorcist.handleQuery.
                await processCommandData(jsonData, isDebugLoggingEnabled: &isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
                return 
            } catch {
                let errResp = AXorcist.ErrorResponse(command_id: "cli_query_file_read_error", error: "Failed to read or process query from file '\(filePath)': \(error.localizedDescription)", debug_logs: currentDebugLogs)
                sendResponse(errResp); throw ExitCode.failure
            }
        } else if stdinQuery { // Use the renamed stdinQuery flag
            if isDebugLoggingEnabled { currentDebugLogs.append("Input source for QueryCommand: STDIN") }
            if isSTDINEmpty() {
                let errResp = AXorcist.ErrorResponse(command_id: "cli_query_stdin_empty", error: "--stdin-query flag was given, but STDIN is empty.", debug_logs: currentDebugLogs)
                sendResponse(errResp); throw ExitCode.failure
            }
            var inputData = Data()
            let stdinFileHandle = FileHandle.standardInput
            inputData = stdinFileHandle.readDataToEndOfFile() 
            guard !inputData.isEmpty else {
                 let errResp = AXorcist.ErrorResponse(command_id: "cli_query_stdin_no_data", error: "--stdin-query flag was given, but no data could be read from STDIN.", debug_logs: currentDebugLogs)
                sendResponse(errResp); throw ExitCode.failure
            }
            await processCommandData(inputData, isDebugLoggingEnabled: &isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            return 
        }

        // If not using inputFile or stdinQuery, proceed with CLI arguments to construct the command.
        if isDebugLoggingEnabled { currentDebugLogs.append("Input source for QueryCommand: CLI arguments") }

        var parsedCriteria: [String: String] = [:]
        if let criteriaString = locatorOptions.criteria, !criteriaString.isEmpty {
            let pairs = criteriaString.split(separator: ";")
            for pair in pairs {
                let keyValue = pair.split(separator: "=", maxSplits: 1)
                if keyValue.count == 2 {
                    parsedCriteria[String(keyValue[0])] = String(keyValue[1])
                } else {
                    if isDebugLoggingEnabled { currentDebugLogs.append("Warning: Malformed criteria pair '\(pair)' in --criteria string will be ignored.") }
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
                if isDebugLoggingEnabled { currentDebugLogs.append("Warning: Unknown --output-format '\(fmtStr)'. Defaulting to 'smart'.") }
            }
        }
        
        let locator = AXorcist.Locator(
            match_all: locatorOptions.matchAll,
            criteria: parsedCriteria, // Pass parsedCriteria directly (it's [String:String], not optional)
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
            debug_logging: isDebugLoggingEnabled, // Pass the effective debug state
            max_elements: maxElements,
            output_format: axOutputFormat
        )
        
        if isDebugLoggingEnabled {
            currentDebugLogs.append("Constructed CommandEnvelope for AXorcist.handleQuery with command_id: \(commandID). Locator: \(locator)")
        }

        let queryResponseCodable = try AXorcist.handleQuery(cmd: envelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        
        // AXorcist.handleQuery returns a type conforming to Codable & LoggableResponseProtocol.
        // The sendResponse function will handle adding debug logs if necessary.
        sendResponse(queryResponseCodable, commandIdForError: commandID)
    }
}

// ... (Input method definitions StdinInput, FileInput, PayloadInput are already restored and used by JsonCommand)
// ... (rest of the file: isSTDINEmpty, processCommandData, sendResponse, LoggableResponseProtocol)

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

// processCommandData is not used by the most simplified AXORC.run(), but keep for eventual restoration
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
            response = try await AXorcist.handleQuery(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .performAction:
            response = try await AXorcist.handlePerform(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .getAttributes:
            response = try await AXorcist.handleGetAttributes(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .batch:
            response = try await AXorcist.handleBatch(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .describeElement:
             response = try await AXorcist.handleDescribeElement(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .getFocusedElement:
            response = try await AXorcist.handleGetFocusedElement(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .collectAll:
            response = try await AXorcist.handleCollectAll(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        case .extractText:
            response = try await AXorcist.handleExtractText(cmd: finalEnvelope, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
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
    let outputPrefix = "AXORC_JSON_OUTPUT_PREFIX:::"

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
        if let errorData = try? encoder.encode(fallbackError), var errorJsonString = String(data: errorData, encoding: .utf8) {
            errorJsonString = outputPrefix + errorJsonString // Add prefix to fallback error
            print(errorJsonString)
            fflush(stdout)
        } else {
            // Critical fallback, ensure it still gets the prefix
            let criticalErrorJson = "{\"command_id\": \"\(commandIdForError ?? "critical_error")\", \"error\": \"Critical: Failed to serialize any response.\"}"
            print(outputPrefix + criticalErrorJson)
            fflush(stdout)
        }
        return
    }

    print(outputPrefix + jsonString) // Add prefix to normal output
    fflush(stdout)
}

public protocol LoggableResponseProtocol: Codable {
    var debug_logs: [String]? { get set }
}

