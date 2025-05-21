// Element.swift - Wrapper for AXUIElement for a more Swift-idiomatic interface

import Foundation
import ApplicationServices // For AXUIElement and other C APIs
// We might need to import ValueHelpers or other local modules later

// Element struct is NOT @MainActor. Isolation is applied to members that need it.
public struct Element: Equatable, Hashable {
    public let underlyingElement: AXUIElement

    public init(_ element: AXUIElement) {
        self.underlyingElement = element
    }

    // Implement Equatable - no longer needs nonisolated as struct is not @MainActor
    public static func == (lhs: Element, rhs: Element) -> Bool {
        return CFEqual(lhs.underlyingElement, rhs.underlyingElement)
    }

    // Implement Hashable - no longer needs nonisolated
    public func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(underlyingElement))
    }

    // Generic method to get an attribute's value (converted to Swift type T)
    @MainActor
    public func attribute<T>(_ attribute: Attribute<T>, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> T? {
        // axValue is from ValueHelpers.swift and now expects logging parameters
        return axValue(of: self.underlyingElement, attr: attribute.rawValue, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) as T?
    }

    // Method to get the raw CFTypeRef? for an attribute
    // This is useful for functions like attributesMatch that do their own CFTypeID checking.
    // This also needs to be @MainActor as AXUIElementCopyAttributeValue should be on main thread.
    @MainActor
    public func rawAttributeValue(named attributeName: String, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> CFTypeRef? {
        func dLog(_ message: String) {
            if isDebugLoggingEnabled {
                currentDebugLogs.append(message)
            }
        }
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(self.underlyingElement, attributeName as CFString, &value)
        if error == .success {
            return value // Caller is responsible for CFRelease if it's a new object they own.
                      // For many get operations, this is a copy-get rule, but some are direct gets.
                      // Since we just return it, the caller should be aware or this function should manage it.
                      // Given AXSwift patterns, often the raw value isn't directly exposed like this, 
                      // or it is clearly documented. For now, let's assume this is for internal use by attributesMatch
                      // which previously used copyAttributeValue which likely returned a +1 ref count object.
        } else if error == .attributeUnsupported {
            dLog("rawAttributeValue: Attribute \(attributeName) unsupported for element \(self.underlyingElement)")
        } else if error == .noValue {
            dLog("rawAttributeValue: Attribute \(attributeName) has no value for element \(self.underlyingElement)")
        } else {
            dLog("rawAttributeValue: Error getting attribute \(attributeName) for element \(self.underlyingElement): \(error.rawValue)")
        }
        return nil // Return nil if not success or if value was nil (though success should mean value is populated)
    }

    // MARK: - Common Attribute Getters (MOVED to Element+Properties.swift)
    // MARK: - Status Properties (MOVED to Element+Properties.swift)
    // MARK: - Hierarchy and Relationship Getters (Simpler ones MOVED to Element+Properties.swift)
    // MARK: - Action-related (supportedActions MOVED to Element+Properties.swift)

    // Remaining properties and methods will stay here for now
    // (e.g., children, isActionSupported, performAction, parameterizedAttribute, briefDescription, generatePathString, static factories)

    // MOVED to Element+Hierarchy.swift
    // @MainActor public var children: [Element]? { ... }

    // MARK: - Actions (supportedActions moved, other action methods remain)

    @MainActor
    public func isActionSupported(_ actionName: String, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> Bool {
        if let actions: [String] = attribute(Attribute<[String]>.actionNames, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
            return actions.contains(actionName)
        }
        return false
    }

    @MainActor
    @discardableResult
    public func performAction(_ actionName: Attribute<String>, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) throws -> Element {
        func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
        let error = AXUIElementPerformAction(self.underlyingElement, actionName.rawValue as CFString)
        if error != .success {
            // Now call the refactored briefDescription, passing the logs along.
            let desc = self.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            dLog("Action \(actionName.rawValue) failed on element \(desc). Error: \(error.rawValue)")
            throw AccessibilityError.actionFailed("Action \(actionName.rawValue) failed on element \(desc)", error)
        }
        return self
    }

    @MainActor
    @discardableResult
    public func performAction(_ actionName: String, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) throws -> Element {
        func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
        let error = AXUIElementPerformAction(self.underlyingElement, actionName as CFString)
        if error != .success {
            // Now call the refactored briefDescription, passing the logs along.
            let desc = self.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            dLog("Action \(actionName) failed on element \(desc). Error: \(error.rawValue)")
            throw AccessibilityError.actionFailed("Action \(actionName) failed on element \(desc)", error)
        }
        return self
    }

    // MARK: - Parameterized Attributes

    @MainActor
    public func parameterizedAttribute<T>(_ attribute: Attribute<T>, forParameter parameter: Any, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> T? {
        func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
        var cfParameter: CFTypeRef?

        // Convert Swift parameter to CFTypeRef for the API
        if var range = parameter as? CFRange {
            cfParameter = AXValueCreate(.cfRange, &range)
        } else if let string = parameter as? String {
            cfParameter = string as CFString
        } else if let number = parameter as? NSNumber {
            cfParameter = number
        } else if CFGetTypeID(parameter as CFTypeRef) != 0 { // Check if it's already a CFTypeRef-compatible type
            cfParameter = (parameter as CFTypeRef)
        } else {
            dLog("parameterizedAttribute: Unsupported parameter type \(type(of: parameter))")
            return nil
        }

        guard let actualCFParameter = cfParameter else {
            dLog("parameterizedAttribute: Failed to convert parameter to CFTypeRef.")
            return nil
        }

        var value: CFTypeRef?
        let error = AXUIElementCopyParameterizedAttributeValue(underlyingElement, attribute.rawValue as CFString, actualCFParameter, &value)

        if error != .success {
            dLog("parameterizedAttribute: Error \(error.rawValue) getting attribute \(attribute.rawValue)")
            return nil
        }

        guard let resultCFValue = value else { return nil }
        
        // Use axValue's unwrapping and casting logic if possible, by temporarily creating an element and attribute
        // This is a bit of a conceptual stretch, as axValue is designed for direct attributes.
        // A more direct unwrap using ValueUnwrapper might be cleaner here.
        let unwrappedValue = ValueUnwrapper.unwrap(resultCFValue, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        
        guard let finalValue = unwrappedValue else { return nil }

        // Perform type casting similar to axValue
        if T.self == String.self {
            if let str = finalValue as? String { return str as? T }
            else if let attrStr = finalValue as? NSAttributedString { return attrStr.string as? T }
            return nil
        }
        if let castedValue = finalValue as? T {
            return castedValue
        }
        dLog("parameterizedAttribute: Fallback cast attempt for attribute '\(attribute.rawValue)' to type \(T.self) FAILED. Unwrapped value was \(type(of: finalValue)): \(finalValue)")
        return nil
    }

    // MOVED to Element+Hierarchy.swift
    // @MainActor
    // public func generatePathString() -> String { ... }

    // MARK: - Attribute Accessors (Raw and Typed)

    // ... existing attribute accessors ...

    // MARK: - Computed Properties for Common Attributes & Heuristics

    // ... existing properties like role, title, isEnabled ...

    /// A computed name for the element, derived from common attributes like title, value, description, etc.
    /// This provides a general-purpose, human-readable name.
    @MainActor
    // Convert from a computed property to a method to accept logging parameters
    public func computedName(isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> String? { 
        // Now uses the passed-in logging parameters for its internal calls
        if let titleStr = self.title(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs), !titleStr.isEmpty, titleStr != kAXNotAvailableString { return titleStr }
        
        if let valueStr: String = self.value(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) as? String, !valueStr.isEmpty, valueStr != kAXNotAvailableString { return valueStr }
        
        if let descStr = self.description(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs), !descStr.isEmpty, descStr != kAXNotAvailableString { return descStr }
        
        if let helpStr: String = self.attribute(Attribute<String>(kAXHelpAttribute), isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs), !helpStr.isEmpty, helpStr != kAXNotAvailableString { return helpStr }
        if let phValueStr: String = self.attribute(Attribute<String>(kAXPlaceholderValueAttribute), isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs), !phValueStr.isEmpty, phValueStr != kAXNotAvailableString { return phValueStr }
        
        let roleNameStr: String = self.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) ?? "Element"
        
        if let roleDescStr: String = self.roleDescription(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs), !roleDescStr.isEmpty, roleDescStr != kAXNotAvailableString {
            return "\(roleDescStr) (\(roleNameStr))"
        }
        return nil
    }

    // MARK: - Path and Hierarchy
}

// Convenience factory for the application element - already @MainActor
@MainActor
public func applicationElement(for bundleIdOrName: String, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> Element? {
    func dLog(_ message: String) {
        if isDebugLoggingEnabled {
            currentDebugLogs.append(message)
        }
    }
    // Now call pid() with logging parameters
    guard let pid = pid(forAppIdentifier: bundleIdOrName, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
        // dLog for "Failed to find PID..." is now handled inside pid() itself or if it returns nil here, we can log the higher level failure.
        // The message below is slightly redundant if pid() logs its own failure, but can be useful.
        dLog("applicationElement: Failed to obtain PID for '\(bundleIdOrName)'. Check previous logs from pid().")
        return nil
    }
    let appElement = AXUIElementCreateApplication(pid)
    return Element(appElement)
}

// Convenience factory for the system-wide element - already @MainActor
@MainActor
public func systemWideElement(isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> Element {
    // This function doesn't do much logging itself, but consistent signature is good.
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    dLog("Creating system-wide element.")
    return Element(AXUIElementCreateSystemWide())
}

// Extension to generate a descriptive path string
extension Element {
    @MainActor
    // Update signature to include logging parameters
    public func generatePathString(upTo ancestor: Element? = nil, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> String {
        func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
        var pathComponents: [String] = []
        var currentElement: Element? = self

        var depth = 0 // Safety break for very deep or circular hierarchies
        let maxDepth = 25
        var tempLogs: [String] = [] // Temporary logs for calls within the loop

        dLog("generatePathString started for element: \(self.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)) upTo: \(ancestor?.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) ?? "nil")")

        while let element = currentElement, depth < maxDepth {
            tempLogs.removeAll() // Clear for each iteration
            let briefDesc = element.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
            pathComponents.append(briefDesc)
            currentDebugLogs.append(contentsOf: tempLogs) // Append logs from briefDescription

            if let ancestor = ancestor, element == ancestor {
                dLog("generatePathString: Reached specified ancestor: \(briefDesc)")
                break // Reached the specified ancestor
            }

            // Check role to prevent going above application or a window if its parent is the app
            tempLogs.removeAll()
            let role = element.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
            currentDebugLogs.append(contentsOf: tempLogs)
            
            tempLogs.removeAll()
            let parentElement = element.parent(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
            currentDebugLogs.append(contentsOf: tempLogs)
            
            tempLogs.removeAll()
            let parentRole = parentElement?.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
            currentDebugLogs.append(contentsOf: tempLogs)

            if role == kAXApplicationRole || (role == kAXWindowRole && parentRole == kAXApplicationRole && ancestor == nil) {
                dLog("generatePathString: Stopping at \(role == kAXApplicationRole ? "Application" : "Window under App"): \(briefDesc)")
                break 
            }
            
            currentElement = parentElement
            depth += 1
            if currentElement == nil && role != kAXApplicationRole { 
                 let orphanLog = "< Orphaned element path component: \(briefDesc) (role: \(role ?? "nil")) >"
                 dLog("generatePathString: Unexpected orphan: \(orphanLog)")
                 pathComponents.append(orphanLog) 
                 break
            }
        }
        if depth >= maxDepth {
            dLog("generatePathString: Reached max depth (\(maxDepth)). Path might be truncated.")
            pathComponents.append("<...max_depth_reached...>")
        }

        let finalPath = pathComponents.reversed().joined(separator: " -> ")
        dLog("generatePathString finished. Path: \(finalPath)")
        return finalPath
    }

    // New function to return path components as an array
    @MainActor
    public func generatePathArray(upTo ancestor: Element? = nil, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> [String] {
        func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
        var pathComponents: [String] = []
        var currentElement: Element? = self

        var depth = 0
        let maxDepth = 25 
        var tempLogs: [String] = []

        dLog("generatePathArray started for element: \(self.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)) upTo: \(ancestor?.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) ?? "nil")")
        currentDebugLogs.append(contentsOf: tempLogs); tempLogs.removeAll()

        while let element = currentElement, depth < maxDepth {
            tempLogs.removeAll()
            let briefDesc = element.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
            pathComponents.append(briefDesc)
            currentDebugLogs.append(contentsOf: tempLogs); tempLogs.removeAll()

            if let ancestor = ancestor, element == ancestor {
                dLog("generatePathArray: Reached specified ancestor: \(briefDesc)")
                break
            }

            tempLogs.removeAll()
            let role = element.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
            currentDebugLogs.append(contentsOf: tempLogs); tempLogs.removeAll()
            
            tempLogs.removeAll()
            let parentElement = element.parent(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
            currentDebugLogs.append(contentsOf: tempLogs); tempLogs.removeAll()
            
            tempLogs.removeAll()
            let parentRole = parentElement?.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
            currentDebugLogs.append(contentsOf: tempLogs); tempLogs.removeAll()

            if role == kAXApplicationRole || (role == kAXWindowRole && parentRole == kAXApplicationRole && ancestor == nil) {
                dLog("generatePathArray: Stopping at \(role == kAXApplicationRole ? "Application" : "Window under App"): \(briefDesc)")
                break 
            }
            
            currentElement = parentElement
            depth += 1
            if currentElement == nil && role != kAXApplicationRole { 
                 let orphanLog = "< Orphaned element path component: \(briefDesc) (role: \(role ?? "nil")) >"
                 dLog("generatePathArray: Unexpected orphan: \(orphanLog)")
                 pathComponents.append(orphanLog) 
                 break
            }
        }
        if depth >= maxDepth {
            dLog("generatePathArray: Reached max depth (\(maxDepth)). Path might be truncated.")
            pathComponents.append("<...max_depth_reached...>")
        }

        let reversedPathComponents = Array(pathComponents.reversed())
        dLog("generatePathArray finished. Path components: \(reversedPathComponents.joined(separator: "/"))") // Log for debugging
        return reversedPathComponents
    }
}