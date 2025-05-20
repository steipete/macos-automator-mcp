// ValueFormatter.swift - Utilities for formatting AX values into human-readable strings

import Foundation
import ApplicationServices
import CoreGraphics // For CGPoint, CGSize, CGRect, CFRange

// debug() is assumed to be globally available from Logging.swift
// stringFromAXValueType() is assumed to be available from ValueHelpers.swift
// axErrorToString() is assumed to be available from AccessibilityConstants.swift

@MainActor
public enum ValueFormatOption {
    case `default` // Concise, suitable for lists or brief views
    case verbose   // More detailed, suitable for focused inspection
}

@MainActor
public func formatAXValue(_ axValue: AXValue, option: ValueFormatOption = .default) -> String {
    let type = AXValueGetType(axValue)
    var result = "AXValue (\(stringFromAXValueType(type)))"

    switch type {
    case .cgPoint:
        var point = CGPoint.zero
        if AXValueGetValue(axValue, .cgPoint, &point) {
            result = "x=\(point.x) y=\(point.y)"
            if option == .verbose { result = "<CGPoint: \(result)>" }
        }
    case .cgSize:
        var size = CGSize.zero
        if AXValueGetValue(axValue, .cgSize, &size) {
            result = "w=\(size.width) h=\(size.height)"
            if option == .verbose { result = "<CGSize: \(result)>" }
        }
    case .cgRect:
        var rect = CGRect.zero
        if AXValueGetValue(axValue, .cgRect, &rect) {
            result = "x=\(rect.origin.x) y=\(rect.origin.y) w=\(rect.size.width) h=\(rect.size.height)"
            if option == .verbose { result = "<CGRect: \(result)>" }
        }
    case .cfRange:
        var range = CFRange()
        if AXValueGetValue(axValue, .cfRange, &range) {
            result = "pos=\(range.location) len=\(range.length)"
            if option == .verbose { result = "<CFRange: \(result)>" }
        }
    case .axError:
        var error = AXError.success
        if AXValueGetValue(axValue, .axError, &error) {
            result = axErrorToString(error)
            if option == .verbose { result = "<AXError: \(result)>" }
        }
    case .illegal:
        result = "Illegal AXValue"
    default:
        // For boolean type (rawValue 4)
        if type.rawValue == 4 {
            var boolResult: DarwinBoolean = false
            if AXValueGetValue(axValue, type, &boolResult) {
                result = boolResult.boolValue ? "true" : "false"
                if option == .verbose { result = "<Boolean: \(result)>"}
            }
        }
        // Other types: return generic description.
        // Consider if other specific AXValueTypes need custom formatting.
        break 
    }
    return result
}

// Helper to escape strings for display (e.g. in logs or formatted output that isn't strict JSON)
private func escapeStringForDisplay(_ input: String) -> String {
    var escaped = input
    // More comprehensive escaping might be needed depending on the exact output context
    // For now, handle common cases for human-readable display.
    escaped = escaped.replacingOccurrences(of: "\\", with: "\\\\") // Escape backslashes first
    escaped = escaped.replacingOccurrences(of: "\"", with: "\\\"")  // Escape double quotes
    escaped = escaped.replacingOccurrences(of: "\n", with: "\\n")   // Escape newlines
    escaped = escaped.replacingOccurrences(of: "\t", with: "\\t")   // Escape tabs
    escaped = escaped.replacingOccurrences(of: "\r", with: "\\r")   // Escape carriage returns
    return escaped
}

@MainActor
public func formatCFTypeRef(_ cfValue: CFTypeRef?, option: ValueFormatOption = .default) -> String {
    guard let value = cfValue else { return "<nil>" }
    let typeID = CFGetTypeID(value)

    switch typeID {
    case AXUIElementGetTypeID():
        let element = Element(value as! AXUIElement)
        return element.briefDescription(option: option)
    case AXValueGetTypeID():
        return formatAXValue(value as! AXValue, option: option)
    case CFStringGetTypeID():
        return "\"\(escapeStringForDisplay(value as! String))\"" // Used helper
    case CFAttributedStringGetTypeID():
         return "\"\(escapeStringForDisplay((value as! NSAttributedString).string ))\"" // Used helper
    case CFBooleanGetTypeID():
        return CFBooleanGetValue((value as! CFBoolean)) ? "true" : "false"
    case CFNumberGetTypeID():
        return (value as! NSNumber).stringValue
    case CFArrayGetTypeID():
        let cfArray = value as! CFArray
        let count = CFArrayGetCount(cfArray)
        if option == .verbose || count <= 5 { // Show contents for small arrays or if verbose
            var swiftArray: [String] = []
            for i in 0..<count {
                guard let elementPtr = CFArrayGetValueAtIndex(cfArray, i) else {
                    swiftArray.append("<nil_in_array>")
                    continue
                }
                swiftArray.append(formatCFTypeRef(Unmanaged<CFTypeRef>.fromOpaque(elementPtr).takeUnretainedValue(), option: .default)) // Use .default for nested
            }
            return "[\(swiftArray.joined(separator: ","))]"
        } else {
            return "<Array of size \(count)>"
        }
    case CFDictionaryGetTypeID():
        let cfDict = value as! CFDictionary
        let count = CFDictionaryGetCount(cfDict)
         if option == .verbose || count <= 3 { // Show contents for small dicts or if verbose
            var swiftDict: [String: String] = [:]
            if let nsDict = cfDict as? [String: AnyObject] {
                for (key, val) in nsDict {
                    swiftDict[key] = formatCFTypeRef(val, option: .default) // Use .default for nested
                }
                // Sort by key for consistent output
                let sortedItems = swiftDict.sorted { $0.key < $1.key }
                                         .map { "\"\(escapeStringForDisplay($0.key))\": \($0.value)" } // Used helper for key, value is already formatted
                return "{\(sortedItems.joined(separator: ","))}"
            } else {
                return "<Dictionary (bridging failed), size \(count)>"
            }
        } else {
            return "<Dictionary of size \(count)>"
        }
    case CFURLGetTypeID():
        return (value as! URL).absoluteString
    default:
        let typeDescription = CFCopyTypeIDDescription(typeID) as String? ?? "Unknown CFType"
        return "<CFType: \(typeDescription)>"
    }
}

// Add a helper to Element for a brief description
extension Element {
    @MainActor
    func briefDescription(option: ValueFormatOption = .default) -> String {
        if let titleStr = self.title, !titleStr.isEmpty {
            return "<\(self.role ?? "UnknownRole"): \"\(escapeStringForDisplay(titleStr))\">"
        }
        // Fallback for elements without titles, using other identifying attributes
        else if let identifierStr = self.identifier, !identifierStr.isEmpty {
            return "<\(self.role ?? "UnknownRole") id: \"\(escapeStringForDisplay(identifierStr))\">"
        } else if let valueStr = self.value as? String, !valueStr.isEmpty, valueStr.count < 50 { // Show brief values
             return "<\(self.role ?? "UnknownRole") val: \"\(escapeStringForDisplay(valueStr))\">"
        } else if let descStr = self.description, !descStr.isEmpty, descStr.count < 50 { // Show brief descriptions
             return "<\(self.role ?? "UnknownRole") desc: \"\(escapeStringForDisplay(descStr))\">"
        }
        return "<\(self.role ?? "UnknownRole")>"
    }
}