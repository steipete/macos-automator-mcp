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
    public func attribute<T>(_ attribute: Attribute<T>) -> T? {
        return axValue(of: self.underlyingElement, attr: attribute.rawValue) as T?
    }

    // Method to get the raw CFTypeRef? for an attribute
    // This is useful for functions like attributesMatch that do their own CFTypeID checking.
    // This also needs to be @MainActor as AXUIElementCopyAttributeValue should be on main thread.
    @MainActor
    public func rawAttributeValue(named attributeName: String) -> CFTypeRef? {
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
            // This is common and not necessarily an error to log loudly unless debugging.
            // debug("rawAttributeValue: Attribute \(attributeName) unsupported for element \(self.underlyingElement)")
        } else if error == .noValue {
            // Also common, attribute exists but has no value.
            // debug("rawAttributeValue: Attribute \(attributeName) has no value for element \(self.underlyingElement)")
        } else {
            // Other errors might be more significant
            // debug("rawAttributeValue: Error getting attribute \(attributeName) for element \(self.underlyingElement): \(error.rawValue)")
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
    public func isActionSupported(_ actionName: String) -> Bool {
        // First, try getting the array of supported action names
        if let actions: [String] = attribute(Attribute<[String]>.actionNames) {
            return actions.contains(actionName)
        }
        // Fallback for older systems or elements that might not return the array correctly,
        // but AXUIElementCopyActionNames might still work more broadly if AXActionNames is missing.
        // However, the direct attribute check is generally preferred with axValue's unwrapping.
        // For simplicity and consistency with our attribute<T> approach, we rely on kAXActionNamesAttribute.
        // If this proves insufficient, we can re-evaluate using AXUIElementCopyActionNames directly here.
        // Another way, more C-style, would be:
        /*
        var actionNamesCFArray: CFArray?
        let error = AXUIElementCopyActionNames(underlyingElement, &actionNamesCFArray)
        if error == .success, let actions = actionNamesCFArray as? [String] {
            return actions.contains(actionName)
        }
        */
        return false // If kAXActionNamesAttribute is not available or doesn't list it.
    }

    @MainActor
    @discardableResult
    public func performAction(_ actionName: Attribute<String>) throws -> Element {
        let error = AXUIElementPerformAction(self.underlyingElement, actionName.rawValue as CFString)
        if error != .success {
            let elementDescription = self.title ?? self.role ?? String(describing: self.underlyingElement)
            throw AccessibilityError.actionFailed("Action \(actionName.rawValue) failed on element \(elementDescription)", error)
        }
        return self
    }

    @MainActor
    @discardableResult
    public func performAction(_ actionName: String) throws -> Element {
        let error = AXUIElementPerformAction(self.underlyingElement, actionName as CFString)
        if error != .success {
            let elementDescription = self.title ?? self.role ?? String(describing: self.underlyingElement)
            throw AccessibilityError.actionFailed("Action \(actionName) failed on element \(elementDescription)", error)
        }
        return self
    }

    // MARK: - Parameterized Attributes

    @MainActor
    public func parameterizedAttribute<T>(_ attribute: Attribute<T>, forParameter parameter: Any) -> T? {
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
            debug("parameterizedAttribute: Unsupported parameter type \(type(of: parameter))")
            return nil
        }

        guard let actualCFParameter = cfParameter else {
            debug("parameterizedAttribute: Failed to convert parameter to CFTypeRef.")
            return nil
        }

        var value: CFTypeRef?
        let error = AXUIElementCopyParameterizedAttributeValue(underlyingElement, attribute.rawValue as CFString, actualCFParameter, &value)

        if error != .success {
            // Silently return nil, or consider throwing an error
            // debug("parameterizedAttribute: Error \(error.rawValue) getting attribute \(attributeName)")
            return nil
        }

        guard let resultCFValue = value else { return nil }
        
        // Use axValue's unwrapping and casting logic if possible, by temporarily creating an element and attribute
        // This is a bit of a conceptual stretch, as axValue is designed for direct attributes.
        // A more direct unwrap using ValueUnwrapper might be cleaner here.
        let unwrappedValue = ValueUnwrapper.unwrap(resultCFValue)
        
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
        debug("parameterizedAttribute: Fallback cast attempt for attribute '\(attribute.rawValue)' to type \(T.self) FAILED. Unwrapped value was \(type(of: finalValue)): \(finalValue)")
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
    public var computedName: String? {
        if let title = self.title, !title.isEmpty, title != kAXNotAvailableString { return title }
        if let value: String = self.attribute(Attribute<String>(kAXValueAttribute)), !value.isEmpty, value != kAXNotAvailableString { return value }
        if let desc = self.description, !desc.isEmpty, desc != kAXNotAvailableString { return desc }
        if let help: String = self.attribute(Attribute<String>(kAXHelpAttribute)), !help.isEmpty, help != kAXNotAvailableString { return help }
        if let phValue: String = self.attribute(Attribute<String>(kAXPlaceholderValueAttribute)), !phValue.isEmpty, phValue != kAXNotAvailableString { return phValue }
        if let roleDesc: String = self.attribute(Attribute<String>(kAXRoleDescriptionAttribute)), !roleDesc.isEmpty, roleDesc != kAXNotAvailableString {
            return "\(roleDesc) (\(self.role ?? "Element"))"
        }
        return nil
    }

    // MARK: - Path and Hierarchy
}

// Convenience factory for the application element - already @MainActor
@MainActor
public func applicationElement(for bundleIdOrName: String) -> Element? {
    guard let pid = pid(forAppIdentifier: bundleIdOrName) else {
        debug("Failed to find PID for app: \(bundleIdOrName) in applicationElement (Element)")
        return nil
    }
    let appElement = AXUIElementCreateApplication(pid)
    // TODO: Check if appElement is nil or somehow invalid after creation, though AXUIElementCreateApplication doesn't directly return an optional or throw errors easily checkable here.
    // For now, assume valid if PID was found.
    return Element(appElement)
}

// Convenience factory for the system-wide element - already @MainActor
@MainActor
public func systemWideElement() -> Element {
    return Element(AXUIElementCreateSystemWide())
}

// Extension to generate a descriptive path string
extension Element {
    @MainActor
    func generatePathString(upTo ancestor: Element? = nil) -> String {
        var pathComponents: [String] = []
        var currentElement: Element? = self

        var depth = 0 // Safety break for very deep or circular hierarchies
        let maxDepth = 25

        while let element = currentElement, depth < maxDepth {
            let briefDesc = element.briefDescription(option: .default) // Use .default for concise path components
            pathComponents.append(briefDesc)

            if let ancestor = ancestor, element == ancestor {
                break // Reached the specified ancestor
            }

            // Stop if we reach the application level and no specific ancestor was given, 
            // or if it's a window and the parent is the app (to avoid App -> App paths)
            let role = element.role
            if role == kAXApplicationRole || (role == kAXWindowRole && element.parent?.role == kAXApplicationRole && ancestor == nil) {
                break 
            }
            
            currentElement = element.parent
            depth += 1
            if currentElement == nil && role != kAXApplicationRole { // Should ideally not happen if parent is correct before app
                 pathComponents.append("< Orphaned >") // Indicate unexpected break
                 break
            }
        }
        if depth == maxDepth {
             pathComponents.append("<...path_too_deep...>")
        }

        return pathComponents.reversed().joined(separator: " -> ")
    }
}