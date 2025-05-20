// AXPathUtils.swift - Utilities for parsing paths and navigating element hierarchies.

import Foundation
import ApplicationServices // For AXElement, AXUIElement and kAX...Attribute constants

// Assumes AXElement is defined (likely via AXSwift an extension or typealias)
// debug() is assumed to be globally available from AXLogging.swift
// axValue<T>() is assumed to be globally available from AXValueHelpers.swift
// kAXWindowRole, kAXWindowsAttribute, kAXChildrenAttribute, kAXRoleAttribute from AXConstants.swift

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
public func navigateToElement(from rootAXElement: AXElement, pathHint: [String]) -> AXElement? {
    var currentAXElement = rootAXElement
    for pathComponent in pathHint {
        guard let (role, index) = parsePathComponent(pathComponent) else {
            debug("Failed to parse path component: \(pathComponent)")
            return nil
        }
        
        if role.lowercased() == "window" || role.lowercased() == kAXWindowRole.lowercased() { 
            // Fetch as [AXUIElement] first, then map to [AXElement]
            guard let windowUIElements: [AXUIElement] = axValue(of: currentAXElement.underlyingElement, attr: kAXWindowsAttribute) else {
                debug("Window UI elements not found (or failed to cast to [AXUIElement]) for component: \(pathComponent). Current element: \(currentAXElement.briefDescription())")
                return nil
            }
            let windows: [AXElement] = windowUIElements.map { AXElement($0) }
            
            guard index < windows.count else {
                debug("Window not found for component: \(pathComponent) at index \(index). Available windows: \(windows.count). Current element: \(currentAXElement.briefDescription())")
                return nil
            }
            currentAXElement = windows[index]
        } else {
            guard let allChildrenUIElements: [AXUIElement] = axValue(of: currentAXElement.underlyingElement, attr: kAXChildrenAttribute) else {
                debug("Children UI elements not found for element \(currentAXElement.briefDescription()) while processing component: \(pathComponent)")
                return nil
            }
            let allChildren: [AXElement] = allChildrenUIElements.map { AXElement($0) }
            guard !allChildren.isEmpty else {
                 debug("No children found for element \(currentAXElement.briefDescription()) while processing component: \(pathComponent)")
                 return nil
            }
            
            let matchingChildren = allChildren.filter { 
                guard let childRole: String = axValue(of: $0.underlyingElement, attr: kAXRoleAttribute) else { return false }
                return childRole.lowercased() == role.lowercased() 
            }
            
            guard index < matchingChildren.count else {
                debug("Child not found for component: \(pathComponent) at index \(index). Role: \(role). For element \(currentAXElement.briefDescription()). Matching children count: \(matchingChildren.count)")
                return nil
            }
            currentAXElement = matchingChildren[index]
        }
    }
    return currentAXElement
} 