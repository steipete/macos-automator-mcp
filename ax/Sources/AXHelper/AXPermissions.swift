// AXPermissions.swift - Utility for checking and managing accessibility permissions.

import Foundation
import ApplicationServices // For AXIsProcessTrusted(), AXUIElementCreateSystemWide(), etc.
import AppKit // For NSRunningApplication

// debug() is assumed to be globally available from AXLogging.swift
// getParentProcessName() is assumed to be globally available from AXProcessUtils.swift
// kAXFocusedUIElementAttribute is assumed to be globally available from AXConstants.swift
// AXToolError is from AXError.swift

@MainActor
public func checkAccessibilityPermissions() throws { // Mark as throwing
    // Define the key string directly to avoid concurrency warnings with the global CFString.
    let kAXTrustedCheckOptionPromptString = "AXTrustedCheckOptionPrompt"
    let trustedOptions = [kAXTrustedCheckOptionPromptString: true] as CFDictionary

    if !AXIsProcessTrustedWithOptions(trustedOptions) { // Use options to prompt if possible
        // Even if prompt was shown, if it returns false, we are not authorized.
        let parentName = getParentProcessName()
        let errorDetail = parentName != nil ? "Hint: Grant accessibility permissions to '\(parentName!)'." : "Hint: Ensure the application running this tool has Accessibility permissions."
        
        // Distinguish between API disabled and not authorized if possible, though AXIsProcessTrustedWithOptions doesn't directly tell us.
        // For simplicity, we'll use .notAuthorized here. A more advanced check might be needed for .apiDisabled.
        // A common way to check if API is disabled is if AXUIElementCreateSystemWide returns nil, but that's too late here.
        
        debug("Accessibility check failed. Details: \(errorDetail)")
        // The fputs lines are now handled by how main.swift catches and prints AXToolError
        throw AXToolError.notAuthorized(errorDetail) 
    } else {
        debug("Accessibility permissions are granted.")
    }
} 