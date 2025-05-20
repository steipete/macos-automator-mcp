import Foundation
import ApplicationServices
import CoreGraphics // For CGPoint, CGSize etc.

// debug() is assumed to be globally available from AXLogging.swift
// Constants like kAXPositionAttribute are assumed to be globally available from AXConstants.swift

// MARK: - AXValueUnwrapper Utility
struct AXValueUnwrapper {
    @MainActor
    static func unwrap(_ cfValue: CFTypeRef?) -> Any? {
        guard let value = cfValue else { return nil }
        let typeID = CFGetTypeID(value)

        switch typeID {
        case ApplicationServices.AXUIElementGetTypeID(): 
            return value as! AXUIElement 
        case ApplicationServices.AXValueGetTypeID():   
            let axVal = value as! AXValue
            let axValueType = AXValueGetType(axVal)
            
            if axValueType.rawValue == 4 { 
                var boolResult: DarwinBoolean = false
                if AXValueGetValue(axVal, axValueType, &boolResult) {
                    return boolResult.boolValue
                }
            }

            switch axValueType {
            case .cgPoint:
                var point = CGPoint.zero
                return AXValueGetValue(axVal, .cgPoint, &point) ? point : nil
            case .cgSize:
                var size = CGSize.zero
                return AXValueGetValue(axVal, .cgSize, &size) ? size : nil
            case .cgRect:
                var rect = CGRect.zero
                return AXValueGetValue(axVal, .cgRect, &rect) ? rect : nil
            case .cfRange: 
                var cfRange = CFRange()
                return AXValueGetValue(axVal, .cfRange, &cfRange) ? cfRange : nil
            case .axError:
                var axErrorValue: AXError = .success 
                return AXValueGetValue(axVal, .axError, &axErrorValue) ? axErrorValue : nil
            case .illegal:
                debug("AXValueUnwrapper: Encountered AXValue with type .illegal")
                return nil
            default:
                debug("AXValueUnwrapper: AXValue with unhandled AXValueType: \(stringFromAXValueType(axValueType)).")
                return axVal 
            }
        case CFStringGetTypeID():
            return (value as! CFString) as String
        case CFAttributedStringGetTypeID():
            return (value as! NSAttributedString).string
        case CFBooleanGetTypeID():
            return CFBooleanGetValue((value as! CFBoolean))
        case CFNumberGetTypeID():
            return value as! NSNumber
        case CFArrayGetTypeID():
            let cfArray = value as! CFArray
            var swiftArray: [Any?] = []
            for i in 0..<CFArrayGetCount(cfArray) {
                guard let elementPtr = CFArrayGetValueAtIndex(cfArray, i) else {
                    swiftArray.append(nil)
                    continue
                }
                swiftArray.append(unwrap(Unmanaged<CFTypeRef>.fromOpaque(elementPtr).takeUnretainedValue()))
            }
            return swiftArray
        case CFDictionaryGetTypeID():
            let cfDict = value as! CFDictionary
            var swiftDict: [String: Any?] = [:]
            if let nsDict = cfDict as? [String: AnyObject] {
                for (key, val) in nsDict {
                    swiftDict[key] = unwrap(val)
                }
            } else {
                 debug("AXValueUnwrapper: Failed to bridge CFDictionary to [String: AnyObject].")
            }
            return swiftDict
        default:
            debug("AXValueUnwrapper: Unhandled CFTypeID: \(typeID) - \(CFCopyTypeIDDescription(typeID) as String? ?? "Unknown"). Returning raw value.")
            return value
        }
    }
}

// MARK: - Attribute Value Accessors

@MainActor
public func copyAttributeValue(element: AXUIElement, attribute: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
        return nil
    }
    return value
}

@MainActor
public func axValue<T>(of element: AXUIElement, attr: String) -> T? {
    let rawCFValue = copyAttributeValue(element: element, attribute: attr)
    let unwrappedValue = AXValueUnwrapper.unwrap(rawCFValue)

    guard let value = unwrappedValue else { return nil }

    if T.self == String.self {
        if let str = value as? String { return str as? T }
        else if let attrStr = value as? NSAttributedString { return attrStr.string as? T }
        debug("axValue: Expected String for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }
    
    if T.self == Bool.self {
        if let boolVal = value as? Bool { return boolVal as? T }
        else if let numVal = value as? NSNumber { return numVal.boolValue as? T }
        debug("axValue: Expected Bool for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }
    
    if T.self == Int.self {
        if let intVal = value as? Int { return intVal as? T }
        else if let numVal = value as? NSNumber { return numVal.intValue as? T }
        debug("axValue: Expected Int for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }

    if T.self == Double.self {
        if let doubleVal = value as? Double { return doubleVal as? T }
        else if let numVal = value as? NSNumber { return numVal.doubleValue as? T }
        debug("axValue: Expected Double for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }
    
    if T.self == [AXUIElement].self {
        if let anyArray = value as? [Any?] {
            let result = anyArray.compactMap { item -> AXUIElement? in
                guard let cfItem = item else { return nil } 
                if CFGetTypeID(cfItem as CFTypeRef) == ApplicationServices.AXUIElementGetTypeID() {
                    return (cfItem as! AXUIElement)
                }
                return nil
            }
            return result as? T
        }
        debug("axValue: Expected [AXUIElement] for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }

    if T.self == [AXElement].self {
        if let anyArray = value as? [Any?] {
            let result = anyArray.compactMap { item -> AXElement? in
                guard let cfItem = item else { return nil }
                if CFGetTypeID(cfItem as CFTypeRef) == ApplicationServices.AXUIElementGetTypeID() {
                    return AXElement(cfItem as! AXUIElement)
                }
                return nil
            }
            return result as? T
        }
        debug("axValue: Expected [AXElement] for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }

    if T.self == [String].self {
        if let stringArray = value as? [Any?] { 
            let result = stringArray.compactMap { $0 as? String }
            if result.count == stringArray.count { return result as? T }
        }
        debug("axValue: Expected [String] for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }

    if T.self == [String: Int].self {
        if attr == kAXPositionAttribute, let point = value as? CGPoint {
            return ["x": Int(point.x), "y": Int(point.y)] as? T
        } else if attr == kAXSizeAttribute, let size = value as? CGSize {
            return ["width": Int(size.width), "height": Int(size.height)] as? T
        }
        debug("axValue: Expected [String: Int] for position/size attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }
    
    if T.self == AXUIElement.self {
        if let cfValue = value as CFTypeRef?, CFGetTypeID(cfValue) == ApplicationServices.AXUIElementGetTypeID() {
            return (cfValue as! AXUIElement) as? T
        }
        let typeDescription = String(describing: type(of: value)) 
        let valueDescription = String(describing: value)
        debug("axValue: Expected AXUIElement for attribute '\(attr)', but got \(typeDescription): \(valueDescription)")
        return nil
    }
    
    if let castedValue = value as? T {
        return castedValue
    }
    
    debug("axValue: Fallback cast attempt for attribute '\(attr)' to type \(T.self) FAILED. Unwrapped value was \(type(of: value)): \(value)")
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
        if type.rawValue == 4 { 
            return "Boolean (rawValue 4, contextually kAXValueBooleanType)"
        }
        return "Unknown AXValueType (rawValue: \(type.rawValue))"
    }
} 