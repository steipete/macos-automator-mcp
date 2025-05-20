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
public func getElementAttributes(_ axElement: AXElement, requestedAttributes: [String], forMultiDefault: Bool = false, targetRole: String? = nil, outputFormat: OutputFormat = .smart) -> ElementAttributes { // Changed to enum type
    var result = ElementAttributes()
    var attributesToFetch = requestedAttributes
    var extractedValue: Any? // MOVED and DECLARED HERE

    // Determine the actual format option for the new formatters
    let valueFormatOption: ValueFormatOption = (outputFormat == .verbose) ? .verbose : .default

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

    for attr in attributesToFetch {
        if attr == kAXParentAttribute { 
            if let parentAXElement = axElement.parent { // Use AXElement.parent
                if outputFormat == .text_content {
                    result[kAXParentAttribute] = AnyCodable("AXElement: \(parentAXElement.role ?? "?Role")")
                } else {
                    // Use new formatter for brief/verbose description
                    result[kAXParentAttribute] = AnyCodable(parentAXElement.briefDescription(option: valueFormatOption))
                }
            } else {
                result[kAXParentAttribute] = AnyCodable(nil as String?) // Keep nil consistent with AnyCodable
            }
            continue 
        } else if attr == kAXChildrenAttribute { 
            if let actualChildren = axElement.children, !actualChildren.isEmpty {
                if outputFormat == .text_content {
                     result[attr] = AnyCodable("Array of \(actualChildren.count) AXElement(s)")
                } else if outputFormat == .verbose { // Verbose gets full summaries for children
                    var childrenSummaries: [String] = [] // Store as strings now
                    for childAXElement in actualChildren {
                        // For children in verbose mode, maybe a slightly less verbose summary than full getElementAttributes recursion
                        childrenSummaries.append(childAXElement.briefDescription(option: .verbose))
                    }
                    result[attr] = AnyCodable(childrenSummaries) 
                } else { // Smart or default
                    result[attr] = AnyCodable("<Collection of \(actualChildren.count) \(actualChildren.first?.role ?? "AXElement")s>")
                }
            } else {
                result[attr] = AnyCodable("[]") // Empty array string representation
            }
            continue
        } else if attr == kAXFocusedUIElementAttribute { 
            if let focusedElem = axElement.focusedElement {
                if outputFormat == .text_content {
                    extractedValue = "AXElement Focus: \(focusedElem.role ?? "?Role")"
                } else {
                    extractedValue = focusedElem.briefDescription(option: valueFormatOption)
                }
            } else { extractedValue = nil }
        }

        // This block for pathHint should be fine, as pathHint is already a String?
        if attr == kAXPathHintAttribute {
            extractedValue = axElement.attribute(AXAttribute<String>(kAXPathHintAttribute))
        }
        // Prefer direct AXElement properties where available
        else if attr == kAXRoleAttribute { extractedValue = axElement.role }
        else if attr == kAXSubroleAttribute { extractedValue = axElement.subrole }
        else if attr == kAXTitleAttribute { extractedValue = axElement.title }
        else if attr == kAXDescriptionAttribute { extractedValue = axElement.axDescription }
        else if attr == kAXEnabledAttribute { 
            if outputFormat == .text_content {
                extractedValue = axElement.isEnabled?.description ?? kAXNotAvailableString
            } else {
                extractedValue = axElement.isEnabled
            }
        }
        else if attr == kAXFocusedAttribute {
            if outputFormat == .text_content {
                extractedValue = axElement.isFocused?.description ?? kAXNotAvailableString
            } else {
                extractedValue = axElement.isFocused
            }
        }
        else if attr == kAXHiddenAttribute {
            if outputFormat == .text_content {
                extractedValue = axElement.isHidden?.description ?? kAXNotAvailableString
            } else {
                extractedValue = axElement.isHidden
            }
        }
        else if attr == "IsIgnored" {
            if outputFormat == .text_content {
                extractedValue = axElement.isIgnored.description
            } else {
                extractedValue = axElement.isIgnored
            }
        }
        else if attr == "PID" {
            if outputFormat == .text_content {
                extractedValue = axElement.pid?.description ?? kAXNotAvailableString
            } else {
                extractedValue = axElement.pid
            }
        }
        else if attr == kAXElementBusyAttribute {
            if outputFormat == .text_content {
                extractedValue = axElement.isElementBusy?.description ?? kAXNotAvailableString
            } else {
                extractedValue = axElement.isElementBusy
            }
        }
        // For other attributes, use the generic attribute<T> or rawAttributeValue and then format
        else {
            let rawCFValue: CFTypeRef? = axElement.rawAttributeValue(named: attr)
            if outputFormat == .text_content {
                // Attempt to get a string representation for text_content
                if let raw = rawCFValue {
                    let typeID = CFGetTypeID(raw)
                    if typeID == CFStringGetTypeID() { extractedValue = (raw as! String) }
                    else if typeID == CFAttributedStringGetTypeID() { extractedValue = (raw as! NSAttributedString).string }
                    else if typeID == AXValueGetTypeID() {
                        let axVal = raw as! AXValue
                        // For text_content, use formatAXValue to get a string representation.
                        // This is simpler than trying to manually extract C strings for specific AXValueTypes.
                        extractedValue = formatAXValue(axVal, option: .default)
                    } else if typeID == CFNumberGetTypeID() { extractedValue = (raw as! NSNumber).stringValue }
                    else if typeID == CFBooleanGetTypeID() { extractedValue = CFBooleanGetValue((raw as! CFBoolean)) ? "true" : "false" }
                    else { extractedValue = "<\(CFCopyTypeIDDescription(typeID) as String? ?? "ComplexType")>" }
                } else {
                    extractedValue = "<Not directly string representable>"
                }
            } else { // For "smart" or "verbose" output, use the new formatter
                 extractedValue = formatCFTypeRef(rawCFValue, option: valueFormatOption)
            }
        }
        
        let finalValueToStore = extractedValue
        // Smart filtering: if it's a string and empty OR specific unhelpful strings, skip it for 'smart' output.
        if outputFormat == .smart {
            if let strVal = finalValueToStore as? String,
               (strVal.isEmpty || strVal == "<nil>" || strVal == "AXValue (Illegal)" || strVal.contains("Unknown CFType")) {
                continue 
            }
        }
        result[attr] = AnyCodable(finalValueToStore)
    }
    
    // Special handling for json_string output format
    if outputFormat == .json_string {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // Or .sortedKeys for deterministic output if needed
        do {
            let jsonData = try encoder.encode(result) // result is [String: AnyCodable]
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // Return a dictionary containing the JSON string under a specific key
                return ["json_representation": AnyCodable(jsonString)] 
            } else {
                return ["error": AnyCodable("Failed to convert encoded JSON data to string")]
            }
        } catch {
            return ["error": AnyCodable("Failed to encode attributes to JSON: \(error.localizedDescription)")]
        }
    }

    if !forMultiDefault {
        // Use axElement.supportedActions directly in the result population
        if let currentActions = axElement.supportedActions, !currentActions.isEmpty {
            result[kAXActionNamesAttribute] = AnyCodable(currentActions)
        } else if result[kAXActionNamesAttribute] == nil && result[kAXActionsAttribute] == nil {
            // Fallback if axElement.supportedActions was nil or empty and not already populated
            // Ensure to wrap with AXAttribute<[String]>
            let primaryActions: [String]? = axElement.attribute(AXAttribute<[String]>(kAXActionNamesAttribute))
            let fallbackActions: [String]? = axElement.attribute(AXAttribute<[String]>(kAXActionsAttribute))

            if let actions = primaryActions ?? fallbackActions, !actions.isEmpty {
               result[kAXActionNamesAttribute] = AnyCodable(actions)
            } else if primaryActions != nil || fallbackActions != nil { // If either was attempted and resulted in empty or nil
               result[kAXActionNamesAttribute] = AnyCodable("\(kAXNotAvailableString) (empty list)")
            } else {
               result[kAXActionNamesAttribute] = AnyCodable(kAXNotAvailableString)
            }
        }

        var computedName: String? = nil
        if let title = axElement.title, !title.isEmpty, title != kAXNotAvailableString { computedName = title }
        else if let value: String = axElement.attribute(AXAttribute<String>(kAXValueAttribute)), !value.isEmpty, value != kAXNotAvailableString { computedName = value }
        else if let desc = axElement.axDescription, !desc.isEmpty, desc != kAXNotAvailableString { computedName = desc }
        else if let help: String = axElement.attribute(AXAttribute<String>(kAXHelpAttribute)), !help.isEmpty, help != kAXNotAvailableString { computedName = help }
        else if let phValue: String = axElement.attribute(AXAttribute<String>(kAXPlaceholderValueAttribute)), !phValue.isEmpty, phValue != kAXNotAvailableString { computedName = phValue }
        else if let roleDesc: String = axElement.attribute(AXAttribute<String>(kAXRoleDescriptionAttribute)), !roleDesc.isEmpty, roleDesc != kAXNotAvailableString {
            computedName = "\(roleDesc) (\(axElement.role ?? "Element"))"
        }
        if let name = computedName { result["ComputedName"] = AnyCodable(name) }

        let isButton = axElement.role == "AXButton"
        // Use axElement.isActionSupported if available, or check availableActions array
        let hasPressAction = axElement.isActionSupported(kAXPressAction) // More direct way
        if isButton || hasPressAction { result["IsClickable"] = AnyCodable(true) }
        
        // Add descriptive path if in verbose mode
        if outputFormat == .verbose {
            result["ComputedPath"] = AnyCodable(axElement.generatePathString())
        }
    }
    return result
}

