// AXUtils.swift - Contains utility functions for accessibility interactions

import Foundation
import ApplicationServices
import AppKit // For NSRunningApplication, NSWorkspace
import CoreGraphics // For CGPoint, CGSize etc.

// Constants like kAXWindowsAttribute are assumed to be globally available from AXConstants.swift
// debug() is assumed to be globally available from AXLogging.swift
// axValue<T>() is now in AXValueHelpers.swift

public enum AXErrorString: Error, CustomStringConvertible {
    case notAuthorised(AXError)
    case elementNotFound
    case actionFailed(AXError)
    case invalidCommand
    case genericError(String)
    case typeMismatch(expected: String, actual: String)

    public var description: String {
        switch self {
        case .notAuthorised(let e): return "AX authorisation failed: \(e)"
        case .elementNotFound:      return "No element matches the locator criteria or path."
        case .actionFailed(let e):  return "Action failed with AXError: \(e)"
        case .invalidCommand:       return "Invalid command specified."
        case .genericError(let msg): return msg
        case .typeMismatch(let expected, let actual): return "Type mismatch: Expected \(expected), got \(actual)."
        }
    }
}

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

public func parsePathComponent(_ path: String) -> (role: String, index: Int)? {
    let pattern = #"(\w+)\[(\d+)\]"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(path.startIndex..<path.endIndex, in: path)
    guard let match = regex.firstMatch(in: path, range: range) else { return nil }
    let role = (path as NSString).substring(with: match.range(at: 1))
    guard let index = Int((path as NSString).substring(with: match.range(at: 2))) else { return nil }
    return (role: role, index: index - 1)
}

@MainActor
public func navigateToElement(from rootAXElement: AXElement, pathHint: [String]) -> AXElement? {
    var currentAXElement = rootAXElement
    for pathComponent in pathHint {
        guard let (role, index) = parsePathComponent(pathComponent) else { return nil }
        if role.lowercased() == "window" {
            guard let windows = currentAXElement.windows, index < windows.count else { return nil }
            currentAXElement = windows[index]
        } else {
            guard let allChildren = currentAXElement.children else { return nil }
            let matchingChildren = allChildren.filter { $0.role?.lowercased() == role.lowercased() }
            guard index < matchingChildren.count else { return nil }
            currentAXElement = matchingChildren[index]
        }
    }
    return currentAXElement
}

@MainActor
public func extractTextContent(axElement: AXElement) -> String {
    var texts: [String] = []
    let textualAttributes = [
        kAXValueAttribute, kAXTitleAttribute, kAXDescriptionAttribute, kAXHelpAttribute,
        kAXPlaceholderValueAttribute, kAXLabelValueAttribute, kAXRoleDescriptionAttribute,
    ]
    for attrName in textualAttributes {
        if let strValue: String = axElement.attribute(attrName), !strValue.isEmpty, strValue != "Not available" {
            texts.append(strValue)
        }
    }
    var uniqueTexts: [String] = []
    var seenTexts = Set<String>()
    for text in texts {
        if !seenTexts.contains(text) {
            uniqueTexts.append(text)
            seenTexts.insert(text)
        }
    }
    return uniqueTexts.joined(separator: "\n")
}

@MainActor
public func checkAccessibilityPermissions() {
    if !AXIsProcessTrusted() {
        fputs("ERROR: Accessibility permissions are not granted.\n", stderr)
        fputs("Please enable in System Settings > Privacy & Security > Accessibility.\n", stderr)
        if let parentName = getParentProcessName() {
            fputs("Hint: Grant accessibility permissions to '\(parentName)'.\n", stderr)
        }
        // Attempting to get focused element to potentially trigger system dialog if run from Terminal directly
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        _ = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        exit(1)
    } else {
        debug("Accessibility permissions are granted.")
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