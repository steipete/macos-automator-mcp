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

    public var description: String {
        switch self {
        case .notAuthorised(let e): return "AX authorisation failed: \(e)"
        case .elementNotFound:      return "No element matches the locator"
        case .actionFailed(let e):  return "Action failed: \(e)"
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
            if attr == kAXPositionAttribute && valueType.rawValue == AXValueType.cgPoint.rawValue {
                var point = CGPoint.zero
                if AXValueGetValue(axTypedValue, AXValueType.cgPoint, &point) == true {
                    return ["x": Int(point.x), "y": Int(point.y)] as? T
                }
            } else if attr == kAXSizeAttribute && valueType.rawValue == AXValueType.cgSize.rawValue {
                var size = CGSize.zero
                if AXValueGetValue(axTypedValue, AXValueType.cgSize, &size) == true {
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
public func getElementAttributes(_ element: AXUIElement, requestedAttributes: [String], forMultiDefault: Bool = false, targetRole: String? = nil, outputFormat: String = "smart") -> ElementAttributes {
    var result = ElementAttributes()
    var attributesToFetch = requestedAttributes

    if forMultiDefault {
        attributesToFetch = [kAXRoleAttribute, kAXValueAttribute, kAXTitleAttribute, kAXIdentifierAttribute]
        if let role = targetRole, role == "AXStaticText" { 
            attributesToFetch = [kAXRoleAttribute, kAXValueAttribute, kAXIdentifierAttribute]
        }
    } else if attributesToFetch.isEmpty {
        var attrNames: CFArray?
        if AXUIElementCopyAttributeNames(element, &attrNames) == .success, let names = attrNames as? [String] {
            attributesToFetch.append(contentsOf: names)
        }
    }

    var availableActions: [String] = []

    for attr in attributesToFetch {
        var extractedValue: Any? 
        if let val: String = axValue(of: element, attr: attr) { extractedValue = val }
        else if let val: Bool = axValue(of: element, attr: attr) { extractedValue = val }
        else if let val: Int = axValue(of: element, attr: attr) { extractedValue = val }
        else if let val: [String] = axValue(of: element, attr: attr) { 
            extractedValue = val
            if attr == kAXActionNamesAttribute || attr == kAXActionsAttribute { 
                availableActions.append(contentsOf: val)
            }
        }
        else if let count = (axValue(of: element, attr: attr) as [AXUIElement]?)?.count { extractedValue = "Array of \(count) UIElement(s)" }
        else if let uiElement: AXUIElement = axValue(of: element, attr: attr) { extractedValue = "UIElement: \(String(describing: uiElement))"}
        else if let val: [String: Int] = axValue(of: element, attr: attr) { 
             extractedValue = val
        }
        else {
            let rawCFValue: CFTypeRef? = copyAttributeValue(element: element, attribute: attr) 
            if let raw = rawCFValue {
                if CFGetTypeID(raw) == AXUIElementGetTypeID() {
                    extractedValue = "AXUIElement (raw)"
                } else if CFGetTypeID(raw) == AXValueGetTypeID() {
                    extractedValue = "AXValue (type: \(AXValueGetType(raw as! AXValue).rawValue))"
                } else {
                    extractedValue = "CFType: \(String(describing: CFCopyTypeIDDescription(CFGetTypeID(raw))))"
                }
            } else {
                extractedValue = nil
            }
        }
        
        let finalValueToStore = extractedValue
        if outputFormat == "smart" {
            if let strVal = finalValueToStore as? String, (strVal.isEmpty || strVal == "Not available") {
                continue 
            }
        }
        result[attr] = AnyCodable(finalValueToStore)
    }
    
    if !forMultiDefault {
        if result[kAXActionNamesAttribute] == nil && result[kAXActionsAttribute] == nil {
             if let actions: [String] = axValue(of: element, attr: kAXActionNamesAttribute) ?? axValue(of: element, attr: kAXActionsAttribute) {
                if !actions.isEmpty { result[kAXActionNamesAttribute] = AnyCodable(actions); availableActions = actions }
                else { result[kAXActionNamesAttribute] = AnyCodable("Not available (empty list)") }
             } else {
                result[kAXActionNamesAttribute] = AnyCodable("Not available")
             }
        } else if let anyCodableActions = result[kAXActionNamesAttribute], let currentActions = anyCodableActions.value as? [String] {
            availableActions = currentActions
        } else if let anyCodableActions = result[kAXActionsAttribute], let currentActions = anyCodableActions.value as? [String] {
            availableActions = currentActions
        }

        var computedName: String? = nil
        if let title: String = axValue(of: element, attr: kAXTitleAttribute), !title.isEmpty, title != "Not available" { computedName = title }
        else if let value: String = axValue(of: element, attr: kAXValueAttribute), !value.isEmpty, value != "Not available" { computedName = value }
        else if let desc: String = axValue(of: element, attr: kAXDescriptionAttribute), !desc.isEmpty, desc != "Not available" { computedName = desc }
        else if let help: String = axValue(of: element, attr: kAXHelpAttribute), !help.isEmpty, help != "Not available" { computedName = help }
        else if let phValue: String = axValue(of: element, attr: kAXPlaceholderValueAttribute), !phValue.isEmpty, phValue != "Not available" { computedName = phValue }
        else if let roleDesc: String = axValue(of: element, attr: kAXRoleDescriptionAttribute), !roleDesc.isEmpty, roleDesc != "Not available" {
            computedName = "\(roleDesc) (\((axValue(of: element, attr: kAXRoleAttribute) as String?) ?? "Element"))"
        }
        if let name = computedName { result["ComputedName"] = AnyCodable(name) }

        let isButton = (axValue(of: element, attr: kAXRoleAttribute) as String?) == "AXButton"
        let hasPressAction = availableActions.contains(kAXPressAction)
        if isButton || hasPressAction { result["IsClickable"] = AnyCodable(true) }
    }
    return result
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

// End of AXUtils.swift for now