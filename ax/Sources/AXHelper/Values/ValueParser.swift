// AXValueParser.swift - Utilities for parsing string inputs into AX-compatible values

import Foundation
import ApplicationServices
import CoreGraphics // For CGPoint, CGSize, CGRect, CFRange

// debug() is assumed to be globally available from Logging.swift
// Constants are assumed to be globally available from AccessibilityConstants.swift
// Scanner and CustomCharacterSet are from Scanner.swift
// AccessibilityError is from AccessibilityError.swift

// Inspired by UIElementInspector's UIElementUtilities.m

// AXValueParseError enum has been removed and its cases merged into AccessibilityError.

@MainActor
public func getCFTypeIDForAttribute(element: Element, attributeName: String) -> CFTypeID? {
    guard let rawValue = element.rawAttributeValue(named: attributeName) else {
        debug("getCFTypeIDForAttribute: Failed to get raw attribute value for '\(attributeName)'")
        return nil
    }
    return CFGetTypeID(rawValue)
}

@MainActor
public func getAXValueTypeForAttribute(element: Element, attributeName: String) -> AXValueType? {
    guard let rawValue = element.rawAttributeValue(named: attributeName) else {
        debug("getAXValueTypeForAttribute: Failed to get raw attribute value for '\(attributeName)'")
        return nil
    }
    
    guard CFGetTypeID(rawValue) == AXValueGetTypeID() else {
        debug("getAXValueTypeForAttribute: Attribute '\(attributeName)' is not an AXValue. TypeID: \(CFGetTypeID(rawValue))")
        return nil
    }
    
    let axValue = rawValue as! AXValue
    return AXValueGetType(axValue)
}


// Main function to create CFTypeRef for setting an attribute
// It determines the type of the attribute and then calls the appropriate parser.
@MainActor
public func createCFTypeRefFromString(stringValue: String, forElement element: Element, attributeName: String) throws -> CFTypeRef? {
    guard let currentRawValue = element.rawAttributeValue(named: attributeName) else {
        throw AccessibilityError.attributeNotReadable("Could not read current value for attribute '\(attributeName)' to determine type.")
    }

    let typeID = CFGetTypeID(currentRawValue)

    if typeID == AXValueGetTypeID() {
        let axValue = currentRawValue as! AXValue
        let axValueType = AXValueGetType(axValue)
        debug("Attribute '\(attributeName)' is AXValue of type: \(stringFromAXValueType(axValueType))")
        return try parseStringToAXValue(stringValue: stringValue, targetAXValueType: axValueType)
    } else if typeID == CFStringGetTypeID() {
        debug("Attribute '\(attributeName)' is CFString. Returning stringValue as CFString.")
        return stringValue as CFString
    } else if typeID == CFNumberGetTypeID() {
        debug("Attribute '\(attributeName)' is CFNumber. Attempting to parse stringValue as Double then create CFNumber.")
        if let doubleValue = Double(stringValue) {
            return NSNumber(value: doubleValue) // CFNumber is toll-free bridged to NSNumber
        } else if let intValue = Int(stringValue) {
             return NSNumber(value: intValue)
        } else {
            throw AccessibilityError.valueParsingFailed(details: "Could not parse '\(stringValue)' as Double or Int for CFNumber attribute '\(attributeName)'")
        }
    } else if typeID == CFBooleanGetTypeID() {
        debug("Attribute '\(attributeName)' is CFBoolean. Attempting to parse stringValue as Bool.")
        if stringValue.lowercased() == "true" {
            return kCFBooleanTrue
        } else if stringValue.lowercased() == "false" {
            return kCFBooleanFalse
        } else {
            throw AccessibilityError.valueParsingFailed(details: "Could not parse '\(stringValue)' as Bool (true/false) for CFBoolean attribute '\(attributeName)'")
        }
    }
    // TODO: Handle other CFTypeIDs like CFArray, CFDictionary if necessary for set-value.
    // For now, focus on types directly convertible from string or AXValue structs.

    let typeDescription = CFCopyTypeIDDescription(typeID) as String? ?? "Unknown CFType"
    throw AccessibilityError.attributeUnsupported("Setting attribute '\(attributeName)' of CFTypeID \(typeID) (\(typeDescription)) from string is not supported yet.")
}


