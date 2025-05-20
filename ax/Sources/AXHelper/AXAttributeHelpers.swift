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
    summary[kAXRoleDescriptionAttribute] = AnyCodable(axElement.attribute(kAXRoleDescriptionAttribute) as String?)
    summary[kAXTitleAttribute] = AnyCodable(axElement.title)
    summary[kAXDescriptionAttribute] = AnyCodable(axElement.axDescription)
    summary[kAXIdentifierAttribute] = AnyCodable(axElement.attribute(kAXIdentifierAttribute) as String?)
    summary[kAXHelpAttribute] = AnyCodable(axElement.attribute(kAXHelpAttribute) as String?)
    // Path hint is custom, so directly use the string literal if kAXPathHintAttribute is not yet in AXConstants (it is now, but good practice)
    summary[kAXPathHintAttribute] = AnyCodable(axElement.attribute(kAXPathHintAttribute) as String?)
    return summary
}

@MainActor
public func getElementAttributes(_ axElement: AXElement, requestedAttributes: [String], forMultiDefault: Bool = false, targetRole: String? = nil, outputFormat: String = "smart") -> ElementAttributes { // Changed to AXElement
    var result = ElementAttributes()
    var attributesToFetch = requestedAttributes

    if forMultiDefault {
        attributesToFetch = [kAXRoleAttribute, kAXValueAttribute, kAXTitleAttribute, kAXIdentifierAttribute]
        // Use axElement.role here for targetRole comparison
        if let role = targetRole, role == "AXStaticText" { 
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
                if outputFormat == "verbose" {
                    result[kAXParentAttribute] = AnyCodable(getSingleElementSummary(parentAXElement))
                } else {
                    var simpleParentSummary = ElementAttributes()
                    simpleParentSummary[kAXRoleAttribute] = AnyCodable(parentAXElement.role)
                    simpleParentSummary[kAXTitleAttribute] = AnyCodable(parentAXElement.title)
                    result[kAXParentAttribute] = AnyCodable(simpleParentSummary)
                }
            } else {
                result[kAXParentAttribute] = AnyCodable(nil as ElementAttributes?) 
            }
            continue 
        } else if attr == kAXChildrenAttribute { 
            // Use the comprehensive axElement.children property
            if let actualChildren = axElement.children, !actualChildren.isEmpty {
                if outputFormat == "verbose" {
                    var childrenSummaries: [ElementAttributes] = []
                    for childAXElement in actualChildren {
                        childrenSummaries.append(getSingleElementSummary(childAXElement))
                    }
                    result[attr] = AnyCodable(childrenSummaries) 
                } else {
                     result[attr] = AnyCodable("Array of \(actualChildren.count) AXElement(s)")
                }
            } else {
                result[attr] = AnyCodable([]) // Or nil if preferred for no children
            }
            continue
        } else if attr == kAXFocusedUIElementAttribute { // Another example
            if let focusedElem = axElement.focusedElement {
                extractedValue = (outputFormat == "verbose") ? getSingleElementSummary(focusedElem) : "AXElement: \(focusedElem.role ?? "?Role")"
            } else { extractedValue = nil }
        }

        var extractedValue: Any? 
        // Prefer direct AXElement properties where available
        if attr == kAXRoleAttribute { extractedValue = axElement.role }
        else if attr == kAXSubroleAttribute { extractedValue = axElement.subrole }
        else if attr == kAXTitleAttribute { extractedValue = axElement.title }
        else if attr == kAXDescriptionAttribute { extractedValue = axElement.axDescription }
        else if attr == kAXEnabledAttribute { extractedValue = axElement.isEnabled }
        else if attr == kAXParentAttribute { // Example of handling specific AXElement-returning attribute
            if let parentElem = axElement.parent {
                extractedValue = (outputFormat == "verbose") ? getSingleElementSummary(parentElem) : "AXElement: \(parentElem.role ?? "?Role")"
            } else { extractedValue = nil }
        }
        else if attr == kAXFocusedUIElementAttribute { // Another example
            if let focusedElem = axElement.focusedElement {
                extractedValue = (outputFormat == "verbose") ? getSingleElementSummary(focusedElem) : "AXElement: \(focusedElem.role ?? "?Role")"
            } else { extractedValue = nil }
        }
        // For other attributes, use the generic attribute<T> method with common types
        else if let val: String = axElement.attribute(attr) { extractedValue = val }
        else if let val: Bool = axElement.attribute(attr) { extractedValue = val }
        else if let val: Int = axElement.attribute(attr) { extractedValue = val }
        else if let val: Double = axElement.attribute(attr) { extractedValue = val } // Added Double
        else if let val: NSNumber = axElement.attribute(attr) { extractedValue = val } // Added NSNumber
        else if let val: [String] = axElement.attribute(attr) { extractedValue = val }
        // For attributes that return [AXUIElement], they should be handled by specific properties like .children, .windows
        // or fetched as [AXUIElement] and then mapped if needed.
        // Avoid trying to cast directly to [AXElement] via axElement.attribute<[AXElement]>(attr)
        else if let uiElementArray: [AXUIElement] = axElement.attribute(attr) { // If an attribute returns an array of AXUIElements
            if outputFormat == "verbose" {
                extractedValue = uiElementArray.map { getSingleElementSummary(AXElement($0)) }
            } else {
                extractedValue = "Array of \(uiElementArray.count) AXUIElement(s) (raw)"
            }
        }
        else if let singleUIElement: AXUIElement = axElement.attribute(attr) { // If an attribute returns a single AXUIElement
             let wrappedElement = AXElement(singleUIElement)
            if outputFormat == "verbose" {
                extractedValue = getSingleElementSummary(wrappedElement)
            } else {
                extractedValue = "AXElement: \(wrappedElement.role ?? "?Role") - \(wrappedElement.title ?? "NoTitle") (wrapped from raw AXUIElement)"
            }
        }
        else if let val: [String: AnyCodable] = axElement.attribute(attr) { // For dictionaries like bounds
             extractedValue = val
        }
        else {
            // Fallback for raw CFTypeRef if direct casting via axElement.attribute fails
            let rawCFValue: CFTypeRef? = axElement.rawAttributeValue(named: attr) // Use rawAttributeValue
            if let raw = rawCFValue {
                let typeID = CFGetTypeID(raw)
                if typeID == AXUIElementGetTypeID() {
                    let wrapped = AXElement(raw as! AXUIElement)
                    extractedValue = (outputFormat == "verbose") ? getSingleElementSummary(wrapped) : "AXElement (raw): \(wrapped.role ?? "?Role")"
                } else if typeID == AXValueGetTypeID() {
                    if let axVal = raw as? AXValue, let valType = AXValueGetTypeIfPresent(axVal) { // Safe getter for AXValueType
                        extractedValue = "AXValue (type: \(stringFromAXValueType(valType)))"
                    } else {
                        extractedValue = "AXValue (unknown type)"
                    }
                } else {
                    if let desc = CFCopyTypeIDDescription(typeID) {
                        extractedValue = "CFType: \(desc as String)"
                    } else {
                        extractedValue = "CFType: Unknown (ID: \(typeID))"
                    }
                }
            } else {
                extractedValue = nil // Or some placeholder like "Not fetched/Not supported"
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
        // Use axElement.supportedActions directly in the result population
        if let currentActions = axElement.supportedActions, !currentActions.isEmpty {
            result[kAXActionNamesAttribute] = AnyCodable(currentActions)
        } else if result[kAXActionNamesAttribute] == nil && result[kAXActionsAttribute] == nil {
            // Fallback if axElement.supportedActions was nil or empty and not already populated
            if let actions: [String] = axElement.attribute(kAXActionNamesAttribute) ?? axElement.attribute(kAXActionsAttribute) {
               if !actions.isEmpty { result[kAXActionNamesAttribute] = AnyCodable(actions) }
               else { result[kAXActionNamesAttribute] = AnyCodable("Not available (empty list)") }
            } else {
               result[kAXActionNamesAttribute] = AnyCodable("Not available")
            }
        }

        var computedName: String? = nil
        if let title = axElement.title, !title.isEmpty, title != "Not available" { computedName = title }
        else if let value: String = axElement.attribute(kAXValueAttribute), !value.isEmpty, value != "Not available" { computedName = value }
        else if let desc = axElement.axDescription, !desc.isEmpty, desc != "Not available" { computedName = desc }
        else if let help: String = axElement.attribute(kAXHelpAttribute), !help.isEmpty, help != "Not available" { computedName = help }
        else if let phValue: String = axElement.attribute(kAXPlaceholderValueAttribute), !phValue.isEmpty, phValue != "Not available" { computedName = phValue }
        else if let roleDesc: String = axElement.attribute(kAXRoleDescriptionAttribute), !roleDesc.isEmpty, roleDesc != "Not available" {
            computedName = "\(roleDesc) (\(axElement.role ?? "Element"))"
        }
        if let name = computedName { result["ComputedName"] = AnyCodable(name) }

        let isButton = axElement.role == "AXButton"
        // Use axElement.isActionSupported if available, or check availableActions array
        let hasPressAction = axElement.isActionSupported(kAXPressAction) // More direct way
        if isButton || hasPressAction { result["IsClickable"] = AnyCodable(true) }
    }
    return result
}

// Any other attribute-specific helper functions could go here in the future. 