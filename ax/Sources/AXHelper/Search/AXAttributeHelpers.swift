// AXAttributeHelpers.swift - Contains functions for fetching and formatting element attributes

import Foundation
import ApplicationServices // For AXUIElement related types
import CoreGraphics // For potential future use with geometry types from attributes

// Note: This file assumes AXModels (for ElementAttributes, AnyCodable), 
// AXLogging (for debug), AXConstants, and AXUtils (for axValue) are available in the same module.
// And now AXElement for the new element wrapper.

@MainActor
private func getSingleElementSummary(_ axElement: AXElement) -> ElementAttributes { // Changed to AXElement
    var summary = ElementAttributes()
    summary[kAXRoleAttribute] = AnyCodable(axElement.role)
    summary[kAXSubroleAttribute] = AnyCodable(axElement.subrole)
    summary[kAXRoleDescriptionAttribute] = AnyCodable(axElement.roleDescription)
    summary[kAXTitleAttribute] = AnyCodable(axElement.title)
    summary[kAXDescriptionAttribute] = AnyCodable(axElement.axDescription)
    summary[kAXIdentifierAttribute] = AnyCodable(axElement.identifier)
    summary[kAXHelpAttribute] = AnyCodable(axElement.help)
    summary[kAXPathHintAttribute] = AnyCodable(axElement.attribute(AXAttribute<String>(kAXPathHintAttribute)))
    
    // Add new status properties
    summary["PID"] = AnyCodable(axElement.pid)
    summary[kAXEnabledAttribute] = AnyCodable(axElement.isEnabled)
    summary[kAXFocusedAttribute] = AnyCodable(axElement.isFocused)
    summary[kAXHiddenAttribute] = AnyCodable(axElement.isHidden)
    summary["IsIgnored"] = AnyCodable(axElement.isIgnored)
    summary[kAXElementBusyAttribute] = AnyCodable(axElement.isElementBusy)

    return summary
}

@MainActor
private func extractDirectPropertyValue(for attributeName: String, from axElement: AXElement, outputFormat: OutputFormat) -> (value: Any?, handled: Bool) {
    var extractedValue: Any?
    var handled = true

    // This block for pathHint should be fine, as pathHint is already a String?
    if attributeName == kAXPathHintAttribute {
        extractedValue = axElement.attribute(AXAttribute<String>(kAXPathHintAttribute))
    }
    // Prefer direct AXElement properties where available
    else if attributeName == kAXRoleAttribute { extractedValue = axElement.role }
    else if attributeName == kAXSubroleAttribute { extractedValue = axElement.subrole }
    else if attributeName == kAXTitleAttribute { extractedValue = axElement.title }
    else if attributeName == kAXDescriptionAttribute { extractedValue = axElement.axDescription }
    else if attributeName == kAXEnabledAttribute {
        extractedValue = axElement.isEnabled
        if outputFormat == .text_content {
            extractedValue = (extractedValue as? Bool)?.description ?? kAXNotAvailableString
        }
    }
    else if attributeName == kAXFocusedAttribute {
        extractedValue = axElement.isFocused
        if outputFormat == .text_content {
            extractedValue = (extractedValue as? Bool)?.description ?? kAXNotAvailableString
        }
    }
    else if attributeName == kAXHiddenAttribute {
        extractedValue = axElement.isHidden
        if outputFormat == .text_content {
            extractedValue = (extractedValue as? Bool)?.description ?? kAXNotAvailableString
        }
    }
    else if attributeName == "IsIgnored" { // String literal for IsIgnored
        extractedValue = axElement.isIgnored
        if outputFormat == .text_content {
            extractedValue = (extractedValue as? Bool)?.description ?? kAXNotAvailableString
        }
    }
    else if attributeName == "PID" { // String literal for PID
        extractedValue = axElement.pid
        if outputFormat == .text_content {
            extractedValue = (extractedValue as? pid_t)?.description ?? kAXNotAvailableString
        }
    }
    else if attributeName == kAXElementBusyAttribute {
        extractedValue = axElement.isElementBusy
        if outputFormat == .text_content {
            extractedValue = (extractedValue as? Bool)?.description ?? kAXNotAvailableString
        }
    } else {
        handled = false // Attribute not handled by this direct property logic
    }
    return (extractedValue, handled)
}

@MainActor
private func determineAttributesToFetch(requestedAttributes: [String], forMultiDefault: Bool, targetRole: String?, axElement: AXElement) -> [String] {
    var attributesToFetch = requestedAttributes
    if forMultiDefault {
        attributesToFetch = [kAXRoleAttribute, kAXValueAttribute, kAXTitleAttribute, kAXIdentifierAttribute]
        // Use axElement.role here for targetRole comparison
        if let role = targetRole, role == kAXStaticTextRole as String { // Used constant
            attributesToFetch = [kAXRoleAttribute, kAXValueAttribute, kAXIdentifierAttribute]
        }
    } else if attributesToFetch.isEmpty {
        var attrNames: CFArray?
        // Use underlyingElement for direct C API calls
        if AXUIElementCopyAttributeNames(axElement.underlyingElement, &attrNames) == .success, let names = attrNames as? [String] {
            attributesToFetch.append(contentsOf: names)
        }
    }
    return attributesToFetch
}