// Parses a string into an AXValue for struct types like CGPoint, CGSize, CGRect, CFRange
@MainActor
private func parseStringToAXValue(stringValue: String, targetAXValueType: AXValueType) throws -> AXValue? {
    var valueRef: AXValue?

    switch targetAXValueType {
    case .cgPoint:
        var x: Double = 0
        var y: Double = 0
        // Expected format: "x=10.0 y=20.0" or "10.0,20.0" etc.
        // Using a more robust regex or component separation might be better than sscanf.
        // For simplicity, let's try a basic split.
        let components = stringValue.replacingOccurrences(of: " ", with: "").split(separator: ",")
        if components.count == 2,
           let xValStr = components[0].split(separator: "=").last, let xVal = Double(xValStr),
           let yValStr = components[1].split(separator: "=").last, let yVal = Double(yValStr) {
            x = xVal
            y = yVal
        } else if components.count == 2, let xVal = Double(components[0]), let yVal = Double(components[1]) {
            x = xVal
            y = yVal
        }
        // Alternative parsing for formats like "x:10 y:20"
        else {
             let scanner = Scanner(string: stringValue)
             _ = scanner.scanCharacters(in: CustomCharacterSet(charactersInString: "xy:, \t\n")) // consume prefixes/delimiters
             let xScanned = scanner.scanDouble()
             _ = scanner.scanCharacters(in: CustomCharacterSet(charactersInString: "xy:, \t\n")) // consume delimiters
             let yScanned = scanner.scanDouble()
             if let xVal = xScanned, let yVal = yScanned {
                 x = xVal
                 y = yVal
              } else {
                throw AccessibilityError.valueParsingFailed(details: "Could not parse '\(stringValue)' into CGPoint. Expected format like 'x=10,y=20' or '10,20'.")
             }
        }
        var point = CGPoint(x: x, y: y)
        valueRef = AXValueCreate(targetAXValueType, &point)

    case .cgSize:
        var w: Double = 0
        var h: Double = 0
        let components = stringValue.replacingOccurrences(of: " ", with: "").split(separator: ",")
        if components.count == 2,
           let wValStr = components[0].split(separator: "=").last, let wVal = Double(wValStr),
           let hValStr = components[1].split(separator: "=").last, let hVal = Double(hValStr) {
            w = wVal
            h = hVal
        } else if components.count == 2, let wVal = Double(components[0]), let hVal = Double(components[1]) {
            w = wVal
            h = hVal
        } else {
            let scanner = Scanner(string: stringValue)
            _ = scanner.scanCharacters(in: CustomCharacterSet(charactersInString: "wh:, \t\n"))
            let wScanned = scanner.scanDouble()
            _ = scanner.scanCharacters(in: CustomCharacterSet(charactersInString: "wh:, \t\n"))
            let hScanned = scanner.scanDouble()
            if let wVal = wScanned, let hVal = hScanned {
                w = wVal
                h = hVal
            } else {
                 throw AccessibilityError.valueParsingFailed(details: "Could not parse '\(stringValue)' into CGSize. Expected format like 'w=100,h=50' or '100,50'.")
            }
        }
        var size = CGSize(width: w, height: h)
        valueRef = AXValueCreate(targetAXValueType, &size)

    case .cgRect:
        var x: Double = 0, y: Double = 0, w: Double = 0, h: Double = 0
        let components = stringValue.replacingOccurrences(of: " ", with: "").split(separator: ",")
        if components.count == 4,
           let xStr = components[0].split(separator: "=").last, let xVal = Double(xStr),
           let yStr = components[1].split(separator: "=").last, let yVal = Double(yStr),
           let wStr = components[2].split(separator: "=").last, let wVal = Double(wStr),
           let hStr = components[3].split(separator: "=").last, let hVal = Double(hStr) {
            x = xVal; y = yVal; w = wVal; h = hVal
        } else if components.count == 4,
            let xVal = Double(components[0]), let yVal = Double(components[1]),
            let wVal = Double(components[2]), let hVal = Double(components[3]) {
            x = xVal; y = yVal; w = wVal; h = hVal
        } else {
            let scanner = Scanner(string: stringValue)
            _ = scanner.scanCharacters(in: CustomCharacterSet(charactersInString: "xywh:, \t\n"))
            let xS_opt = scanner.scanDouble()
            _ = scanner.scanCharacters(in: CustomCharacterSet(charactersInString: "xywh:, \t\n"))
            let yS_opt = scanner.scanDouble()
            _ = scanner.scanCharacters(in: CustomCharacterSet(charactersInString: "xywh:, \t\n"))
            let wS_opt = scanner.scanDouble()
            _ = scanner.scanCharacters(in: CustomCharacterSet(charactersInString: "xywh:, \t\n"))
            let hS_opt = scanner.scanDouble()
            if let xS = xS_opt, let yS = yS_opt, let wS = wS_opt, let hS = hS_opt {
                x = xS; y = yS; w = wS; h = hS
            } else {
                throw AccessibilityError.valueParsingFailed(details: "Could not parse '\(stringValue)' into CGRect. Expected format like 'x=0,y=0,w=100,h=50' or '0,0,100,50'.")
            }
        }
        var rect = CGRect(x: x, y: y, width: w, height: h)
        valueRef = AXValueCreate(targetAXValueType, &rect)

    case .cfRange:
        var loc: Int = 0
        var len: Int = 0
        // Expected format "loc=0,len=10" or "0,10"
        let components = stringValue.replacingOccurrences(of: " ", with: "").split(separator: ",")
        if components.count == 2,
           let locStr = components[0].split(separator: "=").last, let locVal = Int(locStr),
           let lenStr = components[1].split(separator: "=").last, let lenVal = Int(lenStr) {
            loc = locVal; len = lenVal
        } else if components.count == 2, let locVal = Int(components[0]), let lenVal = Int(components[1]) {
            loc = locVal; len = lenVal
        } else {
            // Fallback to scanner if simple split fails
            let scanner = Scanner(string: stringValue)
            _ = scanner.scanCharacters(in: CustomCharacterSet(charactersInString: "loclen:, \t\n"))
            let locScanned = scanner.scanInteger() as Int? // Assuming scanInteger returns a generic SignedInteger
            _ = scanner.scanCharacters(in: CustomCharacterSet(charactersInString: "loclen:, \t\n"))
            let lenScanned = scanner.scanInteger() as Int?
            if let locV = locScanned, let lenV = lenScanned {
                loc = locV
                len = lenV
            } else {
                throw AccessibilityError.valueParsingFailed(details: "Could not parse '\(stringValue)' into CFRange. Expected format like 'loc=0,len=10' or '0,10'.")
            }
        }
        var range = CFRangeMake(loc, len)
        valueRef = AXValueCreate(targetAXValueType, &range)
        
    case .illegal:
        throw AccessibilityError.attributeUnsupported("Cannot parse value for AXValueType .illegal")
        
    case .axError: // Should not be settable
         throw AccessibilityError.attributeUnsupported("Cannot set an attribute of AXValueType .axError")

    default:
        // This case handles types that might be simple (like a boolean wrapped in AXValue)
        // or other specific AXValueTypes not covered above.
        // For boolean:
        if targetAXValueType.rawValue == 4 { // Empirically, AXValueBooleanType is 4
            var boolVal: DarwinBoolean
            if stringValue.lowercased() == "true" {
                boolVal = true
            } else if stringValue.lowercased() == "false" {
                boolVal = false
            } else {
                throw AccessibilityError.valueParsingFailed(details: "Could not parse '\(stringValue)' as boolean for AXValue.")
            }
            valueRef = AXValueCreate(targetAXValueType, &boolVal)
        } else {
            throw AccessibilityError.attributeUnsupported("Parsing for AXValueType '\(stringFromAXValueType(targetAXValueType))' (rawValue: \(targetAXValueType.rawValue)) from string is not supported yet.")
        }
    }

    if valueRef == nil {
         throw AccessibilityError.valueParsingFailed(details: "AXValueCreate failed for type \(stringFromAXValueType(targetAXValueType)) with input '\(stringValue)'")
    }
    return valueRef
} 