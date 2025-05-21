import Foundation
import ApplicationServices
import CoreGraphics // For CGPoint, CGSize etc.

// debug() is assumed to be globally available from Logging.swift
// Constants like kAXPositionAttribute are assumed to be globally available from AccessibilityConstants.swift

// ValueUnwrapper has been moved to its own file: ValueUnwrapper.swift

// MARK: - Attribute Value Accessors

@MainActor
public func copyAttributeValue(element: AXUIElement, attribute: String) -> CFTypeRef? {
    var value: CFTypeRef?
    // This function is low-level, avoid extensive logging here unless specifically for this function.
    // Logging for attribute success/failure is better handled by the caller (axValue).
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
        return nil
    }
    return value
}

@MainActor
public func axValue<T>(of element: AXUIElement, attr: String, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> T? {
    func dLog(_ message: String) {
        if isDebugLoggingEnabled {
            currentDebugLogs.append(message)
        }
    }

    // copyAttributeValue doesn't log, so no need to pass log params to it.
    let rawCFValue = copyAttributeValue(element: element, attribute: attr)
    
    // ValueUnwrapper.unwrap also needs to be audited for logging. For now, assume it doesn't log or its logs are separate.
    let unwrappedValue = ValueUnwrapper.unwrap(rawCFValue, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)

    guard let value = unwrappedValue else { 
        // It's common for attributes to be missing or have no value. 
        // Only log if in debug mode and something was expected but not found, 
        // or if rawCFValue was non-nil but unwrapped to nil (which ValueUnwrapper might handle).
        // For now, let's not log here, as Element.swift's rawAttributeValue also has checks.
        return nil 
    }

    if T.self == String.self {
        if let str = value as? String { return str as? T }
        else if let attrStr = value as? NSAttributedString { return attrStr.string as? T }
        dLog("axValue: Expected String for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }
    
    if T.self == Bool.self {
        if let boolVal = value as? Bool { return boolVal as? T }
        else if let numVal = value as? NSNumber { return numVal.boolValue as? T }
        dLog("axValue: Expected Bool for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }
    
    if T.self == Int.self {
        if let intVal = value as? Int { return intVal as? T }
        else if let numVal = value as? NSNumber { return numVal.intValue as? T }
        dLog("axValue: Expected Int for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }

    if T.self == Double.self {
        if let doubleVal = value as? Double { return doubleVal as? T }
        else if let numVal = value as? NSNumber { return numVal.doubleValue as? T }
        dLog("axValue: Expected Double for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }
    
    if T.self == [AXUIElement].self {
        if let anyArray = value as? [Any?] {
            let result = anyArray.compactMap { item -> AXUIElement? in
                guard let cfItem = item else { return nil } 
                // Ensure correct comparison for CFTypeRef type ID
                if CFGetTypeID(cfItem as CFTypeRef) == AXUIElementGetTypeID() { // Directly use AXUIElementGetTypeID()
                    return (cfItem as! AXUIElement)
                }
                return nil
            }
            return result as? T
        }
        dLog("axValue: Expected [AXUIElement] for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }

    if T.self == [Element].self { // Assuming Element is a struct wrapping AXUIElement
        if let anyArray = value as? [Any?] {
            let result = anyArray.compactMap { item -> Element? in
                guard let cfItem = item else { return nil } 
                if CFGetTypeID(cfItem as CFTypeRef) == AXUIElementGetTypeID() { // Check underlying type
                    return Element(cfItem as! AXUIElement)
                }
                return nil
            }
            return result as? T
        }
        dLog("axValue: Expected [Element] for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }

    if T.self == [String].self {
        if let stringArray = value as? [Any?] { 
            let result = stringArray.compactMap { $0 as? String }
            // Ensure all elements were successfully cast, otherwise it's not a homogenous [String] array
            if result.count == stringArray.count { return result as? T }
        }
        dLog("axValue: Expected [String] for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }

    // CGPoint and CGSize are expected to be directly unwrapped by ValueUnwrapper to these types.
    if T.self == CGPoint.self {
        if let pointVal = value as? CGPoint { return pointVal as? T }
        dLog("axValue: Expected CGPoint for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }

    if T.self == CGSize.self {
        if let sizeVal = value as? CGSize { return sizeVal as? T }
        dLog("axValue: Expected CGSize for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }
    
    if T.self == AXUIElement.self {
        if let cfValue = value as CFTypeRef?, CFGetTypeID(cfValue) == AXUIElementGetTypeID() {
            return (cfValue as! AXUIElement) as? T
        }
        let typeDescription = String(describing: type(of: value)) 
        let valueDescription = String(describing: value)
        dLog("axValue: Expected AXUIElement for attribute '\(attr)', but got \(typeDescription): \(valueDescription)")
        return nil
    }
    
    if let castedValue = value as? T {
        return castedValue
    }
    
    dLog("axValue: Fallback cast attempt for attribute '\(attr)' to type \(T.self) FAILED. Unwrapped value was \(type(of: value)): \(value)")
    return nil
}

// MARK: - AXValueType String Helper

public func stringFromAXValueType(_ type: AXValueType) -> String {
    switch type {
    case .cgPoint: return "CGPoint (kAXValueCGPointType)"
    case .cgSize: return "CGSize (kAXValueCGSizeType)"
    case .cgRect: return "CGRect (kAXValueCGRectType)"
    case .cfRange: return "CFRange (kAXValueCFRangeType)"
    case .axError: return "AXError (kAXValueAXErrorType)"
    case .illegal: return "Illegal (kAXValueIllegalType)"
    default:
        // AXValueType is not exhaustive in Swift's AXValueType enum from ApplicationServices.
        // Common missing ones include Boolean (4), Number (5), Array (6), Dictionary (7), String (8), URL (9), etc.
        // We rely on ValueUnwrapper to handle these based on CFGetTypeID.
        // This function is mostly for AXValue encoded types.
        if type.rawValue == 4 { // kAXValueBooleanType is often 4 but not in the public enum
            return "Boolean (rawValue 4, contextually kAXValueBooleanType)"
        }
        return "Unknown AXValueType (rawValue: \(type.rawValue))"
    }
}