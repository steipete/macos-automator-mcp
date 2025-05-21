// AttributeHelpers.swift - Contains functions for fetching and formatting element attributes

import Foundation
import ApplicationServices // For AXUIElement related types
import CoreGraphics // For potential future use with geometry types from attributes

// Note: This file assumes Models (for ElementAttributes, AnyCodable), 
// Logging (for debug), AccessibilityConstants, and Utils (for axValue) are available in the same module.
// And now Element for the new element wrapper.

// Define AttributeData and AttributeSource here as they are not found by the compiler
public enum AttributeSource: String, Codable {
    case direct // Directly from an AXAttribute
    case computed // Derived by this tool
}

public struct AttributeData: Codable {
    public let value: AnyCodable
    public let source: AttributeSource
}

// MARK: - Element Summary Helpers

// Removed getSingleElementSummary as it was unused.

// MARK: - Internal Fetch Logic Helpers

// Approach using direct property access within a switch statement
@MainActor
private func extractDirectPropertyValue(for attributeName: String, from element: Element, outputFormat: OutputFormat, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> (value: Any?, handled: Bool) {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For Element method calls
    var extractedValue: Any?
    var handled = true
    
    // Ensure logging parameters are passed to Element methods
    switch attributeName {
    case kAXPathHintAttribute:
        extractedValue = element.attribute(Attribute<String>(kAXPathHintAttribute), isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    case kAXRoleAttribute:
        extractedValue = element.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    case kAXSubroleAttribute:
        extractedValue = element.subrole(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    case kAXTitleAttribute:
        extractedValue = element.title(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    case kAXDescriptionAttribute:
        extractedValue = element.description(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    case kAXEnabledAttribute:
        let val = element.isEnabled(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
        extractedValue = val
        if outputFormat == .text_content { extractedValue = val?.description ?? kAXNotAvailableString }
    case kAXFocusedAttribute:
        let val = element.isFocused(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
        extractedValue = val
        if outputFormat == .text_content { extractedValue = val?.description ?? kAXNotAvailableString }
    case kAXHiddenAttribute:
        let val = element.isHidden(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
        extractedValue = val
        if outputFormat == .text_content { extractedValue = val?.description ?? kAXNotAvailableString }
    case isIgnoredAttributeKey:
        let val = element.isIgnored(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
        extractedValue = val
        if outputFormat == .text_content { extractedValue = val ? "true" : "false" }
    case "PID":
        let val = element.pid(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
        extractedValue = val
        if outputFormat == .text_content { extractedValue = val?.description ?? kAXNotAvailableString }
    case kAXElementBusyAttribute:
        let val = element.isElementBusy(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
        extractedValue = val
        if outputFormat == .text_content { extractedValue = val?.description ?? kAXNotAvailableString }
    default:
        handled = false
    }
    currentDebugLogs.append(contentsOf: tempLogs) // Collect logs from Element method calls
    return (extractedValue, handled)
}

@MainActor
private func determineAttributesToFetch(requestedAttributes: [String], forMultiDefault: Bool, targetRole: String?, element: Element, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> [String] {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var attributesToFetch = requestedAttributes
    if forMultiDefault {
        attributesToFetch = [kAXRoleAttribute, kAXValueAttribute, kAXTitleAttribute, kAXIdentifierAttribute]
        if let role = targetRole, role == kAXStaticTextRole {
            attributesToFetch = [kAXRoleAttribute, kAXValueAttribute, kAXIdentifierAttribute]
        }
    } else if attributesToFetch.isEmpty {
        var attrNames: CFArray?
        if AXUIElementCopyAttributeNames(element.underlyingElement, &attrNames) == .success, let names = attrNames as? [String] {
            attributesToFetch.append(contentsOf: names)
            dLog("determineAttributesToFetch: No specific attributes requested, fetched all \(names.count) available: \(names.joined(separator: ", "))")
        } else {
            dLog("determineAttributesToFetch: No specific attributes requested and failed to fetch all available names.")
        }
    }
    return attributesToFetch
}

// MARK: - Public Attribute Getters

@MainActor
public func getElementAttributes(_ element: Element, requestedAttributes: [String], forMultiDefault: Bool = false, targetRole: String? = nil, outputFormat: OutputFormat = .smart, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> ElementAttributes {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For Element method calls, cleared and appended for each.
    var result = ElementAttributes()
    let valueFormatOption: ValueFormatOption = (outputFormat == .verbose) ? .verbose : .default

    tempLogs.removeAll()
    dLog("getElementAttributes starting for element: \(element.briefDescription(option: valueFormatOption, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)), format: \(outputFormat)")
    currentDebugLogs.append(contentsOf: tempLogs)

    let attributesToFetch = determineAttributesToFetch(requestedAttributes: requestedAttributes, forMultiDefault: forMultiDefault, targetRole: targetRole, element: element, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
    dLog("Attributes to fetch: \(attributesToFetch.joined(separator: ", "))")

    for attr in attributesToFetch {
        var tempCallLogs: [String] = [] // Logs for a specific attribute fetching call
        if attr == kAXParentAttribute { 
            tempCallLogs.removeAll()
            let parent = element.parent(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempCallLogs)
            result[kAXParentAttribute] = formatParentAttribute(parent, outputFormat: outputFormat, valueFormatOption: valueFormatOption, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempCallLogs) // formatParentAttribute will manage its own logs now
            currentDebugLogs.append(contentsOf: tempCallLogs) // Collect logs from element.parent and formatParentAttribute
            continue 
        } else if attr == kAXChildrenAttribute { 
            tempCallLogs.removeAll()
            let children = element.children(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempCallLogs)
            result[attr] = formatChildrenAttribute(children, outputFormat: outputFormat, valueFormatOption: valueFormatOption, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempCallLogs) // formatChildrenAttribute will manage its own logs
            currentDebugLogs.append(contentsOf: tempCallLogs)
            continue
        } else if attr == kAXFocusedUIElementAttribute { 
            tempCallLogs.removeAll()
            let focused = element.focusedElement(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempCallLogs)
            result[attr] = AnyCodable(formatFocusedUIElementAttribute(focused, outputFormat: outputFormat, valueFormatOption: valueFormatOption, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempCallLogs))
            currentDebugLogs.append(contentsOf: tempCallLogs)
            continue
        }

        tempCallLogs.removeAll()
        let (directValue, wasHandledDirectly) = extractDirectPropertyValue(for: attr, from: element, outputFormat: outputFormat, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempCallLogs)
        currentDebugLogs.append(contentsOf: tempCallLogs)
        var finalValueToStore: Any?

        if wasHandledDirectly {
            finalValueToStore = directValue
            dLog("Attribute '\(attr)' handled directly, value: \(String(describing: directValue))")
        } else {
            tempCallLogs.removeAll()
            let rawCFValue: CFTypeRef? = element.rawAttributeValue(named: attr, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempCallLogs)
            currentDebugLogs.append(contentsOf: tempCallLogs)
            if outputFormat == .text_content {
                finalValueToStore = formatRawCFValueForTextContent(rawCFValue)
            } else { 
                finalValueToStore = formatCFTypeRef(rawCFValue, option: valueFormatOption, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            }
            dLog("Attribute '\(attr)' fetched via rawAttributeValue, formatted value: \(String(describing: finalValueToStore))")
        }
        
        if outputFormat == .smart {
            if let strVal = finalValueToStore as? String,
               (strVal.isEmpty || strVal == "<nil>" || strVal == "AXValue (Illegal)" || strVal.contains("Unknown CFType") || strVal == kAXNotAvailableString) {
                dLog("Smart format: Skipping attribute '\(attr)' with unhelpful value: \(strVal)")
                continue 
            }
        }
        result[attr] = AnyCodable(finalValueToStore)
    }
    
    tempLogs.removeAll()
    if result[computedNameAttributeKey] == nil { 
        if let name = element.computedName(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) {
            result[computedNameAttributeKey] = AnyCodable(AttributeData(value: AnyCodable(name), source: .computed))
            dLog("Added ComputedName: \(name)")
        }
    }
    currentDebugLogs.append(contentsOf: tempLogs)

    tempLogs.removeAll()
    if result[isClickableAttributeKey] == nil { 
        let isButton = (element.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) == kAXButtonRole)
        let hasPressAction = element.isActionSupported(kAXPressAction, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
        if isButton || hasPressAction { 
            result[isClickableAttributeKey] = AnyCodable(AttributeData(value: AnyCodable(true), source: .computed))
            dLog("Added IsClickable: true (button: \(isButton), pressAction: \(hasPressAction))")
        }
    }
    currentDebugLogs.append(contentsOf: tempLogs)
    
    tempLogs.removeAll()
    if outputFormat == .verbose && result[computedPathAttributeKey] == nil {
        let path = element.generatePathString(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
        result[computedPathAttributeKey] = AnyCodable(path)
        dLog("Added ComputedPath (verbose): \(path)")
    }
    currentDebugLogs.append(contentsOf: tempLogs)

    populateActionNamesAttribute(for: element, result: &result, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)

    dLog("getElementAttributes finished. Result keys: \(result.keys.joined(separator: ", "))")
    return result
}

@MainActor
private func populateActionNamesAttribute(for element: Element, result: inout ElementAttributes, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For Element method calls
    if result[kAXActionNamesAttribute] != nil {
        dLog("populateActionNamesAttribute: Already present or explicitly requested, skipping.")
        return
    }
    currentDebugLogs.append(contentsOf: tempLogs) // Appending potentially empty tempLogs, for consistency, though it does nothing here.

    var actionsToStore: [String]?
    tempLogs.removeAll()
    if let currentActions = element.supportedActions(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs), !currentActions.isEmpty {
        actionsToStore = currentActions
        dLog("populateActionNamesAttribute: Got \(currentActions.count) from supportedActions.")
    } else {
        dLog("populateActionNamesAttribute: supportedActions was nil or empty. Trying kAXActionsAttribute.")
        tempLogs.removeAll() // Clear before next call that uses it
        if let fallbackActions: [String] = element.attribute(Attribute<[String]>(kAXActionsAttribute), isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs), !fallbackActions.isEmpty {
            actionsToStore = fallbackActions
            dLog("populateActionNamesAttribute: Got \(fallbackActions.count) from kAXActionsAttribute fallback.")
        }
    }
    currentDebugLogs.append(contentsOf: tempLogs)

    tempLogs.removeAll()
    let pressActionSupported = element.isActionSupported(kAXPressAction, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    currentDebugLogs.append(contentsOf: tempLogs)
    dLog("populateActionNamesAttribute: kAXPressAction supported: \(pressActionSupported).")
    if pressActionSupported {
        if actionsToStore == nil { actionsToStore = [kAXPressAction] }
        else if !actionsToStore!.contains(kAXPressAction) { actionsToStore!.append(kAXPressAction) }
    }

    if let finalActions = actionsToStore, !finalActions.isEmpty {
        result[kAXActionNamesAttribute] = AnyCodable(finalActions)
        dLog("populateActionNamesAttribute: Final actions: \(finalActions.joined(separator: ", ")).")
    } else {
        tempLogs.removeAll()
        let primaryNil = element.supportedActions(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) == nil
        currentDebugLogs.append(contentsOf: tempLogs)
        tempLogs.removeAll()
        let fallbackNil = element.attribute(Attribute<[String]>(kAXActionsAttribute), isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) == nil
        currentDebugLogs.append(contentsOf: tempLogs)
        if primaryNil && fallbackNil && !pressActionSupported {
            result[kAXActionNamesAttribute] = AnyCodable(kAXNotAvailableString)
            dLog("populateActionNamesAttribute: All action sources nil/unsupported. Set to kAXNotAvailableString.")
        } else {
            result[kAXActionNamesAttribute] = AnyCodable("\(kAXNotAvailableString) (no specific actions found or list empty)")
            dLog("populateActionNamesAttribute: Some action source present but list empty. Set to verbose kAXNotAvailableString.")
        }
    }
}

// MARK: - Attribute Formatting Helpers

// Helper function to format the parent attribute
@MainActor
private func formatParentAttribute(_ parent: Element?, outputFormat: OutputFormat, valueFormatOption: ValueFormatOption, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> AnyCodable {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For Element method calls
    guard let parentElement = parent else { return AnyCodable(nil as String?) }
    if outputFormat == .text_content {
        return AnyCodable("Element: \(parentElement.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) ?? "?Role")")
    } else {
        return AnyCodable(parentElement.briefDescription(option: valueFormatOption, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs))
    }
}

// Helper function to format the children attribute
@MainActor
private func formatChildrenAttribute(_ children: [Element]?, outputFormat: OutputFormat, valueFormatOption: ValueFormatOption, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> AnyCodable {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For Element method calls
    guard let actualChildren = children, !actualChildren.isEmpty else { return AnyCodable("[]") }
    if outputFormat == .text_content {
        return AnyCodable("Array of \(actualChildren.count) Element(s)")
    } else if outputFormat == .verbose {
        var childrenSummaries: [String] = []
        for childElement in actualChildren {
            childrenSummaries.append(childElement.briefDescription(option: valueFormatOption, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs))
        }
        return AnyCodable("[\(childrenSummaries.joined(separator: ", "))]")
    } else { // .smart output
        return AnyCodable("Array of \(actualChildren.count) children")
    }
}

// Helper function to format the focused UI element attribute
@MainActor
private func formatFocusedUIElementAttribute(_ focusedElement: Element?, outputFormat: OutputFormat, valueFormatOption: ValueFormatOption, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> AnyCodable {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For Element method calls
    guard let actualFocusedElement = focusedElement else { return AnyCodable(nil as String?) }
    if outputFormat == .text_content {
        return AnyCodable("Element: \(actualFocusedElement.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) ?? "?Role")")
    } else {
        return AnyCodable(actualFocusedElement.briefDescription(option: valueFormatOption, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs))
    }
}

/// Encodes the given ElementAttributes dictionary into a new dictionary containing
/// a single key "json_representation" with the JSON string as its value.
/// If encoding fails, returns a dictionary with an error message.
@MainActor
public func encodeAttributesToJSONStringRepresentation(_ attributes: ElementAttributes) -> ElementAttributes {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted // Or .sortedKeys for deterministic output if needed
    do {
        let jsonData = try encoder.encode(attributes) // attributes is [String: AnyCodable]
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            return ["json_representation": AnyCodable(jsonString)] 
        } else {
            return ["error": AnyCodable("Failed to convert encoded JSON data to string")]
        }
    } catch {
        return ["error": AnyCodable("Failed to encode attributes to JSON: \(error.localizedDescription)")]
    }
}

// MARK: - Computed Attributes

// New helper function to get only computed/heuristic attributes for matching
@MainActor
public func getComputedAttributes(for element: Element, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> ElementAttributes {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For Element method calls
    var attributes: ElementAttributes = [:]

    tempLogs.removeAll()
    dLog("getComputedAttributes for element: \(element.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs))")
    currentDebugLogs.append(contentsOf: tempLogs)

    tempLogs.removeAll()
    if let name = element.computedName(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) {
        attributes[computedNameAttributeKey] = AnyCodable(AttributeData(value: AnyCodable(name), source: .computed))
        dLog("ComputedName: \(name)")
    }
    currentDebugLogs.append(contentsOf: tempLogs)

    tempLogs.removeAll()
    let isButton = (element.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) == kAXButtonRole)
    currentDebugLogs.append(contentsOf: tempLogs) // Collect logs from role call
    tempLogs.removeAll()
    let hasPressAction = element.isActionSupported(kAXPressAction, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    currentDebugLogs.append(contentsOf: tempLogs) // Collect logs from isActionSupported call

    if isButton || hasPressAction {
        attributes[isClickableAttributeKey] = AnyCodable(AttributeData(value: AnyCodable(true), source: .computed))
        dLog("IsClickable: true (button: \(isButton), pressAction: \(hasPressAction))")
    }
    
    // Ensure other computed attributes like ComputedPath also use methods with logging if they exist.
    // For now, this focuses on the direct errors.

    return attributes
}

// MARK: - Attribute Formatting Helpers (Additional)

// Helper function to format a raw CFTypeRef for .text_content output
@MainActor
private func formatRawCFValueForTextContent(_ rawValue: CFTypeRef?) -> String {
    guard let value = rawValue else { return kAXNotAvailableString }
    let typeID = CFGetTypeID(value)
    if typeID == CFStringGetTypeID() { return (value as! String) }
    else if typeID == CFAttributedStringGetTypeID() { return (value as! NSAttributedString).string }
    else if typeID == AXValueGetTypeID() {
        let axVal = value as! AXValue
        return formatAXValue(axVal, option: .default) // Assumes formatAXValue returns String
    } else if typeID == CFNumberGetTypeID() { return (value as! NSNumber).stringValue }
    else if typeID == CFBooleanGetTypeID() { return CFBooleanGetValue((value as! CFBoolean)) ? "true" : "false" }
    else { return "<\(CFCopyTypeIDDescription(typeID) as String? ?? "ComplexType")>" }
}

// Any other attribute-specific helper functions could go here in the future.