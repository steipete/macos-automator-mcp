// Logging.swift - Manages debug logging

import Foundation

public let GLOBAL_DEBUG_ENABLED = false // Should be let if not changed after init
@MainActor public var commandSpecificDebugLoggingEnabled = false
@MainActor public var collectedDebugLogs: [String] = []
@MainActor private var versionHeaderLoggedForCommand = false // New flag

@MainActor // Functions calling this might be on main actor, good to keep it consistent.
public func debug(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
    // file, function, line parameters are kept for future re-activation but not used in log strings for now.
    var messageToLog: String
    var printHeaderToStdErrSeparately = false

    if commandSpecificDebugLoggingEnabled {
        if !versionHeaderLoggedForCommand {
            let header = "DEBUG: AX: \(BINARY_VERSION) - Command Debugging Started"
            collectedDebugLogs.append(header)
            if GLOBAL_DEBUG_ENABLED {
                // We'll print header and current message together if GLOBAL_DEBUG_ENABLED
                printHeaderToStdErrSeparately = true // Mark that header needs printing with the first message
            }
            versionHeaderLoggedForCommand = true
            messageToLog = "  \(message)" // Indented message
        } else {
            messageToLog = "  \(message)" // Indented message
        }
        collectedDebugLogs.append(messageToLog) // Always collect command-specific logs

        // If GLOBAL_DEBUG is on, these command-specific logs (header + indented messages) also go to stderr.
        // This is handled by the GLOBAL_DEBUG_ENABLED block below.
    } else if GLOBAL_DEBUG_ENABLED {
        // Only GLOBAL_DEBUG_ENABLED is true (commandSpecific is false)
        messageToLog = "DEBUG: AX: \(BINARY_VERSION) - \(message)"
    } else {
        // Neither commandSpecificDebugLoggingEnabled nor GLOBAL_DEBUG_ENABLED is true.
        // No logging will occur. Initialize messageToLog to prevent errors, though it won't be used.
        messageToLog = "" 
    }

    if GLOBAL_DEBUG_ENABLED {
        if commandSpecificDebugLoggingEnabled {
            // Current message is already in messageToLog (indented).
            // If it was the first message, the header also needs to be printed.
            if printHeaderToStdErrSeparately {
                 let header = "DEBUG: AX: \(BINARY_VERSION) - Command Debugging Started"
                 fputs(header + "\n", stderr)
            }
            // Print the (potentially indented) messageToLog
            if !messageToLog.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || printHeaderToStdErrSeparately { // Avoid printing empty/whitespace only unless it's first after header
                 fputs(messageToLog + "\n", stderr)
            }
        } else {
            // Only GLOBAL_DEBUG_ENABLED is true, commandSpecificDebugLoggingEnabled is false.
            // messageToLog already contains the globally-prefixed message.
             if !messageToLog.isEmpty {
                fputs(messageToLog + "\n", stderr)
            }
        }
        fflush(stderr)
    }
}

// It's important to reset versionHeaderLoggedForCommand at the start of each new command.
// This will be handled in main.swift where collectedDebugLogs and commandSpecificDebugLoggingEnabled are reset.
// Adding a specific function here for clarity and to ensure it's done.
@MainActor
public func resetDebugLogContextForNewCommand() {
    versionHeaderLoggedForCommand = false
    // collectedDebugLogs and commandSpecificDebugLoggingEnabled are reset in main.swift
}