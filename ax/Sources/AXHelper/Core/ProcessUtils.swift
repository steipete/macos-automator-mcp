// ProcessUtils.swift - Utilities for process and application inspection.

import Foundation
import AppKit // For NSRunningApplication, NSWorkspace

// debug() is assumed to be globally available from Logging.swift

@MainActor
public func pid(forAppIdentifier ident: String) -> pid_t? {
    debug("Looking for app: \(ident)")

    if ident == "focused" {
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            debug("Identified frontmost application as: \(frontmostApp.localizedName ?? "Unknown") (PID: \(frontmostApp.processIdentifier))")
            return frontmostApp.processIdentifier
        } else {
            debug("Could not identify frontmost application via NSWorkspace.")
            return nil
        }
    }

    // Special handling for Safari to try bundle ID first, then localized name
    // This can be useful if there are multiple apps with "Safari" in the name but different bundle IDs.
    if ident.lowercased() == "safari" { // Make comparison case-insensitive for convenience
        if let safariApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Safari").first {
            debug("Found Safari by bundle ID: com.apple.Safari (PID: \(safariApp.processIdentifier))")
            return safariApp.processIdentifier
        }
        // Fall through to general localizedName check if bundle ID lookup fails or ident wasn't exactly "com.apple.Safari"
    }
    
    if let byBundle = NSRunningApplication.runningApplications(withBundleIdentifier: ident).first {
        debug("Found app by bundle ID: \(ident) (PID: \(byBundle.processIdentifier))")
        return byBundle.processIdentifier
    }
    if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == ident }) {
        debug("Found app by localized name (exact match): \(ident) (PID: \(app.processIdentifier))")
        return app.processIdentifier
    }
    // Case-insensitive fallback for localized name
    if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName?.lowercased() == ident.lowercased() }) {
        debug("Found app by localized name (case-insensitive): \(ident) (PID: \(app.processIdentifier))")
        return app.processIdentifier
    }
    debug("App not found: \(ident)")
    return nil
}

@MainActor
public func getParentProcessName() -> String? {
    let parentPid = getppid()
    if let parentApp = NSRunningApplication(processIdentifier: parentPid) {
        return parentApp.localizedName ?? parentApp.bundleIdentifier
    }
    return nil
}