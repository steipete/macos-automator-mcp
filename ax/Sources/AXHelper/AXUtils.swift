// AXUtils.swift - Contains utility functions for accessibility interactions

import Foundation
import ApplicationServices
import AppKit // For NSRunningApplication, NSWorkspace
import CoreGraphics // For CGPoint, CGSize etc.

// MARK: - AXValueUnwrapper Utility
// Inspired by AXSwift's separation of concerns for unpacking AXValue types.
struct AXValueUnwrapper {
    @MainActor // Ensure calls are on main actor if they involve AX APIs directly or indirectly
    static func unwrap(_ cfValue: CFTypeRef?) -> Any? {
        guard let value = cfValue else { return nil }
        let typeID = CFGetTypeID(value)

        switch typeID {
        case AXUIElementGetTypeID():
            return value as! AXUIElement // Return as is, caller can wrap if needed
        case AXValueGetTypeID():
            let axVal = value as! AXValue
            let axValueType = AXValueGetType(axVal)
            
            // Prioritize our empirically found boolean handling
            if axValueType.rawValue == 4 { // kAXValueCFRangeType in public enum, but contextually boolean
                var boolResult: DarwinBoolean = false
                if AXValueGetValue(axVal, axValueType, &boolResult) {
                    return boolResult.boolValue
                }
                // If it's rawValue 4 but NOT extractable as bool, let it fall through
                // to the switch to be handled as .cfRange or default.
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
            case .cfRange: // This handles the case where rawValue 4 wasn't our special boolean
                var cfRange = CFRange()
                return AXValueGetValue(axVal, .cfRange, &cfRange) ? cfRange : nil
            case .axError:
                var axError: AXError = .success
                return AXValueGetValue(axVal, .axError, &axError) ? axError : nil
            case .illegal:
                debug("AXValueUnwrapper: Encountered AXValue with type .illegal")
                return nil // Or some representation of illegal
            default:
                debug("AXValueUnwrapper: AXValue with unhandled AXValueType: \(axValueType.rawValue) - \(stringFromAXValueType(axValueType)). Returning raw AXValue.")
                return axVal // Return the AXValue itself if type is not specifically handled
            }
        case CFStringGetTypeID():
            return (value as! CFString) as String
        case CFAttributedStringGetTypeID():
             // Extract string content from CFAttributedString
            return (value as! NSAttributedString).string
        case CFBooleanGetTypeID():
            return CFBooleanGetValue((value as! CFBoolean))
        case CFNumberGetTypeID():
            return value as! NSNumber // Let Swift bridge it to Int, Double, Bool as needed later
        case CFArrayGetTypeID():
            // Return as Swift array of Any?, caller can then process further
            let cfArray = value as! CFArray
            var swiftArray: [Any?] = []
            for i in 0..<CFArrayGetCount(cfArray) {
                guard let elementPtr = CFArrayGetValueAtIndex(cfArray, i) else {
                    swiftArray.append(nil)
                    continue
                }
                // Recursively unwrap elements within the array
                swiftArray.append(unwrap(Unmanaged<CFTypeRef>.fromOpaque(elementPtr).takeUnretainedValue()))
            }
            return swiftArray
        case CFDictionaryGetTypeID():
            let cfDict = value as! CFDictionary
            var swiftDict: [String: Any?] = [:]
            if let nsDict = cfDict as? [String: AnyObject] { // Bridge to NSDictionary equivalent
                for (key, val) in nsDict {
                    // Recursively unwrap values from the bridged dictionary
                    swiftDict[key] = unwrap(val)
                }
            } else {
                 debug("AXValueUnwrapper: Failed to bridge CFDictionary to [String: AnyObject].")
            }
            return swiftDict
        default:
            debug("AXValueUnwrapper: Unhandled CFTypeID: \(typeID) - \(CFCopyTypeIDDescription(typeID) as String? ?? "Unknown"). Returning raw value.")
            return value // Return the raw CFTypeRef if not recognized
        }
    }
}

// Helper function to get AXUIElement type ID (moved from main.swift)
public func AXUIElementGetTypeID() -> CFTypeID {
    return AXUIElementGetTypeID_Impl()
}

// Bridging to the private function (moved from main.swift)
@_silgen_name("AXUIElementGetTypeID")
public func AXUIElementGetTypeID_Impl() -> CFTypeID

public enum AXErrorString: Error, CustomStringConvertible {
    case notAuthorised(AXError)
    case elementNotFound
    case actionFailed(AXError)
    case invalidCommand
    case genericError(String)
    case typeMismatch(expected: String, actual: String)

    public var description: String {
        switch self {
        case .notAuthorised(let e): return "AX authorisation failed: \(e)"
        case .elementNotFound:      return "No element matches the locator criteria or path."
        case .actionFailed(let e):  return "Action failed with AXError: \(e)"
        case .invalidCommand:       return "Invalid command specified."
        case .genericError(let msg): return msg
        case .typeMismatch(let expected, let actual): return "Type mismatch: Expected \(expected), got \(actual)."
        }
    }
}

