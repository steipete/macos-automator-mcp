// PathUtils.swift - Utilities for parsing paths and navigating element hierarchies.

import Foundation
import ApplicationServices // For Element, AXUIElement and kAX...Attribute constants

// Assumes Element is defined (likely via AXSwift an extension or typealias)
// debug() is assumed to be globally available from Logging.swift
// axValue<T>() is assumed to be globally available from ValueHelpers.swift
// kAXWindowRole, kAXWindowsAttribute, kAXChildrenAttribute, kAXRoleAttribute from AccessibilityConstants.swift

public func parsePathComponent(_ path: String) -> (role: String, index: Int)? {
    let pattern = #"(\w+)\[(\d+)\]"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(path.startIndex..<path.endIndex, in: path)
    guard let match = regex.firstMatch(in: path, range: range) else { return nil }
    let role = (path as NSString).substring(with: match.range(at: 1))
    guard let index = Int((path as NSString).substring(with: match.range(at: 2))) else { return nil }
    return (role: role, index: index - 1) // Return 0-based index
}

@MainActor
public func navigateToElement(from rootElement: Element, pathHint: [String], isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> Element? {
    func dLog(_ message: String) {
        if isDebugLoggingEnabled {
            currentDebugLogs.append(message)
        }
    }
    var currentElement = rootElement
    for pathComponent in pathHint {
        guard let (role, index) = parsePathComponent(pathComponent) else {
            dLog("Failed to parse path component: \(pathComponent)")
            return nil
        }
        
        var tempBriefDescLogs: [String] = [] // Placeholder for briefDescription logs

        if role.lowercased() == "window" || role.lowercased() == kAXWindowRole.lowercased() { 
            guard let windowUIElements: [AXUIElement] = axValue(of: currentElement.underlyingElement, attr: kAXWindowsAttribute, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
                dLog("PathUtils: AXWindows attribute could not be fetched as [AXUIElement].")
                return nil
            }
            dLog("PathUtils: Fetched \(windowUIElements.count) AXUIElements for AXWindows.")
            
            let windows: [Element] = windowUIElements.map { Element($0) }
            dLog("PathUtils: Mapped to \(windows.count) Elements.")
            
            guard index < windows.count else {
                dLog("PathUtils: Index \(index) is out of bounds for windows array (count: \(windows.count)). Component: \(pathComponent).")
                return nil
            }
            currentElement = windows[index]
        } else {
            let currentElementDesc = currentElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempBriefDescLogs) // Placeholder call
            guard let allChildrenUIElements: [AXUIElement] = axValue(of: currentElement.underlyingElement, attr: kAXChildrenAttribute, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
                dLog("PathUtils: AXChildren attribute could not be fetched as [AXUIElement] for element \(currentElementDesc) while processing \(pathComponent).")
                return nil
            }
            dLog("PathUtils: Fetched \(allChildrenUIElements.count) AXUIElements for AXChildren of \(currentElementDesc) for \(pathComponent).")

            let allChildren: [Element] = allChildrenUIElements.map { Element($0) }
            dLog("PathUtils: Mapped to \(allChildren.count) Elements for children of \(currentElementDesc) for \(pathComponent).")

            guard !allChildren.isEmpty else {
                 dLog("No children found for element \(currentElementDesc) while processing component: \(pathComponent)")
                 return nil
            }
            
            let matchingChildren = allChildren.filter { 
                guard let childRole: String = axValue(of: $0.underlyingElement, attr: kAXRoleAttribute, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else { return false }
                return childRole.lowercased() == role.lowercased() 
            }
            
            guard index < matchingChildren.count else {
                dLog("Child not found for component: \(pathComponent) at index \(index). Role: \(role). For element \(currentElementDesc). Matching children count: \(matchingChildren.count)")
                return nil
            }
            currentElement = matchingChildren[index]
        }
    }
    return currentElement
}