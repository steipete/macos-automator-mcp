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

    // Try to get by bundle identifier first
    if let app = NSRunningApplication.runningApplications(withBundleIdentifier: ident).first {
        debug("Found running application by bundle ID \(ident) as: \(app.localizedName ?? "Unknown") (PID: \(app.processIdentifier))")
        return app.processIdentifier
    }

    // If not found by bundle ID, try to find by name (localized or process name if available)
    let allApps = NSWorkspace.shared.runningApplications
    if let app = allApps.first(where: { $0.localizedName?.lowercased() == ident.lowercased() }) {
        debug("Found running application by localized name \(ident) as: \(app.localizedName ?? "Unknown") (PID: \(app.processIdentifier))")
        return app.processIdentifier
    }

    // As a further fallback, check if `ident` might be a path to an app bundle
    let potentialPath = (ident as NSString).expandingTildeInPath
    if FileManager.default.fileExists(atPath: potentialPath),
       let bundle = Bundle(path: potentialPath),
       let bundleId = bundle.bundleIdentifier,
       let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first {
        debug("Found running application via path '\(potentialPath)' (resolved to bundleID '\(bundleId)') as: \(app.localizedName ?? "Unknown") (PID: \(app.processIdentifier))")
        return app.processIdentifier
    }
    
    // Finally, as a last resort, try to interpret `ident` as a PID string
    if let pidInt = Int32(ident) {
        if let app = NSRunningApplication(processIdentifier: pidInt) {
            debug("Identified application by PID string '\(ident)' as: \(app.localizedName ?? "Unknown") (PID: \(app.processIdentifier))")
            return pidInt
        } else {
            debug("String '\(ident)' looked like a PID but no running application found for it.")
        }
    }

    debug("Application with identifier '\(ident)' not found running (tried bundle ID, name, path, and PID string).")
    return nil
}

@MainActor
func findFrontmostApplicationPid() -> pid_t? {
    if let frontmostApp = NSWorkspace.shared.frontmostApplication {
        debug("Identified frontmost application as: \(frontmostApp.localizedName ?? "Unknown") (PID: \(frontmostApp.processIdentifier))")
        return frontmostApp.processIdentifier
    } else {
        debug("Could not identify frontmost application via NSWorkspace.")
        return nil
    }
}

@MainActor
public func getParentProcessName() -> String? {
    let parentPid = getppid()
    if let parentApp = NSRunningApplication(processIdentifier: parentPid) {
        return parentApp.localizedName ?? parentApp.bundleIdentifier
    }
    return nil
}