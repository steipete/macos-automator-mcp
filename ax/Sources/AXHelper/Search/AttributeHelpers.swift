// AttributeHelpers.swift - Contains functions for fetching and formatting element attributes

import Foundation
import ApplicationServices // For AXUIElement related types
import CoreGraphics // For potential future use with geometry types from attributes

// Note: This file assumes Models (for ElementAttributes, AnyCodable), 
// Logging (for debug), AccessibilityConstants, and Utils (for axValue) are available in the same module.
// And now Element for the new element wrapper.

// MARK: - Element Summary Helpers

@MainActor
private func getSingleElementSummary(_ element: Element) -> ElementAttributes { // Changed to Element
    var summary = ElementAttributes()
    summary[kAXRoleAttribute] = AnyCodable(element.role)
    summary[kAXSubroleAttribute] = AnyCodable(element.subrole)
    summary[kAXRoleDescriptionAttribute] = AnyCodable(element.roleDescription)
    summary[kAXTitleAttribute] = AnyCodable(element.title)
    summary[kAXDescriptionAttribute] = AnyCodable(element.description)
    summary[kAXIdentifierAttribute] = AnyCodable(element.identifier)
    summary[kAXHelpAttribute] = AnyCodable(element.help)
    summary[kAXPathHintAttribute] = AnyCodable(element.attribute(Attribute<String>(kAXPathHintAttribute)))
    
    // Add new status properties
    summary["PID"] = AnyCodable(element.pid)
    summary[kAXEnabledAttribute] = AnyCodable(element.isEnabled)
    summary[kAXFocusedAttribute] = AnyCodable(element.isFocused)
    summary[kAXHiddenAttribute] = AnyCodable(element.isHidden)
    summary["IsIgnored"] = AnyCodable(element.isIgnored)
    summary[kAXElementBusyAttribute] = AnyCodable(element.isElementBusy)

    return summary
}

// MARK: - Internal Fetch Logic Helpers

@MainActor
private func extractDirectPropertyValue(for attributeName: String, from element: Element, outputFormat: OutputFormat) -> (value: Any?, handled: Bool) {
    var extractedValue: Any?
    var handled = true

    // This block for pathHint should be fine, as pathHint is already a String?
    if attributeName == kAXPathHintAttribute {
        extractedValue = element.attribute(Attribute<String>(kAXPathHintAttribute))
    }
    // Prefer direct Element properties where available
    else if attributeName == kAXRoleAttribute { extractedValue = element.role }
    else if attributeName == kAXSubroleAttribute { extractedValue = element.subrole }
    else if attributeName == kAXTitleAttribute { extractedValue = element.title }
    else if attributeName == kAXDescriptionAttribute { extractedValue = element.description }
    else if attributeName == kAXEnabledAttribute {
        extractedValue = element.isEnabled
        if outputFormat == .text_content {
            extractedValue = (extractedValue as? Bool)?.description ?? kAXNotAvailableString
        }
    }
    else if attributeName == kAXFocusedAttribute {
        extractedValue = element.isFocused
        if outputFormat == .text_content {
            extractedValue = (extractedValue as? Bool)?.description ?? kAXNotAvailableString
        }
    }
    else if attributeName == kAXHiddenAttribute {
        extractedValue = element.isHidden
        if outputFormat == .text_content {
            extractedValue = (extractedValue as? Bool)?.description ?? kAXNotAvailableString
        }
    }
    else if attributeName == "IsIgnored" { // String literal for IsIgnored
        extractedValue = element.isIgnored
        if outputFormat == .text_content {
            extractedValue = (extractedValue as? Bool)?.description ?? kAXNotAvailableString
        }
    }
    else if attributeName == "PID" { // String literal for PID
        extractedValue = element.pid
        if outputFormat == .text_content {
            extractedValue = (extractedValue as? pid_t)?.description ?? kAXNotAvailableString
        }
    }
    else if attributeName == kAXElementBusyAttribute {
        extractedValue = element.isElementBusy
        if outputFormat == .text_content {
            extractedValue = (extractedValue as? Bool)?.description ?? kAXNotAvailableString
        }
    } else {
        handled = false // Attribute not handled by this direct property logic
    }
    return (extractedValue, handled)
}