@MainActor
public func getElementAttributes(_ axElement: AXElement, requestedAttributes: [String], forMultiDefault: Bool = false, targetRole: String? = nil, outputFormat: OutputFormat = .smart) -> ElementAttributes { // Changed to enum type
    var result = ElementAttributes()
    // var attributesToFetch = requestedAttributes // Logic moved to determineAttributesToFetch
    // var extractedValue: Any? // No longer needed here, handled by helper or scoped in loop

    // Determine the actual format option for the new formatters
    let valueFormatOption: ValueFormatOption = (outputFormat == .verbose) ? .verbose : .default

    let attributesToFetch = determineAttributesToFetch(requestedAttributes: requestedAttributes, forMultiDefault: forMultiDefault, targetRole: targetRole, axElement: axElement)

    for attr in attributesToFetch {
        if attr == kAXParentAttribute { 
            result[kAXParentAttribute] = formatParentAttribute(axElement.parent, outputFormat: outputFormat, valueFormatOption: valueFormatOption)
            continue 
        } else if attr == kAXChildrenAttribute { 
            result[attr] = formatChildrenAttribute(axElement.children, outputFormat: outputFormat, valueFormatOption: valueFormatOption)
            continue
        } else if attr == kAXFocusedUIElementAttribute { 
            // extractedValue = formatFocusedUIElementAttribute(axElement.focusedElement, outputFormat: outputFormat, valueFormatOption: valueFormatOption)
            result[attr] = AnyCodable(formatFocusedUIElementAttribute(axElement.focusedElement, outputFormat: outputFormat, valueFormatOption: valueFormatOption))
            continue // Continue after direct assignment
        }

        let (directValue, wasHandledDirectly) = extractDirectPropertyValue(for: attr, from: axElement, outputFormat: outputFormat)
        var finalValueToStore: Any?

        if wasHandledDirectly {
            finalValueToStore = directValue
        } else {
            // For other attributes, use the generic attribute<T> or rawAttributeValue and then format
            let rawCFValue: CFTypeRef? = axElement.rawAttributeValue(named: attr)
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
        if let name = axElement.computedName { // USE AXElement.computedName
            result["ComputedName"] = AnyCodable(name)
        }
    }

    // Calculate IsClickable
    if result["IsClickable"] == nil { // Only if not already set
        let isButton = axElement.role == "AXButton"
        let hasPressAction = axElement.isActionSupported(kAXPressAction)
        if isButton || hasPressAction { result["IsClickable"] = AnyCodable(true) }
    }
    
    // Add descriptive path if in verbose mode (moved out of !forMultiDefault check)
    if outputFormat == .verbose && result["ComputedPath"] == nil {
        result["ComputedPath"] = AnyCodable(axElement.generatePathString())
    }
    // --- End of moved block ---

    if !forMultiDefault {
        populateActionNamesAttribute(for: axElement, result: &result)
        // The ComputedName, IsClickable, and ComputedPath (for verbose) are now handled above, outside this !forMultiDefault block.
    }
    return result
}

@MainActor
private func populateActionNamesAttribute(for axElement: AXElement, result: inout ElementAttributes) {
    // Use axElement.supportedActions directly in the result population
    if let currentActions = axElement.supportedActions, !currentActions.isEmpty {
        result[kAXActionNamesAttribute] = AnyCodable(currentActions)
    } else if result[kAXActionNamesAttribute] == nil && result[kAXActionsAttribute] == nil {
        // Fallback if axElement.supportedActions was nil or empty and not already populated
        let primaryActions: [String]? = axElement.attribute(AXAttribute<[String]>(kAXActionNamesAttribute))
        let fallbackActions: [String]? = axElement.attribute(AXAttribute<[String]>(kAXActionsAttribute))

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

// Helper function to format the parent attribute
@MainActor
private func formatParentAttribute(_ parent: AXElement?, outputFormat: OutputFormat, valueFormatOption: ValueFormatOption) -> AnyCodable {
    guard let parentAXElement = parent else {
        return AnyCodable(nil as String?) // Keep nil consistent with AnyCodable
    }

    if outputFormat == .text_content {
        return AnyCodable("AXElement: \(parentAXElement.role ?? "?Role")")
    } else {
        // Use new formatter for brief/verbose description
        return AnyCodable(parentAXElement.briefDescription(option: valueFormatOption))
    }
}

// Helper function to format the children attribute
@MainActor
private func formatChildrenAttribute(_ children: [AXElement]?, outputFormat: OutputFormat, valueFormatOption: ValueFormatOption) -> AnyCodable {
    guard let actualChildren = children, !actualChildren.isEmpty else {
        return AnyCodable("[]") // Empty array string representation
    }

    if outputFormat == .text_content {
        return AnyCodable("Array of \(actualChildren.count) AXElement(s)")
    } else if outputFormat == .verbose { // Verbose gets full summaries for children
        var childrenSummaries: [String] = [] // Store as strings now
        for childAXElement in actualChildren {
            childrenSummaries.append(childAXElement.briefDescription(option: .verbose))
        }
        return AnyCodable(childrenSummaries) 
    } else { // Smart or default
        return AnyCodable("<Collection of \(actualChildren.count) \(actualChildren.first?.role ?? "AXElement")s>")
    }
}

// Helper function to format the focused UI element attribute
@MainActor
private func formatFocusedUIElementAttribute(_ focusedElement: AXElement?, outputFormat: OutputFormat, valueFormatOption: ValueFormatOption) -> Any? {
    guard let focusedElem = focusedElement else { return nil }

    if outputFormat == .text_content {
        return "AXElement Focus: \(focusedElem.role ?? "?Role")"
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

// New helper function to get only computed/heuristic attributes for matching
@MainActor
internal func getComputedAttributes(for axElement: AXElement) -> ElementAttributes {
    var computedAttrs = ElementAttributes()

    if let name = axElement.computedName { // USE AXElement.computedName
        computedAttrs["ComputedName"] = AnyCodable(name)
    }

    let isButton = axElement.role == "AXButton"
    let hasPressAction = axElement.isActionSupported(kAXPressAction)
    if isButton || hasPressAction { computedAttrs["IsClickable"] = AnyCodable(true) }
    
    // Add other lightweight heuristic attributes here if needed in the future for matching

    return computedAttrs
}

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