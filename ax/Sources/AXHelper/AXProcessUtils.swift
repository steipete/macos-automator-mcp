// AXProcessUtils.swift - Utilities for process and application inspection.

import Foundation
import AppKit // For NSRunningApplication, NSWorkspace

// debug() is assumed to be globally available from AXLogging.swift

@MainActor
public func pid(forAppIdentifier ident: String) -> pid_t? {
    debug("Looking for app: \(ident)")
    if ident == "Safari" {
        if let safariApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Safari").first {
            return safariApp.processIdentifier
        }
        if let safariApp = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == "Safari" }) {
            return safariApp.processIdentifier
        }
    }
    if let byBundle = NSRunningApplication.runningApplications(withBundleIdentifier: ident).first {
        return byBundle.processIdentifier
    }
    if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == ident }) {
        return app.processIdentifier
    }
    if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName?.lowercased() == ident.lowercased() }) {
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