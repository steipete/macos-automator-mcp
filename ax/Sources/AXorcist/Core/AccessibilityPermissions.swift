// AccessibilityPermissions.swift - Utility for checking and managing accessibility permissions.

import Foundation
import ApplicationServices // For AXIsProcessTrusted(), AXUIElementCreateSystemWide(), etc.
import AppKit // For NSRunningApplication, NSAppleScript

// debug() is assumed to be globally available from Logging.swift
// getParentProcessName() is assumed to be globally available from ProcessUtils.swift
// kAXFocusedUIElementAttribute is assumed to be globally available from AccessibilityConstants.swift
// AccessibilityError is from AccessibilityError.swift

public struct AXPermissionsStatus {
    public let isAccessibilityApiEnabled: Bool
    public let isProcessTrustedForAccessibility: Bool
    public var automationStatus: [String: Bool] = [:] // BundleID: Bool (true if permitted, false if denied, nil if not checked or app not running)
    public var overallErrorMessages: [String] = []

    public var canUseAccessibility: Bool {
        isAccessibilityApiEnabled && isProcessTrustedForAccessibility
    }

    public func canAutomate(bundleID: String) -> Bool? {
        return automationStatus[bundleID]
    }
}

@MainActor
public func checkAccessibilityPermissions(isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) throws {
    // Define local dLog using passed-in parameters
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    
    let kAXTrustedCheckOptionPromptString = "AXTrustedCheckOptionPrompt"
    let trustedOptions = [kAXTrustedCheckOptionPromptString: true] as CFDictionary
    // tempLogs is already declared for getParentProcessName, which is good.
    // var tempLogs: [String] = [] // This would be a re-declaration error if uncommented

    if !AXIsProcessTrustedWithOptions(trustedOptions) { 
        // Use isDebugLoggingEnabled for the call to getParentProcessName
        let parentName = getParentProcessName(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) 
        let errorDetail = parentName != nil ? "Hint: Grant accessibility permissions to '\(parentName!)'." : "Hint: Ensure the application running this tool has Accessibility permissions."
        dLog("Accessibility check failed (AXIsProcessTrustedWithOptions returned false). Details: \(errorDetail)")
        throw AccessibilityError.notAuthorized(errorDetail) 
    } else {
        dLog("Accessibility permissions are granted (AXIsProcessTrustedWithOptions returned true).")
    }
}

@MainActor
public func getPermissionsStatus(checkAutomationFor bundleIDs: [String] = [], isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> AXPermissionsStatus {
    // Local dLog appends to currentDebugLogs, which will be returned as overallErrorMessages
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }

    var accEnabled = true 
    var accTrusted = false
    // tempLogsForParentName is correctly scoped locally for its specific getParentProcessName call.

    let kAXTrustedCheckOptionPromptString = "AXTrustedCheckOptionPrompt"
    let trustedOptionsWithoutPrompt = [kAXTrustedCheckOptionPromptString: false] as CFDictionary

    if AXIsProcessTrustedWithOptions(trustedOptionsWithoutPrompt) {
        accTrusted = true
        dLog("getPermissionsStatus: Process is trusted for Accessibility.")
    } else {
        accTrusted = false
        var tempLogsForParentNameScope: [String] = [] // Ensure this is a fresh, local log array for this specific call
        // Use isDebugLoggingEnabled for the call to getParentProcessName
        let parentName = getParentProcessName(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogsForParentNameScope) 
        currentDebugLogs.append(contentsOf: tempLogsForParentNameScope) // Merge logs from getParentProcessName
        let errorDetail = parentName != nil ? "Accessibility not granted to '\(parentName!)' or API disabled." : "Process not trusted for Accessibility or API disabled."
        dLog("getPermissionsStatus: Process is NOT trusted for Accessibility (or API disabled). Details: \(errorDetail)")
    }

    var automationResults: [String: Bool] = [:]
    if accTrusted { 
        for bundleID in bundleIDs {
            dLog("getPermissionsStatus: Checking automation for \(bundleID)")
            guard NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first(where: { !$0.isTerminated }) != nil else {
                dLog("getPermissionsStatus: Target application \(bundleID) for automation check is not running.")
                automationResults[bundleID] = nil 
                currentDebugLogs.append("Automation for \(bundleID): Not checked, application not running.")
                continue
            }

            let appleEventTestScript = "tell application id \"\(bundleID)\" to get its name\nend tell"
            var errorInfo: NSDictionary? = nil
            if let scriptObject = NSAppleScript(source: appleEventTestScript) {
                let result_optional: NSAppleEventDescriptor? = scriptObject.executeAndReturnError(&errorInfo)
                
                if let errorDict = errorInfo, let errorCode = errorDict[NSAppleScript.errorNumber] as? Int {
                    if errorCode == -1743 { 
                        dLog("getPermissionsStatus: Automation for \(bundleID) DENIED (TCC). Error: \(errorCode)")
                        automationResults[bundleID] = false
                        currentDebugLogs.append("Automation for \(bundleID): Denied by user (TCC). Error: \(errorCode).")
                    } else if errorCode == -600 || errorCode == -609 { 
                         dLog("getPermissionsStatus: Automation check for \(bundleID) FAILED (app not found/quit or no scripting interface). Error: \(errorCode)")
                         automationResults[bundleID] = nil 
                         currentDebugLogs.append("Automation for \(bundleID): Failed, app may have quit or doesn\'t support scripting. Error: \(errorCode).")
                    } else {
                        dLog("getPermissionsStatus: Automation check for \(bundleID) FAILED with AppleScript error \(errorCode). Details: \(errorDict[NSAppleScript.errorMessage] ?? "unknown")")
                        automationResults[bundleID] = false 
                        currentDebugLogs.append("Automation for \(bundleID): Failed with AppleScript error \(errorCode). Details: \(errorDict[NSAppleScript.errorMessage] ?? "unknown")")
                    }
                } else if errorInfo == nil && result_optional != nil { 
                    dLog("getPermissionsStatus: Automation check for \(bundleID) SUCCEEDED.")
                    automationResults[bundleID] = true
                } else { 
                    let errorDetailsFromDict = (errorInfo as? [String: Any])?.description ?? "none"
                    dLog("getPermissionsStatus: Automation check for \(bundleID) FAILED. Result: \(result_optional?.description ?? "nil"), ErrorInfo: \(errorDetailsFromDict).")
                    automationResults[bundleID] = false 
                    currentDebugLogs.append("Automation for \(bundleID): Failed. Result: \(result_optional?.description ?? "nil"), ErrorInfo: \(errorDetailsFromDict).")
                }
            } else {
                dLog("getPermissionsStatus: Failed to create NSAppleScript object for \(bundleID).")
                automationResults[bundleID] = false 
                currentDebugLogs.append("Automation for \(bundleID): Could not create AppleScript for check.")
            }
        }
    } else {
        dLog("getPermissionsStatus: Skipping automation checks as process is not trusted for Accessibility.")
        currentDebugLogs.append("Automation checks skipped: Process not trusted for Accessibility.")
    }
    
    if !accTrusted {
        accEnabled = false 
    }

    // Use currentDebugLogs directly as it has accumulated all messages.
    return AXPermissionsStatus(
        isAccessibilityApiEnabled: accEnabled, 
        isProcessTrustedForAccessibility: accTrusted,
        automationStatus: automationResults,
        overallErrorMessages: currentDebugLogs 
    )
}