@MainActor
public func pid(forAppIdentifier ident: String) -> pid_t? {
    debug("Looking for app: \(ident)")
    if ident == "Safari" {
        if let safariApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Safari").first {
            return safariApp.processIdentifier
        }
        if let safariApp = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == "Safari" }) {
            return safariApp.processIdentifier
        }
    }
    if let byBundle = NSRunningApplication.runningApplications(withBundleIdentifier: ident).first {
        return byBundle.processIdentifier
    }
    if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == ident }) {
        return app.processIdentifier
    }
    if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName?.lowercased() == ident.lowercased() }) {
        return app.processIdentifier
    }
    debug("App not found: \(ident)")
    return nil
}

@MainActor
public func copyAttributeValue(element: AXUIElement, attribute: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
        return nil
    }
    return value
}

@MainActor
public func elementSupportsAction(_ element: AXUIElement, action: String) -> Bool {
    var actionNames: CFArray?
    guard AXUIElementCopyActionNames(element, &actionNames) == .success, let actions = actionNames else {
        return false
    }
    for i in 0..<CFArrayGetCount(actions) {
        if let actionPtr = CFArrayGetValueAtIndex(actions, i),
           let actionStr = unsafeBitCast(actionPtr, to: CFString.self) as String?,
           actionStr == action {
            return true
        }
    }
    return false
}

public func parsePathComponent(_ path: String) -> (role: String, index: Int)? {
    let pattern = #"(\w+)\[(\d+)\]"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(path.startIndex..<path.endIndex, in: path)
    guard let match = regex.firstMatch(in: path, range: range) else { return nil }
    let role = (path as NSString).substring(with: match.range(at: 1))
    guard let index = Int((path as NSString).substring(with: match.range(at: 2))) else { return nil }
    return (role: role, index: index - 1)
}

@MainActor
public func navigateToElement(from root: AXUIElement, pathHint: [String]) -> AXUIElement? {
    var currentElement = root
    for pathComponent in pathHint {
        guard let (role, index) = parsePathComponent(pathComponent) else { return nil }
        if role.lowercased() == "window" {
            guard let windows: [AXUIElement] = axValue(of: currentElement, attr: kAXWindowsAttribute), index < windows.count else { return nil }
            currentElement = windows[index]
        } else {
            let roleKey = "AX\(role.prefix(1).uppercased() + role.dropFirst())"
            if let children: [AXUIElement] = axValue(of: currentElement, attr: roleKey), index < children.count {
                currentElement = children[index]
            } else {
                guard let allChildren: [AXUIElement] = axValue(of: currentElement, attr: kAXChildrenAttribute) else { return nil }
                let matchingChildren = allChildren.filter { el in
                    (axValue(of: el, attr: kAXRoleAttribute) as String?)?.lowercased() == role.lowercased()
                }
                guard index < matchingChildren.count else { return nil }
                currentElement = matchingChildren[index]
            }
        }
    }
    return currentElement
}

