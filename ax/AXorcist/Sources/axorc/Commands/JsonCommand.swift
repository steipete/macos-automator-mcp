mutating func run() throws {
    print("[AXORC_JSON_COMMAND_DEBUG] JsonCommand.run() entered.")

    var overallErrorMessagesFromDLog: [String] = []

    print("[AXORC_JSON_COMMAND_DEBUG] JsonCommand.run() PRE - Permission Check Task.")
    var permissionsStatus = AXPermissionsStatus.notDetermined // Default
    var permissionError: String? = nil

    print("[AXORC_JSON_COMMAND_DEBUG] JsonCommand.run() PRE - processCommandData Task.")
    var commandOutput: String? = nil
    var commandError: String? = nil

    semaphore.signal()
    semaphore.wait()
    print("[AXORC_JSON_COMMAND_DEBUG] JsonCommand.run() POST - Permission Check Task. Status: \(permissionsStatus), Error: \(permissionError ?? "None")")

    if let permError = permissionError {
        // ... existing code ...
    }

    if permissionsStatus != .authorized {
        // ... existing code ...
    }

    semaphore.signal()
    semaphore.wait()
    print("[AXORC_JSON_COMMAND_DEBUG] JsonCommand.run() POST - processCommandData Task. Output: \(commandOutput != nil), Error: \(commandError ?? "None")")

    let finalOutputString:
    // ... existing code ...

    print("AXORC_JSON_OUTPUT_PREFIX:::")
    print(finalOutputString)
    print("[AXORC_JSON_COMMAND_DEBUG] JsonCommand.run() finished, output printed.")
}

@MainActor // processCommandData now needs to be @MainActor because AXorcist.handle* are.
// ... existing code ... 