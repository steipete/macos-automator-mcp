import Foundation
import ApplicationServices
import CoreGraphics // For CGPoint, CGSize etc.

// debug() is assumed to be globally available from Logging.swift
// Constants like kAXPositionAttribute are assumed to be globally available from AccessibilityConstants.swift

// MARK: - ValueUnwrapper Utility
struct ValueUnwrapper {
    @MainActor
    static func unwrap(_ cfValue: CFTypeRef?, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> Any? {
        func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
        guard let value = cfValue else { return nil }
        let typeID = CFGetTypeID(value)

        switch typeID {
        case ApplicationServices.AXUIElementGetTypeID():
            return value as! AXUIElement
        case ApplicationServices.AXValueGetTypeID():
            let axVal = value as! AXValue
            let axValueType = AXValueGetType(axVal)

            if axValueType.rawValue == 4 { // kAXValueBooleanType (private)
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
                dLog("ValueUnwrapper: Encountered AXValue with type .illegal")
                return nil
            @unknown default: // Added @unknown default to handle potential new AXValueType cases
                dLog("ValueUnwrapper: AXValue with unhandled AXValueType: \(stringFromAXValueType(axValueType)).")
                return axVal // Return the original AXValue if type is unknown
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
                swiftArray.append(unwrap(Unmanaged<CFTypeRef>.fromOpaque(elementPtr).takeUnretainedValue(), isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs))
            }
            return swiftArray
        case CFDictionaryGetTypeID():
            let cfDict = value as! CFDictionary
            var swiftDict: [String: Any?] = [:]
            // Attempt to bridge to Swift dictionary directly if possible
            if let nsDict = cfDict as? [String: AnyObject] { // Use AnyObject for broader compatibility
                for (key, val) in nsDict {
                    swiftDict[key] = unwrap(val, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) // Unwrap the value
                }
            } else {
                 // Fallback for more complex CFDictionary structures if direct bridging fails
                 // This part requires careful handling of CFDictionary keys and values
                 // For now, we'll log if direct bridging fails, as full CFDictionary iteration is complex.
                 dLog("ValueUnwrapper: Failed to bridge CFDictionary to [String: AnyObject]. Full CFDictionary iteration not yet implemented here.")
            }
            return swiftDict
        default:
            dLog("ValueUnwrapper: Unhandled CFTypeID: \(typeID) - \(CFCopyTypeIDDescription(typeID) as String? ?? "Unknown"). Returning raw value.")
            return value // Return the original value if CFType is not handled
        }
    }
}