@MainActor
public func axValue<T>(of element: AXUIElement, attr: String) -> T? {
    let rawCFValue = copyAttributeValue(element: element, attribute: attr)
    let unwrappedValue = AXValueUnwrapper.unwrap(rawCFValue)

    guard let value = unwrappedValue else { return nil }

    // Now, handle specific type conversions and transformations based on T
    if T.self == String.self {
        if let str = value as? String { // Primary case: unwrapper already gave a String
            return str as? T
        } else if let attrStr = value as? NSAttributedString { // Fallback: if value is NSAttributedString
            debug("axValue: Value for String was NSAttributedString, extracting .string. Attribute: \(attr)")
            return attrStr.string as? T
        }
        debug("axValue: Expected String for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }
    
    if T.self == Bool.self {
        if let boolVal = value as? Bool {
            return boolVal as? T
        } else if let numVal = value as? NSNumber { // CFNumber can represent booleans
            return numVal.boolValue as? T
        }
        debug("axValue: Expected Bool for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }
    
    if T.self == Int.self {
        if let intVal = value as? Int {
            return intVal as? T
        } else if let numVal = value as? NSNumber {
            return numVal.intValue as? T
        }
        debug("axValue: Expected Int for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }

    if T.self == Double.self { // Added Double support
        if let doubleVal = value as? Double {
            return doubleVal as? T
        } else if let numVal = value as? NSNumber {
            return numVal.doubleValue as? T
        }
        debug("axValue: Expected Double for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }
    
    if T.self == [AXUIElement].self {
        if let anyArray = value as? [Any?] {
            let result = anyArray.compactMap { item -> AXUIElement? in
                guard let cfItem = item else { return nil } // Ensure item is not nil
                // Check if cfItem is an AXUIElement by its TypeID before casting
                // Ensure cfItem is treated as CFTypeRef for CFGetTypeID
                if CFGetTypeID(cfItem as CFTypeRef) == AXUIElementGetTypeID() {
                    return (cfItem as! AXUIElement) // Safe force-cast after type check
                }
                return nil
            }
            // If T is [AXUIElement], an empty array is a valid result. Casting `result` to `T?` is appropriate.
            return result as? T
        }
        debug("axValue: Expected [AXUIElement] for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }

    if T.self == [String].self {
        if let stringArray = value as? [Any?] { // Unwrapper returns [Any?] for arrays
            let result = stringArray.compactMap { $0 as? String }
            if result.count == stringArray.count { // Ensure all elements were Strings
                 return result as? T
            }
        }
        debug("axValue: Expected [String] for attribute '\(attr)', but got \(type(of: value)): \(value)")
        return nil
    }

    // Handle CGPoint and CGSize specifically for our [String: Int] format
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
        // Ensure value is not nil and check its CFTypeID before attempting cast
        // Make sure to cast `value` to CFTypeRef for CFGetTypeID
        if let cfValue = value as CFTypeRef?, CFGetTypeID(cfValue) == AXUIElementGetTypeID() {
            return (cfValue as! AXUIElement) as? T // Safe force-cast after type check
        }
        // If we are here, value is non-nil (due to earlier guard) but not an AXUIElement.
        // So, value is of type 'Any'.
        let typeDescription = String(describing: type(of: value)) 
        let valueDescription = String(describing: value)
        debug("axValue: Expected AXUIElement for attribute '\(attr)', but got \(typeDescription): \(valueDescription)")
        return nil
    }
    
    // Fallback direct cast if no specific handling matched T
    if let castedValue = value as? T {
        return castedValue
    }
    
    debug("axValue: Fallback cast attempt for attribute '\(attr)' to type \(T.self) FAILED. Unwrapped value was \(type(of: value)): \(value)")
    return nil
}

@MainActor
public func extractTextContent(element: AXUIElement) -> String {
    var texts: [String] = []
    let textualAttributes = [
        kAXValueAttribute, kAXTitleAttribute, kAXDescriptionAttribute, kAXHelpAttribute,
        kAXPlaceholderValueAttribute, kAXLabelValueAttribute, kAXRoleDescriptionAttribute,
    ]
    for attrName in textualAttributes {
        if let strValue: String = axValue(of: element, attr: attrName), !strValue.isEmpty, strValue != "Not available" {
            texts.append(strValue)
        }
    }
    var uniqueTexts: [String] = []
    var seenTexts = Set<String>()
    for text in texts {
        if !seenTexts.contains(text) {
            uniqueTexts.append(text)
            seenTexts.insert(text)
        }
    }
    return uniqueTexts.joined(separator: "\n")
}

@MainActor
public func checkAccessibilityPermissions() {
    if !AXIsProcessTrusted() {
        fputs("ERROR: Accessibility permissions are not granted.\n", stderr)
        fputs("Please enable in System Settings > Privacy & Security > Accessibility.\n", stderr)
        if let parentName = getParentProcessName() {
            fputs("Hint: Grant accessibility permissions to '\(parentName)'.\n", stderr)
        }
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        _ = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        exit(1)
    } else {
        debug("Accessibility permissions are granted.")
    }
}

@MainActor
public func getParentProcessName() -> String? {
    let parentPid = getppid()
    if let parentApp = NSRunningApplication(processIdentifier: parentPid) {
        return parentApp.localizedName ?? parentApp.bundleIdentifier
    }
    return nil
}

@MainActor 
public func getApplicationElement(bundleIdOrName: String) -> AXUIElement? {
    guard let processID = pid(forAppIdentifier: bundleIdOrName) else { // pid is in AXUtils.swift
        debug("Failed to find PID for app: \(bundleIdOrName)")
        return nil
    }
    debug("Creating application element for PID: \(processID) for app '\(bundleIdOrName)'.")
    return AXUIElementCreateApplication(processID)
}

// Helper function to get a string description for AXValueType
public func stringFromAXValueType(_ type: AXValueType) -> String {
    switch type {
    case .cgPoint: return "CGPoint (kAXValueCGPointType)"
    case .cgSize: return "CGSize (kAXValueCGSizeType)"
    case .cgRect: return "CGRect (kAXValueCGRectType)"
    case .cfRange: return "CFRange (kAXValueCFRangeType)" // Publicly this is rawValue 4
    case .axError: return "AXError (kAXValueAXErrorType)"
    case .illegal: return "Illegal (kAXValueIllegalType)"
    // Add other known public cases if necessary
    default:
        // Handle the special case where rawValue 4 is treated as Boolean by AXValueGetValue
        if type.rawValue == 4 { // Check if this is the boolean-specific context
            return "Boolean (rawValue 4, contextually kAXValueBooleanType)"
        }
        return "Unknown AXValueType (rawValue: \(type.rawValue))"
    }
}