// AXAttributeHelpers.swift - Contains functions for fetching and formatting element attributes

import Foundation
import ApplicationServices // For AXUIElement related types
import CoreGraphics // For potential future use with geometry types from attributes

// Note: This file assumes AXModels (for ElementAttributes, AnyCodable), 
// AXLogging (for debug), AXConstants, and AXUtils (for axValue) are available in the same module.

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
        if attr == kAXParentAttribute { // Special handling for AXParent
            if let parentElement: AXUIElement = axValue(of: element, attr: kAXParentAttribute) {
                var parentAttrs = ElementAttributes()
                parentAttrs[kAXRoleAttribute] = AnyCodable(axValue(of: parentElement, attr: kAXRoleAttribute) as String?)
                parentAttrs[kAXSubroleAttribute] = AnyCodable(axValue(of: parentElement, attr: kAXSubroleAttribute) as String?)
                parentAttrs[kAXRoleDescriptionAttribute] = AnyCodable(axValue(of: parentElement, attr: kAXRoleDescriptionAttribute) as String?)
                parentAttrs[kAXTitleAttribute] = AnyCodable(axValue(of: parentElement, attr: kAXTitleAttribute) as String?)
                parentAttrs[kAXDescriptionAttribute] = AnyCodable(axValue(of: parentElement, attr: kAXDescriptionAttribute) as String?)
                parentAttrs[kAXIdentifierAttribute] = AnyCodable(axValue(of: parentElement, attr: kAXIdentifierAttribute) as String?)
                parentAttrs[kAXHelpAttribute] = AnyCodable(axValue(of: parentElement, attr: kAXHelpAttribute) as String?)
                // Fetch and include the parent's AXPathHint as a String
                parentAttrs["AXPathHint"] = AnyCodable(axValue(of: parentElement, attr: "AXPathHint") as String?)
                result[kAXParentAttribute] = AnyCodable(parentAttrs)
            } else {
                result[kAXParentAttribute] = AnyCodable(nil as ElementAttributes?) // Provide type hint for nil
            }
            continue // Move to next attribute in attributesToFetch
        } else if attr == kAXChildrenAttribute { // Special handling for AXChildren
            var children: [AXUIElement]? = axValue(of: element, attr: kAXChildrenAttribute)

            if children == nil || children!.isEmpty {
                // If standard AXChildren is empty or nil, try alternative attributes
                let alternativeChildrenAttributes = [
                    kAXVisibleChildrenAttribute, "AXWebAreaChildren", "AXHTMLContent", 
                    "AXARIADOMChildren", "AXDOMChildren", "AXApplicationNavigation", 
                    "AXApplicationElements", "AXContents", "AXBodyArea", "AXDocumentContent", 
                    "AXWebPageContent", "AXAttributedString", "AXSplitGroupContents",
                    "AXLayoutAreaChildren", "AXGroupChildren"
                    // kAXTabsAttribute, kAXSelectedChildrenAttribute, kAXRowsAttribute, kAXColumnsAttribute are usually more specific
                ]
                for altAttr in alternativeChildrenAttributes {
                    if let altChildren: [AXUIElement] = axValue(of: element, attr: altAttr), !altChildren.isEmpty {
                        children = altChildren
                        debug("getElementAttributes: Used alternative children attribute '\(altAttr)' for element.")
                        break
                    }
                }
            }
            
            if let actualChildren = children {
                // For now, just indicate count or a placeholder if children exist, to avoid verbose output by default.
                // The search/collectAll functions will traverse them.
                // If specific child details are needed via getElementAttributes, it might require a deeper representation.
                if outputFormat == "verbose" {
                    var childrenSummaries: [ElementAttributes] = []
                    for childElement in actualChildren {
                        var childSummary = ElementAttributes()
                        // Basic, usually safe attributes for a summary
                        childSummary[kAXRoleAttribute] = AnyCodable(axValue(of: childElement, attr: kAXRoleAttribute) as String?)
                        childSummary[kAXSubroleAttribute] = AnyCodable(axValue(of: childElement, attr: kAXSubroleAttribute) as String?)
                        childSummary[kAXRoleDescriptionAttribute] = AnyCodable(axValue(of: childElement, attr: kAXRoleDescriptionAttribute) as String?)
                        childSummary[kAXTitleAttribute] = AnyCodable(axValue(of: childElement, attr: kAXTitleAttribute) as String?)
                        childSummary[kAXDescriptionAttribute] = AnyCodable(axValue(of: childElement, attr: kAXDescriptionAttribute) as String?)
                        childSummary[kAXIdentifierAttribute] = AnyCodable(axValue(of: childElement, attr: kAXIdentifierAttribute) as String?)
                        childSummary[kAXHelpAttribute] = AnyCodable(axValue(of: childElement, attr: kAXHelpAttribute) as String?)
                        
                        // Replace temporary file logging with a call to the enhanced debug() function
                        debug("Processing child element: \(childElement) for verbose output.")
                        
                        childrenSummaries.append(childSummary)
                    }
                    result[attr] = AnyCodable(childrenSummaries) 
                } else {
                     result[attr] = AnyCodable("Array of \(actualChildren.count) UIElement(s)")
                }

            } else {
                result[attr] = AnyCodable([]) // Represent as empty array if no children found through any means
            }
            continue
        }

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
                    let axValueTyped = raw as! AXValue
                    extractedValue = "AXValue (type: \(stringFromAXValueType(AXValueGetType(axValueTyped))))"
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

// Any other attribute-specific helper functions could go here in the future. 