// AXElement.swift - Wrapper for AXUIElement for a more Swift-idiomatic interface

import Foundation
import ApplicationServices // For AXUIElement and other C APIs
// We might need to import AXValueHelpers or other local modules later

// AXElement struct is NOT @MainActor. Isolation is applied to members that need it.
public struct AXElement: Equatable, Hashable {
    public let underlyingElement: AXUIElement

    public init(_ element: AXUIElement) {
        self.underlyingElement = element
    }

    // Implement Equatable - no longer needs nonisolated as struct is not @MainActor
    public static func == (lhs: AXElement, rhs: AXElement) -> Bool {
        return CFEqual(lhs.underlyingElement, rhs.underlyingElement)
    }

    // Implement Hashable - no longer needs nonisolated
    public func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(underlyingElement))
    }

    // Generic method to get an attribute's value (converted to Swift type T)
    @MainActor
    public func attribute<T>(_ attributeName: String) -> T? {
        return axValue(of: self.underlyingElement, attr: attributeName)
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

    // MARK: - Common Attribute Getters
    // Marked @MainActor because they call attribute(), which is @MainActor.
    @MainActor public var role: String? { attribute(kAXRoleAttribute) }
    @MainActor public var subrole: String? { attribute(kAXSubroleAttribute) }
    @MainActor public var title: String? { attribute(kAXTitleAttribute) }
    @MainActor public var axDescription: String? { attribute(kAXDescriptionAttribute) }
    @MainActor public var isEnabled: Bool? { attribute(kAXEnabledAttribute) }
    // value can be tricky as it can be many types. Defaulting to String? for now, or Any? if T can be inferred for Any
    // For now, let's make it specific if we know the expected type, or use the generic attribute<T>() directly.
    // Example: public var stringValue: String? { attribute(kAXValueAttribute) }
    // Example: public var numberValue: NSNumber? { attribute(kAXValueAttribute) }

    // MARK: - Hierarchy and Relationship Getters
    // Marked @MainActor because they call attribute(), which is @MainActor.
    @MainActor public var parent: AXElement? {
        guard let parentElement: AXUIElement = attribute(kAXParentAttribute) else { return nil }
        return AXElement(parentElement)
    }

    @MainActor public var children: [AXElement]? {
        var collectedChildren: [AXElement] = []
        var uniqueChildrenSet = Set<AXElement>()

        // Primary children attribute
        if let directChildrenUI: [AXUIElement] = attribute(kAXChildrenAttribute) {
            for childUI in directChildrenUI {
                let childAX = AXElement(childUI)
                if !uniqueChildrenSet.contains(childAX) {
                    collectedChildren.append(childAX)
                    uniqueChildrenSet.insert(childAX)
                }
            }
        }

        // Alternative children attributes, especially for web areas or complex views
        // This logic is similar to what was in AXSearch and AXAttributeHelpers
        // Check these if primary children are empty or if we want to be exhaustive.
        // For now, let's always check them and add unique ones.
        let alternativeAttributes: [String] = [
            kAXVisibleChildrenAttribute, "AXWebAreaChildren", "AXHTMLContent",
            "AXARIADOMChildren", "AXDOMChildren", "AXApplicationNavigation",
            "AXApplicationElements", "AXContents", "AXBodyArea", "AXDocumentContent",
            "AXWebPageContent", "AXSplitGroupContents", "AXLayoutAreaChildren",
            "AXGroupChildren", kAXSelectedChildrenAttribute, kAXRowsAttribute, kAXColumnsAttribute,
            kAXTabsAttribute // Tabs can also be considered children in some contexts
        ]

        for attrName in alternativeAttributes {
            if let altChildrenUI: [AXUIElement] = attribute(attrName) {
                for childUI in altChildrenUI {
                    let childAX = AXElement(childUI)
                    if !uniqueChildrenSet.contains(childAX) {
                        collectedChildren.append(childAX)
                        uniqueChildrenSet.insert(childAX)
                    }
                }
            }
        }
        
        // For application elements, kAXWindowsAttribute is also very important
        if self.role == kAXApplicationRole {
            if let windowElementsUI: [AXUIElement] = attribute(kAXWindowsAttribute) {
                 for childUI in windowElementsUI {
                    let childAX = AXElement(childUI)
                    if !uniqueChildrenSet.contains(childAX) {
                        collectedChildren.append(childAX)
                        uniqueChildrenSet.insert(childAX)
                    }
                }
            }
        }

        return collectedChildren.isEmpty ? nil : collectedChildren
    }

    @MainActor public var windows: [AXElement]? {
        guard let windowElements: [AXUIElement] = attribute(kAXWindowsAttribute) else { return nil }
        return windowElements.map { AXElement($0) }
    }

    @MainActor public var mainWindow: AXElement? {
        guard let windowElement: AXUIElement = attribute(kAXMainWindowAttribute) else { return nil }
        return AXElement(windowElement)
    }

    @MainActor public var focusedWindow: AXElement? {
        guard let windowElement: AXUIElement = attribute(kAXFocusedWindowAttribute) else { return nil }
        return AXElement(windowElement)
    }

    @MainActor public var focusedElement: AXElement? {
        guard let element: AXUIElement = attribute(kAXFocusedUIElementAttribute) else { return nil }
        return AXElement(element)
    }

    // MARK: - Actions

    @MainActor
    public var supportedActions: [String]? {
        return attribute(kAXActionNamesAttribute)
    }

    @MainActor
    public func isActionSupported(_ actionName: String) -> Bool {
        // First, try getting the array of supported action names
        if let actions: [String] = attribute(kAXActionNamesAttribute) {
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
    public func performAction(_ actionName: String) throws {
        let error = AXUIElementPerformAction(underlyingElement, actionName as CFString)
        if error != .success {
            // It would be good to have a more specific error here from AXErrorString
            throw AXErrorString.actionFailed(error) // Ensure AXErrorString.actionFailed exists and takes AXError
        }
    }

    // MARK: - Parameterized Attributes

    @MainActor
    public func parameterizedAttribute<T>(_ attributeName: String, forParameter parameter: Any) -> T? {
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
        let error = AXUIElementCopyParameterizedAttributeValue(underlyingElement, attributeName as CFString, actualCFParameter, &value)

        if error != .success {
            // Silently return nil, or consider throwing an error
            // debug("parameterizedAttribute: Error \(error.rawValue) getting attribute \(attributeName)")
            return nil
        }

        guard let resultCFValue = value else { return nil }
        
        // Use axValue's unwrapping and casting logic if possible, by temporarily creating an element and attribute
        // This is a bit of a conceptual stretch, as axValue is designed for direct attributes.
        // A more direct unwrap using AXValueUnwrapper might be cleaner here.
        let unwrappedValue = AXValueUnwrapper.unwrap(resultCFValue)
        
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
        debug("parameterizedAttribute: Fallback cast attempt for attribute '\(attributeName)' to type \(T.self) FAILED. Unwrapped value was \(type(of: finalValue)): \(finalValue)")
        return nil
    }
}

// Convenience factory for the application element - already @MainActor
@MainActor
public func applicationElement(for bundleIdOrName: String) -> AXElement? {
    guard let pid = pid(forAppIdentifier: bundleIdOrName) else {
        debug("Failed to find PID for app: \(bundleIdOrName) in applicationElement (AXElement)")
        return nil
    }
    let appElement = AXUIElementCreateApplication(pid)
    return AXElement(appElement)
}

// Convenience factory for the system-wide element - already @MainActor
@MainActor
public func systemWideElement() -> AXElement {
    return AXElement(AXUIElementCreateSystemWide())
} 