@MainActor
private func determineAttributesToFetch(requestedAttributes: [String], forMultiDefault: Bool, targetRole: String?, element: Element) -> [String] {
    var attributesToFetch = requestedAttributes
    if forMultiDefault {
        attributesToFetch = [kAXRoleAttribute, kAXValueAttribute, kAXTitleAttribute, kAXIdentifierAttribute]
        // Use element.role here for targetRole comparison
        if let role = targetRole, role == kAXStaticTextRole as String { // Used constant
            attributesToFetch = [kAXRoleAttribute, kAXValueAttribute, kAXIdentifierAttribute]
        }
    } else if attributesToFetch.isEmpty {
        var attrNames: CFArray?
        // Use underlyingElement for direct C API calls
        if AXUIElementCopyAttributeNames(element.underlyingElement, &attrNames) == .success, let names = attrNames as? [String] {
            attributesToFetch.append(contentsOf: names)
        }
    }
    return attributesToFetch
}

// MARK: - Public Attribute Getters

@MainActor
public func getElementAttributes(_ element: Element, requestedAttributes: [String], forMultiDefault: Bool = false, targetRole: String? = nil, outputFormat: OutputFormat = .smart) -> ElementAttributes { // Changed to enum type
    var result = ElementAttributes()
    // var attributesToFetch = requestedAttributes // Logic moved to determineAttributesToFetch
    // var extractedValue: Any? // No longer needed here, handled by helper or scoped in loop

    // Determine the actual format option for the new formatters
    let valueFormatOption: ValueFormatOption = (outputFormat == .verbose) ? .verbose : .default

    let attributesToFetch = determineAttributesToFetch(requestedAttributes: requestedAttributes, forMultiDefault: forMultiDefault, targetRole: targetRole, element: element)

    for attr in attributesToFetch {
        if attr == kAXParentAttribute { 
            result[kAXParentAttribute] = formatParentAttribute(element.parent, outputFormat: outputFormat, valueFormatOption: valueFormatOption)
            continue 
        } else if attr == kAXChildrenAttribute { 
            result[attr] = formatChildrenAttribute(element.children, outputFormat: outputFormat, valueFormatOption: valueFormatOption)
            continue
        } else if attr == kAXFocusedUIElementAttribute { 
            // extractedValue = formatFocusedUIElementAttribute(element.focusedElement, outputFormat: outputFormat, valueFormatOption: valueFormatOption)
            result[attr] = AnyCodable(formatFocusedUIElementAttribute(element.focusedElement, outputFormat: outputFormat, valueFormatOption: valueFormatOption))
            continue // Continue after direct assignment
        }

        let (directValue, wasHandledDirectly) = extractDirectPropertyValue(for: attr, from: element, outputFormat: outputFormat)
        var finalValueToStore: Any?

        if wasHandledDirectly {
            finalValueToStore = directValue
        } else {
            // For other attributes, use the generic attribute<T> or rawAttributeValue and then format
            let rawCFValue: CFTypeRef? = element.rawAttributeValue(named: attr)
            if outputFormat == .text_content {
                finalValueToStore = formatRawCFValueForTextContent(rawCFValue)
            } else { // For "smart" or "verbose" output, use the new formatter
                finalValueToStore = formatCFTypeRef(rawCFValue, option: valueFormatOption)
            }
        }
        
        // let finalValueToStore = extractedValue // This line is replaced by the logic above
        // Smart filtering: if it's a string and empty OR specific unhelpful strings, skip it for 'smart' output.
        if outputFormat == .smart {
            if let strVal = finalValueToStore as? String,
               (strVal.isEmpty || strVal == "<nil>" || strVal == "AXValue (Illegal)" || strVal.contains("Unknown CFType")) {
                continue 
            }
        }
        result[attr] = AnyCodable(finalValueToStore)
    }
    
    // --- Start of moved block --- Always compute these heuristic attributes ---
    // But only add them if not explicitly requested by the user with the same key.

    // Calculate ComputedName
    if result["ComputedName"] == nil { // Only if not already set by explicit request
        if let name = element.computedName { // USE Element.computedName
            result["ComputedName"] = AnyCodable(name)
        }
    }

    // Calculate IsClickable
    if result["IsClickable"] == nil { // Only if not already set
        let isButton = element.role == "AXButton"
        let hasPressAction = element.isActionSupported(kAXPressAction)
        if isButton || hasPressAction { result["IsClickable"] = AnyCodable(true) }
    }
    
    // Add descriptive path if in verbose mode (moved out of !forMultiDefault check)
    if outputFormat == .verbose && result["ComputedPath"] == nil {
        result["ComputedPath"] = AnyCodable(element.generatePathString())
    }
    // --- End of moved block ---

    if !forMultiDefault {
        populateActionNamesAttribute(for: element, result: &result)
        // The ComputedName, IsClickable, and ComputedPath (for verbose) are now handled above, outside this !forMultiDefault block.
    }
    return result
}

