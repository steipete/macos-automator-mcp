// AccessibilityPermissions.swift - Utility for checking and managing accessibility permissions.

import Foundation
import ApplicationServices // For AXIsProcessTrusted(), AXUIElementCreateSystemWide(), etc.
import AppKit // For NSRunningApplication, NSAppleScript

private let kAXTrustedCheckOptionPromptKey = "AXTrustedCheckOptionPrompt"

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
    
    let trustedOptions = [kAXTrustedCheckOptionPromptKey: true] as CFDictionary
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

    dLog("Starting permission status check.")
    let isAccessibilitySetup = AXIsProcessTrusted() // Changed from AXAPIEnabled()
    dLog("AXIsProcessTrusted (general check): \(isAccessibilitySetup)")

    var isProcessTrustedForAccessibilityWithOptions = false // Renamed for clarity
    var overallErrorMessages: [String] = [] // This will capture high-level error messages for the user

    if isAccessibilitySetup { // Check if basic trust is there before prompting
        let trustedOptions = [kAXTrustedCheckOptionPromptKey: true] as CFDictionary
        isProcessTrustedForAccessibilityWithOptions = AXIsProcessTrustedWithOptions(trustedOptions)
        dLog("AXIsProcessTrustedWithOptions (prompt check): \(isProcessTrustedForAccessibilityWithOptions)")
        if !isProcessTrustedForAccessibilityWithOptions {
            let parentProcessName = getParentProcessName(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) ?? "Unknown Process"
            let errorMessage = "Process (ax, child of \(parentProcessName)) is not trusted for accessibility with prompt. Please grant permissions in System Settings > Privacy & Security > Accessibility."
            overallErrorMessages.append(errorMessage)
            dLog("Error: \(errorMessage)") // dLog will add to currentDebugLogs if enabled
        }
    } else {
        let parentProcessName = getParentProcessName(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) ?? "Unknown Process"
        let errorMessage = "Accessibility API is likely disabled or process (ax, child of \(parentProcessName)) lacks basic trust. Check System Settings > Privacy & Security > Accessibility."
        overallErrorMessages.append(errorMessage)
        dLog("Error: \(errorMessage)") // dLog will add to currentDebugLogs if enabled
        isProcessTrustedForAccessibilityWithOptions = false
    }

    var automationResults: [String: Bool] = [:]
    if isProcessTrustedForAccessibilityWithOptions { 
        for bundleID in bundleIDs {
            dLog("Checking automation permission for \(bundleID).")
            guard NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first(where: { !$0.isTerminated }) != nil else {
                dLog("Automation for \(bundleID): Not checked, application not running.")
                automationResults[bundleID] = nil 
                continue
            }

            let appleEventTestScript = "tell application id \"\(bundleID)\" to get its name\nend tell"
            var errorInfo: NSDictionary? = nil
            if let scriptObject = NSAppleScript(source: appleEventTestScript) {
                let result_optional: NSAppleEventDescriptor? = scriptObject.executeAndReturnError(&errorInfo)
                
                if let errorDict = errorInfo, let errorCode = errorDict[NSAppleScript.errorNumber] as? Int {
                    if errorCode == -1743 { 
                        dLog("Automation for \(bundleID): Denied by user (TCC). Error: \(errorCode).")
                        automationResults[bundleID] = false
                    } else if errorCode == -600 || errorCode == -609 { 
                         dLog("Automation for \(bundleID): Failed, app may have quit or doesn't support scripting. Error: \(errorCode).")
                         automationResults[bundleID] = nil 
                    } else {
                        let errorMessage = errorDict[NSAppleScript.errorMessage] ?? "unknown"
                        dLog("Automation for \(bundleID): Failed with AppleScript error \(errorCode). Details: \(errorMessage).")
                        automationResults[bundleID] = false 
                    }
                } else if errorInfo == nil && result_optional != nil { 
                    dLog("Automation for \(bundleID): Succeeded.")
                    automationResults[bundleID] = true
                } else { 
                    let errorDetailsFromDict = (errorInfo as? [String: Any])?.description ?? "none"
                    dLog("Automation for \(bundleID): Failed. Result: \(result_optional?.description ?? "nil"), ErrorInfo: \(errorDetailsFromDict).")
                    automationResults[bundleID] = false 
                }
            } else {
                dLog("Automation for \(bundleID): Could not create AppleScript object for check.")
                automationResults[bundleID] = false 
            }
        }
    } else {
        dLog("Skipping automation checks: Process not trusted for Accessibility.")
    }
    
    let finalStatus = AXPermissionsStatus(
        isAccessibilityApiEnabled: isAccessibilitySetup, 
        isProcessTrustedForAccessibility: isProcessTrustedForAccessibilityWithOptions, 
        automationStatus: automationResults,
        overallErrorMessages: overallErrorMessages 
    )
    dLog("Permission status check complete. Result: isAccessibilityApiEnabled=\(finalStatus.isAccessibilityApiEnabled), isProcessTrustedForAccessibility=\(finalStatus.isProcessTrustedForAccessibility), automationStatus=\(finalStatus.automationStatus), overallErrorMessages=\(finalStatus.overallErrorMessages.joined(separator: "; "))")
    return finalStatus
}