// New helper function to get only computed/heuristic attributes for matching
@MainActor
internal func getComputedAttributes(for axElement: AXElement) -> ElementAttributes {
    var computedAttrs = ElementAttributes()

    var computedName: String? = nil
    if let title = axElement.title, !title.isEmpty, title != kAXNotAvailableString { computedName = title }
    else if let value: String = axElement.attribute(AXAttribute<String>(kAXValueAttribute)), !value.isEmpty, value != kAXNotAvailableString { computedName = value }
    else if let desc = axElement.axDescription, !desc.isEmpty, desc != kAXNotAvailableString { computedName = desc }
    else if let help: String = axElement.attribute(AXAttribute<String>(kAXHelpAttribute)), !help.isEmpty, help != kAXNotAvailableString { computedName = help }
    else if let phValue: String = axElement.attribute(AXAttribute<String>(kAXPlaceholderValueAttribute)), !phValue.isEmpty, phValue != kAXNotAvailableString { computedName = phValue }
    else if let roleDesc: String = axElement.attribute(AXAttribute<String>(kAXRoleDescriptionAttribute)), !roleDesc.isEmpty, roleDesc != kAXNotAvailableString {
        computedName = "\(roleDesc) (\(axElement.role ?? "Element"))"
    }
    if let name = computedName { computedAttrs["ComputedName"] = AnyCodable(name) }

    let isButton = axElement.role == "AXButton"
    let hasPressAction = axElement.isActionSupported(kAXPressAction)
    if isButton || hasPressAction { computedAttrs["IsClickable"] = AnyCodable(true) }
    
    // Add other lightweight heuristic attributes here if needed in the future for matching

    return computedAttrs
}

// Any other attribute-specific helper functions could go here in the future. 