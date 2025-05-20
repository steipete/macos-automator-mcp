// AXUtils.swift - Contains utility functions for accessibility interactions

import Foundation
import ApplicationServices
import AppKit // For NSRunningApplication, NSWorkspace
import CoreGraphics // For CGPoint, CGSize etc.

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

    public var description: String {
        switch self {
        case .notAuthorised(let e): return "AX authorisation failed: \(e)"
        case .elementNotFound:      return "No element matches the locator criteria or path."
        case .actionFailed(let e):  return "Action failed with AXError: \(e)"
        case .invalidCommand:       return "Invalid command specified."
        case .genericError(let msg): return msg
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
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attr as CFString, &value) == .success else { return nil }
    guard let unwrappedValue = value else { return nil }

    if T.self == String.self || T.self == Optional<String>.self {
        if CFGetTypeID(unwrappedValue) == CFStringGetTypeID() {
            return (unwrappedValue as! CFString) as? T
        } else if CFGetTypeID(unwrappedValue) == CFAttributedStringGetTypeID() {
            debug("axValue: Attribute '\(attr)' is CFAttributedString. Extracting string content.")
            let nsAttrStr = unwrappedValue as! NSAttributedString // Toll-free bridge
            return nsAttrStr.string as? T
        } else if CFGetTypeID(unwrappedValue) == AXValueGetTypeID() {
            let axVal = unwrappedValue as! AXValue
            debug("axValue: Attribute '\(attr)' is AXValue, not directly convertible to String here. Type: \(AXValueGetType(axVal).rawValue)")
            return nil
        }
        return nil
    }
    
    if T.self == Bool.self {
        if CFGetTypeID(unwrappedValue) == CFBooleanGetTypeID() {
            return CFBooleanGetValue((unwrappedValue as! CFBoolean)) as? T
        } else if CFGetTypeID(unwrappedValue) == CFNumberGetTypeID() {
            var intValue: Int = 0
            if CFNumberGetValue((unwrappedValue as! CFNumber), CFNumberType.intType, &intValue) {
                return (intValue != 0) as? T
            }
            return nil 
        } else if CFGetTypeID(unwrappedValue) == AXValueGetTypeID() {
             let axVal = unwrappedValue as! AXValue
             var boolResult: DarwinBoolean = false
             // The rawValue 4 is used here for boolean extraction with AXValueGetValue.
             // This may be an undocumented or specific behavior for boolean AXValues, 
             // as the public AXValueType enum maps rawValue 4 to kAXValueCFRangeType.
             // However, this pattern is crucial for correctly extracting boolean values.
             if AXValueGetType(axVal).rawValue == 4 /* kAXValueBooleanType */ && AXValueGetValue(axVal, AXValueGetType(axVal), &boolResult) {
                 return (boolResult.boolValue) as? T
             }
             return nil
        }
        return nil
    }
    
    if T.self == Int.self {
        if CFGetTypeID(unwrappedValue) == CFNumberGetTypeID() {
            var intValue: Int = 0
            if CFNumberGetValue((unwrappedValue as! CFNumber), CFNumberType.intType, &intValue) {
                return intValue as? T
            }
        }
        return nil
    }
    
    if T.self == [AXUIElement].self {
        if CFGetTypeID(unwrappedValue) == CFArrayGetTypeID() {
            let cfArray = unwrappedValue as! CFArray
            var result = [AXUIElement]()
            for i in 0..<CFArrayGetCount(cfArray) {
                guard let elementPtr = CFArrayGetValueAtIndex(cfArray, i) else { continue }
                let cfType = Unmanaged<CFTypeRef>.fromOpaque(elementPtr).takeUnretainedValue()
                if CFGetTypeID(cfType) == AXUIElementGetTypeID() { 
                    result.append(cfType as! AXUIElement)
                }
            }
            return result as? T
        }
        return nil
    }

    if T.self == [String].self {
        if CFGetTypeID(unwrappedValue) == CFArrayGetTypeID() {
            let cfArray = unwrappedValue as! CFArray
            var result = [String]()
            for i in 0..<CFArrayGetCount(cfArray) {
                guard let elementPtr = CFArrayGetValueAtIndex(cfArray, i) else { continue }
                let cfType = Unmanaged<CFTypeRef>.fromOpaque(elementPtr).takeUnretainedValue()
                if CFGetTypeID(cfType) == CFStringGetTypeID() {
                    result.append(cfType as! String)
                }
            }
            return result as? T
        }
        return nil
    }

    if T.self == [String: Int].self && (attr == kAXPositionAttribute || attr == kAXSizeAttribute) {
        if CFGetTypeID(unwrappedValue) == AXValueGetTypeID() {
            let axTypedValue = unwrappedValue as! AXValue
            let valueType = AXValueGetType(axTypedValue)
            // Use direct enum case comparison for CGPoint and CGSize
            if attr == kAXPositionAttribute && valueType == .cgPoint {
                var point = CGPoint.zero
                if AXValueGetValue(axTypedValue, .cgPoint, &point) == true {
                    return ["x": Int(point.x), "y": Int(point.y)] as? T
                }
            } else if attr == kAXSizeAttribute && valueType == .cgSize {
                var size = CGSize.zero
                if AXValueGetValue(axTypedValue, .cgSize, &size) == true {
                    return ["width": Int(size.width), "height": Int(size.height)] as? T
                }
            }
        }
        return nil 
    }
    
    if T.self == AXUIElement.self {
        if CFGetTypeID(unwrappedValue) == AXUIElementGetTypeID() {
            return unwrappedValue as? T
        }
        return nil
    }
    
    debug("axValue: Fallback cast attempt for attribute '\(attr)' to type \(T.self).")
    return unwrappedValue as? T
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