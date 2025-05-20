import Foundation
import ApplicationServices // For AXUIElement etc., kAXSetValueAction
import AppKit // For NSWorkspace (indirectly via getApplicationElement)

// Note: Relies on many helpers from other modules (AXElement, AXSearch, AXModels, AXValueParser for createCFTypeRefFromString etc.)

@MainActor
func handlePerform(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) throws -> PerformResponse {
    let appIdentifier = cmd.application ?? "focused"
    debug("Handling perform_action for app: \(appIdentifier), action: \(cmd.action ?? "nil")")

    guard let appAXElement = applicationElement(for: appIdentifier) else {
        return PerformResponse(command_id: cmd.command_id, success: false, error: "Application not found: \(appIdentifier)", debug_logs: collectedDebugLogs)
    }
    guard let actionToPerform = cmd.action, !actionToPerform.isEmpty else {
        return PerformResponse(command_id: cmd.command_id, success: false, error: "Action not specified", debug_logs: collectedDebugLogs)
    }
    guard let locator = cmd.locator else {
        var elementForDirectAction = appAXElement
        if let pathHint = cmd.path_hint, !pathHint.isEmpty {
            debug("No locator for Perform. Navigating with path_hint: \(pathHint.joined(separator: " -> ")) for action \(actionToPerform)")
            guard let navigatedAXElement = navigateToElement(from: appAXElement, pathHint: pathHint) else {
                return PerformResponse(command_id: cmd.command_id, success: false, error: "Element for action (no locator) not found via path_hint: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
            }
            elementForDirectAction = navigatedAXElement
        }
        debug("No locator. Performing action '\(actionToPerform)' directly on element: \(elementForDirectAction.underlyingElement)")
        return try performActionOnElement(axElement: elementForDirectAction, action: actionToPerform, cmd: cmd)
    }

    var baseAXElementForSearch = appAXElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        debug("PerformAction: Main path_hint \(pathHint.joined(separator: " -> ")) present. Navigating to establish base for search.")
        guard let navigatedBaseAX = navigateToElement(from: appAXElement, pathHint: pathHint) else {
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Base element for search (from main path_hint) not found: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
        baseAXElementForSearch = navigatedBaseAX
    }
    if let rootPathHint = locator.root_element_path_hint, !rootPathHint.isEmpty {
        debug("PerformAction: locator.root_element_path_hint \(rootPathHint.joined(separator: " -> ")) overrides main path_hint for search base. Navigating from app root.")
        guard let newBaseAXFromLocatorRoot = navigateToElement(from: appAXElement, pathHint: rootPathHint) else {
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Search base from locator.root_element_path_hint not found: \(rootPathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
        baseAXElementForSearch = newBaseAXFromLocatorRoot
    }
    debug("PerformAction: Searching for action element within: \(baseAXElementForSearch.underlyingElement) using locator criteria: \(locator.criteria)")
        
    let actionRequiredForInitialSearch: String?
    if actionToPerform == kAXSetValueAction || actionToPerform == kAXPressAction { 
        actionRequiredForInitialSearch = nil 
    } else {
        actionRequiredForInitialSearch = actionToPerform
    }

    var targetAXElement: AXElement? = search(axElement: baseAXElementForSearch, locator: locator, requireAction: actionRequiredForInitialSearch, maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_SEARCH, isDebugLoggingEnabled: isDebugLoggingEnabled)

    // Smart Search / Fuzzy Find for perform_action
    if targetAXElement == nil || 
       (actionToPerform != kAXSetValueAction && 
        actionToPerform != kAXPressAction && 
        targetAXElement?.isActionSupported(actionToPerform) == false) {
        
        debug("PerformAction: Initial search failed or element found does not support action '\(actionToPerform)'. Attempting smart search...")
        
        var smartLocatorCriteria = locator.criteria
        var useComputedNameForSmartSearch = false

        if let titleFromCriteria = smartLocatorCriteria[kAXTitleAttribute] ?? smartLocatorCriteria["AXTitle"] {
            smartLocatorCriteria["computed_name_contains"] = titleFromCriteria // Try contains first
            smartLocatorCriteria.removeValue(forKey: kAXTitleAttribute)
            smartLocatorCriteria.removeValue(forKey: "AXTitle")
            useComputedNameForSmartSearch = true
            debug("PerformAction (Smart): Using title '\(titleFromCriteria)' for computed_name_contains.")
        } else if let idFromCriteria = smartLocatorCriteria[kAXIdentifierAttribute] ?? smartLocatorCriteria["AXIdentifier"] {
            smartLocatorCriteria["computed_name_contains"] = idFromCriteria
            smartLocatorCriteria.removeValue(forKey: kAXIdentifierAttribute)
            smartLocatorCriteria.removeValue(forKey: "AXIdentifier")
            useComputedNameForSmartSearch = true
            debug("PerformAction (Smart): No title, using ID '\(idFromCriteria)' for computed_name_contains.")
        }

        if useComputedNameForSmartSearch || (smartLocatorCriteria[kAXRoleAttribute] != nil || smartLocatorCriteria["AXRole"] != nil) {
            let smartSearchLocator = Locator(
                match_all: locator.match_all,
                criteria: smartLocatorCriteria, 
                root_element_path_hint: nil, 
                requireAction: actionToPerform, 
                computed_name_equals: nil, 
                computed_name_contains: smartLocatorCriteria["computed_name_contains"]
            )

            var foundCollectedElements: [AXElement] = []
            var processingSet = Set<AXElement>()
            let smartSearchMaxDepth = 3 

            debug("PerformAction (Smart): Collecting candidates with smart locator: \(smartSearchLocator.criteria), requireAction: '\(actionToPerform)', depth: \(smartSearchMaxDepth)")
            collectAll(
                appAXElement: appAXElement, 
                locator: smartSearchLocator, 
                currentAXElement: baseAXElementForSearch, 
                depth: 0, 
                maxDepth: smartSearchMaxDepth, 
                maxElements: 5, 
                currentPath: [], 
                elementsBeingProcessed: &processingSet, 
                foundElements: &foundCollectedElements,
                isDebugLoggingEnabled: isDebugLoggingEnabled
            )

            let trulySupportingElements = foundCollectedElements.filter { $0.isActionSupported(actionToPerform) }

            if trulySupportingElements.count == 1 {
                targetAXElement = trulySupportingElements.first
                debug("PerformAction (Smart): Found unique element via smart search: \(targetAXElement?.briefDescription(option: .verbose) ?? "nil")")
            } else if trulySupportingElements.count > 1 {
                debug("PerformAction (Smart): Found \(trulySupportingElements.count) elements via smart search. Ambiguous. Original error will be returned.")
            } else {
                debug("PerformAction (Smart): No elements found via smart search that support the action.")
            }
        } else {
            debug("PerformAction (Smart): Not enough criteria (no title/ID for computed_name and no role) to attempt smart search.")
        }
    }
    
    guard let finalTargetAXElement = targetAXElement else {
        return PerformResponse(command_id: cmd.command_id, success: false, error: "Target element for action '\(actionToPerform)' not found with given locator and path hints, even after smart search.", debug_logs: collectedDebugLogs)
    }
    
    if actionToPerform != kAXSetValueAction && !finalTargetAXElement.isActionSupported(actionToPerform) {
         let supportedActions: [String]? = finalTargetAXElement.supportedActions
         return PerformResponse(command_id: cmd.command_id, success: false, error: "Final target element for action '\(actionToPerform)' does not support it. Supported: \(supportedActions?.joined(separator: ", ") ?? "none")", debug_logs: collectedDebugLogs)
    }

    return try performActionOnElement(axElement: finalTargetAXElement, action: actionToPerform, cmd: cmd)
}

@MainActor
private func performActionOnElement(axElement: AXElement, action: String, cmd: CommandEnvelope) throws -> PerformResponse {
    debug("Final target element for action '\(action)': \(axElement.underlyingElement)")
    if action == kAXSetValueAction {
        guard let valueToSetString = cmd.value else {
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Value not provided for AXSetValue action", debug_logs: collectedDebugLogs)
        }
        
        let attributeToSet = cmd.attribute_to_set?.isEmpty == false ? cmd.attribute_to_set! : kAXValueAttribute
        debug("AXSetValue: Attempting to set attribute '\(attributeToSet)' to value '\(valueToSetString)' on \(String(describing: axElement.underlyingElement))")

        do {
            guard let cfValueToSet = try createCFTypeRefFromString(stringValue: valueToSetString, forElement: axElement, attributeName: attributeToSet) else {
                 return PerformResponse(command_id: cmd.command_id, success: false, error: "Could not parse value '\(valueToSetString)' for attribute '\(attributeToSet)'. Parsing returned nil.", debug_logs: collectedDebugLogs)
            }
            defer { /* _ = Unmanaged.passRetained(cfValueToSet).autorelease() */ } 
            
            let axErr = AXUIElementSetAttributeValue(axElement.underlyingElement, attributeToSet as CFString, cfValueToSet)
            if axErr == .success {
                return PerformResponse(command_id: cmd.command_id, success: true, error: nil, debug_logs: collectedDebugLogs)
            } else {
                let errorDescription = "AXUIElementSetAttributeValue failed for attribute '\(attributeToSet)'. Error: \(axErr.rawValue) (\(axErrorToString(axErr)))"
                debug(errorDescription)
                throw AXToolError.actionFailed(errorDescription, axErr)
            }
        } catch let error as AXToolError {
            let errorMessage = "Error during AXSetValue for attribute '\(attributeToSet)': \(error.description)"
            debug(errorMessage)
            throw error
        } catch {
            let errorMessage = "Unexpected Swift error preparing value for '\(attributeToSet)': \(error.localizedDescription)"
            debug(errorMessage)
            throw AXToolError.genericError(errorMessage)
        }
    } else {
        if !axElement.isActionSupported(action) {
            if action == kAXPressAction && cmd.perform_action_on_child_if_needed == true {
                debug("Action '\(action)' not supported on element \(axElement.briefDescription()). Trying on children as perform_action_on_child_if_needed is true.")
                if let children = axElement.children, !children.isEmpty {
                    for child in children {
                        if child.isActionSupported(kAXPressAction) {
                            debug("Attempting \(kAXPressAction) on child: \(child.briefDescription())")
                            do {
                                try child.performAction(kAXPressAction)
                                debug("Successfully performed \\(kAXPressAction) on child: \\(child.briefDescription())")
                                return PerformResponse(command_id: cmd.command_id, success: true, error: nil, debug_logs: collectedDebugLogs)
                            } catch AXToolError.actionFailed(let desc, let axErr) {
                                debug("Child action \\(kAXPressAction) failed on \\(child.briefDescription()): \\(desc), AXErr: \\(axErr?.rawValue ?? -1)")
                            } catch {
                                debug("Child action \\(kAXPressAction) failed on \\(child.briefDescription()) with unexpected error: \\(error.localizedDescription)")
                            }
                        }
                    }
                    debug("No child successfully handled \(kAXPressAction).")
                    return PerformResponse(command_id: cmd.command_id, success: false, error: "Action '\(action)' not supported on element, and no child could perform it.", debug_logs: collectedDebugLogs)
                } else {
                    debug("Element has no children to attempt best-effort \(kAXPressAction).")
                    return PerformResponse(command_id: cmd.command_id, success: false, error: "Action '\(action)' not supported, and no children to attempt alternative press.", debug_logs: collectedDebugLogs)
                }
            }
            let supportedActions: [String]? = axElement.supportedActions
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Action '\(action)' not supported. Supported: \(supportedActions?.joined(separator: ", ") ?? "none")", debug_logs: collectedDebugLogs)
        }
        
        debug("Performing action '\(action)' on \(axElement.underlyingElement)")
        try axElement.performAction(action) 
        return PerformResponse(command_id: cmd.command_id, success: true, error: nil, debug_logs: collectedDebugLogs)
    }
} 