@MainActor
private func populateActionNamesAttribute(for element: Element, result: inout ElementAttributes) {
    // Use element.supportedActions directly in the result population
    if let currentActions = element.supportedActions, !currentActions.isEmpty {
        result[kAXActionNamesAttribute] = AnyCodable(currentActions)
    } else if result[kAXActionNamesAttribute] == nil && result[kAXActionsAttribute] == nil {
        // Fallback if element.supportedActions was nil or empty and not already populated
        let primaryActions: [String]? = element.attribute(Attribute<[String]>(kAXActionNamesAttribute))
        let fallbackActions: [String]? = element.attribute(Attribute<[String]>(kAXActionsAttribute))

        if let actions = primaryActions ?? fallbackActions, !actions.isEmpty {
           result[kAXActionNamesAttribute] = AnyCodable(actions)
        } else if primaryActions != nil || fallbackActions != nil { 
           result[kAXActionNamesAttribute] = AnyCodable("\(kAXNotAvailableString) (empty list)")
        } else {
           result[kAXActionNamesAttribute] = AnyCodable(kAXNotAvailableString)
        }
    }
    // The ComputedName, IsClickable, and ComputedPath (for verbose) are handled elsewhere.
}

// MARK: - Attribute Formatting Helpers

// Helper function to format the parent attribute
@MainActor
private func formatParentAttribute(_ parent: Element?, outputFormat: OutputFormat, valueFormatOption: ValueFormatOption) -> AnyCodable {
    guard let parentElement = parent else {
        return AnyCodable(nil as String?) // Keep nil consistent with AnyCodable
    }

    if outputFormat == .text_content {
        return AnyCodable("Element: \(parentElement.role ?? "?Role")")
    } else {
        // Use new formatter for brief/verbose description
        return AnyCodable(parentElement.briefDescription(option: valueFormatOption))
    }
}

// Helper function to format the children attribute
@MainActor
private func formatChildrenAttribute(_ children: [Element]?, outputFormat: OutputFormat, valueFormatOption: ValueFormatOption) -> AnyCodable {
    guard let actualChildren = children, !actualChildren.isEmpty else {
        return AnyCodable("[]") // Empty array string representation
    }

    if outputFormat == .text_content {
        return AnyCodable("Array of \(actualChildren.count) Element(s)")
    } else if outputFormat == .verbose { // Verbose gets full summaries for children
        var childrenSummaries: [String] = [] // Store as strings now
        for childElement in actualChildren {
            childrenSummaries.append(childElement.briefDescription(option: .verbose))
        }
        return AnyCodable(childrenSummaries) 
    } else { // Smart or default
        return AnyCodable("<Collection of \(actualChildren.count) \(actualChildren.first?.role ?? "Element")s>")
    }
}

// Helper function to format the focused UI element attribute
@MainActor
private func formatFocusedUIElementAttribute(_ focusedElement: Element?, outputFormat: OutputFormat, valueFormatOption: ValueFormatOption) -> Any? {
    guard let focusedElem = focusedElement else { return nil }

    if outputFormat == .text_content {
        return "Element Focus: \(focusedElem.role ?? "?Role")"
    } else {
        return focusedElem.briefDescription(option: valueFormatOption)
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
internal func getComputedAttributes(for element: Element) -> ElementAttributes {
    var computedAttrs = ElementAttributes()

    if let name = element.computedName { // USE Element.computedName
        computedAttrs["ComputedName"] = AnyCodable(name)
    }

    let isButton = element.role == "AXButton"
    let hasPressAction = element.isActionSupported(kAXPressAction)
    if isButton || hasPressAction { computedAttrs["IsClickable"] = AnyCodable(true) }
    
    // Add other lightweight heuristic attributes here if needed in the future for matching

    return computedAttrs
}

// MARK: - Attribute Formatting Helpers (Additional)

// Helper function to format a raw CFTypeRef for .text_content output
@MainActor
private func formatRawCFValueForTextContent(_ rawCFValue: CFTypeRef?) -> String {
    guard let raw = rawCFValue else {
        return "<Not directly string representable>"
    }
    let typeID = CFGetTypeID(raw)
    if typeID == CFStringGetTypeID() { return (raw as! String) }
    else if typeID == CFAttributedStringGetTypeID() { return (raw as! NSAttributedString).string }
    else if typeID == AXValueGetTypeID() {
        let axVal = raw as! AXValue
        return formatAXValue(axVal, option: .default) // Assumes formatAXValue returns String
    } else if typeID == CFNumberGetTypeID() { return (raw as! NSNumber).stringValue }
    else if typeID == CFBooleanGetTypeID() { return CFBooleanGetValue((raw as! CFBoolean)) ? "true" : "false" }
    else { return "<\(CFCopyTypeIDDescription(typeID) as String? ?? "ComplexType")>" }
}

// Any other attribute-specific helper functions could go here in the future.