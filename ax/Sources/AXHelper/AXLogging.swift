// AXLogging.swift - Manages debug logging

import Foundation

// More advanced logging setup
public let GLOBAL_DEBUG_ENABLED = true // Consistent with previous advanced setup
@MainActor public var commandSpecificDebugLoggingEnabled = false
@MainActor public var collectedDebugLogs: [String] = []

@MainActor // Functions calling this might be on main actor, good to keep it consistent.
public func debug(_ message: String) {
    // AX_BINARY_VERSION is in AXConstants.swift
    let logMessage = "DEBUG: AX Binary Version: \(AX_BINARY_VERSION) - \(message)"
    if commandSpecificDebugLoggingEnabled {
        collectedDebugLogs.append(logMessage)
    }
    if GLOBAL_DEBUG_ENABLED {
        fputs(logMessage + "\n", stderr)
    }
} 