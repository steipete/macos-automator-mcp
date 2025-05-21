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
// Update signature to accept logging parameters
public func formatCFTypeRef(_ cfValue: CFTypeRef?, option: ValueFormatOption = .default, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> String {
    guard let value = cfValue else { return "<nil>" }
    let typeID = CFGetTypeID(value)
    // var tempLogs: [String] = [] // Removed as it was unused

    switch typeID {
    case AXUIElementGetTypeID():
        let element = Element(value as! AXUIElement)
        // Pass the received logging parameters to briefDescription
        return element.briefDescription(option: option, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
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
                // Pass logging parameters to recursive call
                swiftArray.append(formatCFTypeRef(Unmanaged<CFTypeRef>.fromOpaque(elementPtr).takeUnretainedValue(), option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs))
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
                    // Pass logging parameters to recursive call
                    swiftDict[key] = formatCFTypeRef(val, option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
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
    // Now a method to accept logging parameters
    public func briefDescription(option: ValueFormatOption = .default, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> String {
        // Call the new method versions of title, identifier, value, description, role
        if let titleStr = self.title(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs), !titleStr.isEmpty {
            let roleStr = self.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) ?? "UnknownRole"
            return "<\(roleStr): \"\(escapeStringForDisplay(titleStr))\">"
        }
        else if let identifierStr = self.identifier(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs), !identifierStr.isEmpty {
            let roleStr = self.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) ?? "UnknownRole"
            return "<\(roleStr) id: \"\(escapeStringForDisplay(identifierStr))\">"
        } else if let valueAny = self.value(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs), let valueStr = valueAny as? String, !valueStr.isEmpty, valueStr.count < 50 { 
            let roleStr = self.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) ?? "UnknownRole"
            return "<\(roleStr) val: \"\(escapeStringForDisplay(valueStr))\">"
        } else if let descStr = self.description(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs), !descStr.isEmpty, descStr.count < 50 { 
            let roleStr = self.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) ?? "UnknownRole"
            return "<\(roleStr) desc: \"\(escapeStringForDisplay(descStr))\">"
        }
        let roleStr = self.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) ?? "UnknownRole"
        return "<\(roleStr)>"
    }
}