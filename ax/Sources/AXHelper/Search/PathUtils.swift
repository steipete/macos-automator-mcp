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
public func navigateToElement(from rootElement: Element, pathHint: [String]) -> Element? {
    var currentElement = rootElement
    for pathComponent in pathHint {
        guard let (role, index) = parsePathComponent(pathComponent) else {
            debug("Failed to parse path component: \(pathComponent)")
            return nil
        }
        
        if role.lowercased() == "window" || role.lowercased() == kAXWindowRole.lowercased() { 
            // Fetch as [AXUIElement] first, then map to [Element]
            guard let windowUIElements: [AXUIElement] = axValue(of: currentElement.underlyingElement, attr: kAXWindowsAttribute) else {
                debug("PathUtils: AXWindows attribute could not be fetched as [AXUIElement].")
                return nil
            }
            debug("PathUtils: Fetched \(windowUIElements.count) AXUIElements for AXWindows.")
            
            let windows: [Element] = windowUIElements.map { Element($0) }
            debug("PathUtils: Mapped to \(windows.count) Elements.")
            
            guard index < windows.count else {
                debug("PathUtils: Index \(index) is out of bounds for windows array (count: \(windows.count)). Component: \(pathComponent).")
                return nil
            }
            currentElement = windows[index]
        } else {
            // Similar explicit logging for children
            guard let allChildrenUIElements: [AXUIElement] = axValue(of: currentElement.underlyingElement, attr: kAXChildrenAttribute) else {
                debug("PathUtils: AXChildren attribute could not be fetched as [AXUIElement] for element \(currentElement.briefDescription()) while processing \(pathComponent).")
                return nil
            }
            debug("PathUtils: Fetched \(allChildrenUIElements.count) AXUIElements for AXChildren of \(currentElement.briefDescription()) for \(pathComponent).")

            let allChildren: [Element] = allChildrenUIElements.map { Element($0) }
            debug("PathUtils: Mapped to \(allChildren.count) Elements for children of \(currentElement.briefDescription()) for \(pathComponent).")

            guard !allChildren.isEmpty else {
                 debug("No children found for element \(currentElement.briefDescription()) while processing component: \(pathComponent)")
                 return nil
            }
            
            let matchingChildren = allChildren.filter { 
                guard let childRole: String = axValue(of: $0.underlyingElement, attr: kAXRoleAttribute) else { return false }
                return childRole.lowercased() == role.lowercased() 
            }
            
            guard index < matchingChildren.count else {
                debug("Child not found for component: \(pathComponent) at index \(index). Role: \(role). For element \(currentElement.briefDescription()). Matching children count: \(matchingChildren.count)")
                return nil
            }
            currentElement = matchingChildren[index]
        }
    }
    return currentElement
}