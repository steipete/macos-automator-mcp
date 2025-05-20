import Foundation
import ApplicationServices // For AXUIElement etc., kAXSetValueAction
import AppKit // For NSWorkspace (indirectly via getApplicationElement)

// Note: Relies on many helpers from other modules (Element, ElementSearch, Models, ValueParser for createCFTypeRefFromString etc.)

@MainActor
public func handlePerform(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) throws -> PerformResponse {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }

    dLog("Handling perform_action for app: \(cmd.application ?? "focused"), action: \(cmd.action ?? "nil")")

    // Calls to external functions like applicationElement, navigateToElement, search, collectAll
    // will use their original signatures for now. Their own debug logs won't be captured here yet.
    guard let appElement = applicationElement(for: cmd.application ?? "focused", isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
        // If applicationElement itself logged to a global store, that won't be in currentDebugLogs.
        // For now, this is acceptable as an intermediate step.
        return PerformResponse(command_id: cmd.command_id, success: false, error: "Application not found: \(cmd.application ?? "focused")", debug_logs: currentDebugLogs)
    }
    guard let actionToPerform = cmd.action, !actionToPerform.isEmpty else {
        return PerformResponse(command_id: cmd.command_id, success: false, error: "Action not specified", debug_logs: currentDebugLogs)
    }
    guard let locator = cmd.locator else {
        var elementForDirectAction = appElement
        if let pathHint = cmd.path_hint, !pathHint.isEmpty {
            dLog("No locator for Perform. Navigating with path_hint: \(pathHint.joined(separator: " -> ")) for action \(actionToPerform)")
            guard let navigatedElement = navigateToElement(from: appElement, pathHint: pathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
                return PerformResponse(command_id: cmd.command_id, success: false, error: "Element for action (no locator) not found via path_hint: \(pathHint.joined(separator: " -> "))", debug_logs: currentDebugLogs)
            }
            elementForDirectAction = navigatedElement
        }
        let briefDesc = elementForDirectAction.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        dLog("No locator. Performing action '\(actionToPerform)' directly on element: \(briefDesc)")
        // performActionOnElement is a private helper in this file, so it CAN use currentDebugLogs.
        return try performActionOnElement(element: elementForDirectAction, action: actionToPerform, cmd: cmd, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
    }

    var baseElementForSearch = appElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        dLog("PerformAction: Main path_hint \(pathHint.joined(separator: " -> ")) present. Navigating to establish base for search.")
        guard let navigatedBase = navigateToElement(from: appElement, pathHint: pathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Base element for search (from main path_hint) not found: \(pathHint.joined(separator: " -> "))", debug_logs: currentDebugLogs)
        }
        baseElementForSearch = navigatedBase
    }
    if let rootPathHint = locator.root_element_path_hint, !rootPathHint.isEmpty {
        dLog("PerformAction: locator.root_element_path_hint \(rootPathHint.joined(separator: " -> ")) overrides main path_hint for search base. Navigating from app root.")
        guard let newBaseFromLocatorRoot = navigateToElement(from: appElement, pathHint: rootPathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Search base from locator.root_element_path_hint not found: \(rootPathHint.joined(separator: " -> "))", debug_logs: currentDebugLogs)
        }
        baseElementForSearch = newBaseFromLocatorRoot
    }
    let baseBriefDesc = baseElementForSearch.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
    dLog("PerformAction: Searching for action element within: \(baseBriefDesc) using locator criteria: \(locator.criteria)")
        
    let actionRequiredForInitialSearch: String?
    if actionToPerform == kAXSetValueAction || actionToPerform == kAXPressAction { 
        actionRequiredForInitialSearch = nil 
    } else {
        actionRequiredForInitialSearch = actionToPerform
    }

    // search() is external, call original signature. Its logs won't be in currentDebugLogs yet.
    var targetElement: Element? = search(element: baseElementForSearch, locator: locator, requireAction: actionRequiredForInitialSearch, maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_SEARCH, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)

    if targetElement == nil || 
       (actionToPerform != kAXSetValueAction && 
        actionToPerform != kAXPressAction && 
        targetElement?.isActionSupported(actionToPerform, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) == false) {
        
        dLog("PerformAction: Initial search failed or element found does not support action '\(actionToPerform)'. Attempting smart search...")
        var smartLocatorCriteria = locator.criteria
        var useComputedNameForSmartSearch = false

        if let titleFromCriteria = smartLocatorCriteria[kAXTitleAttribute] ?? smartLocatorCriteria["AXTitle"] {
            smartLocatorCriteria["computed_name_contains"] = titleFromCriteria
            smartLocatorCriteria.removeValue(forKey: kAXTitleAttribute); smartLocatorCriteria.removeValue(forKey: "AXTitle")
            useComputedNameForSmartSearch = true
            dLog("PerformAction (Smart): Using title '\(titleFromCriteria)' for computed_name_contains.")
        } else if let idFromCriteria = smartLocatorCriteria[kAXIdentifierAttribute] ?? smartLocatorCriteria["AXIdentifier"] {
            smartLocatorCriteria["computed_name_contains"] = idFromCriteria
            smartLocatorCriteria.removeValue(forKey: kAXIdentifierAttribute); smartLocatorCriteria.removeValue(forKey: "AXIdentifier")
            useComputedNameForSmartSearch = true
            dLog("PerformAction (Smart): No title, using ID '\(idFromCriteria)' for computed_name_contains.")
        }

        if useComputedNameForSmartSearch || (smartLocatorCriteria[kAXRoleAttribute] != nil || smartLocatorCriteria["AXRole"] != nil) {
            let smartSearchLocator = Locator(
                match_all: locator.match_all, criteria: smartLocatorCriteria, 
                root_element_path_hint: nil, requireAction: actionToPerform, 
                computed_name_equals: nil, computed_name_contains: smartLocatorCriteria["computed_name_contains"]
            )
            var foundCollectedElements: [Element] = []
            var processingSet = Set<Element>()
            dLog("PerformAction (Smart): Collecting candidates with smart locator: \(smartSearchLocator.criteria), requireAction: '\(actionToPerform)', depth: 3")
            // collectAll() is external, call original signature. Its logs won't be in currentDebugLogs yet.
            collectAll(
                appElement: appElement, locator: smartSearchLocator, currentElement: baseElementForSearch, 
                depth: 0, maxDepth: 3, maxElements: 5, currentPath: [], 
                elementsBeingProcessed: &processingSet, foundElements: &foundCollectedElements,
                isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs
            )
            let trulySupportingElements = foundCollectedElements.filter { $0.isActionSupported(actionToPerform, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) }
            if trulySupportingElements.count == 1 {
                targetElement = trulySupportingElements.first
                let targetDesc = targetElement?.briefDescription(option: .verbose, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) ?? "nil"
                dLog("PerformAction (Smart): Found unique element via smart search: \(targetDesc)")
            } else if trulySupportingElements.count > 1 {
                dLog("PerformAction (Smart): Found \(trulySupportingElements.count) elements via smart search. Ambiguous.")
            } else {
                dLog("PerformAction (Smart): No elements found via smart search that support the action.")
            }
        } else {
            dLog("PerformAction (Smart): Not enough criteria to attempt smart search.")
        }
    }
    
    guard let finalTargetElement = targetElement else {
        return PerformResponse(command_id: cmd.command_id, success: false, error: "Target element for action '\(actionToPerform)' not found, even after smart search.", debug_logs: currentDebugLogs)
    }
    
    if actionToPerform != kAXSetValueAction && !finalTargetElement.isActionSupported(actionToPerform, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
         let supportedActions: [String]? = finalTargetElement.supportedActions(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
         return PerformResponse(command_id: cmd.command_id, success: false, error: "Final target element for action '\(actionToPerform)' does not support it. Supported: \(supportedActions?.joined(separator: ", ") ?? "none")", debug_logs: currentDebugLogs)
    }

    return try performActionOnElement(element: finalTargetElement, action: actionToPerform, cmd: cmd, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
}

@MainActor
private func performActionOnElement(element: Element, action: String, cmd: CommandEnvelope, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) throws -> PerformResponse {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    let elementDesc = element.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
    dLog("Final target element for action '\(action)': \(elementDesc)")
    if action == kAXSetValueAction {
        guard let valueToSetString = cmd.value else {
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Value not provided for AXSetValue action", debug_logs: currentDebugLogs)
        }
        let attributeToSet = cmd.attribute_to_set?.isEmpty == false ? cmd.attribute_to_set! : kAXValueAttribute
        dLog("AXSetValue: Attempting to set attribute '\(attributeToSet)' to value '\(valueToSetString)' on \(elementDesc)")
        do {
            // createCFTypeRefFromString is external. Assume original signature.
            guard let cfValueToSet = try createCFTypeRefFromString(stringValue: valueToSetString, forElement: element, attributeName: attributeToSet, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
                 return PerformResponse(command_id: cmd.command_id, success: false, error: "Could not parse value '\(valueToSetString)' for attribute '\(attributeToSet)'. Parsing returned nil.", debug_logs: currentDebugLogs)
            }
            let axErr = AXUIElementSetAttributeValue(element.underlyingElement, attributeToSet as CFString, cfValueToSet)
            if axErr == .success {
                return PerformResponse(command_id: cmd.command_id, success: true, error: nil, debug_logs: currentDebugLogs)
            } else {
                // Call axErrorToString without logging parameters
                let errorDescription = "AXUIElementSetAttributeValue failed for attribute '\(attributeToSet)'. Error: \(axErr.rawValue) (\(axErrorToString(axErr)))"
                dLog(errorDescription)
                throw AccessibilityError.actionFailed(errorDescription, axErr)
            }
        } catch let error as AccessibilityError {
            let errorMessage = "Error during AXSetValue for attribute '\(attributeToSet)': \(error.description)"
            dLog(errorMessage)
            throw error
        } catch {
            let errorMessage = "Unexpected Swift error preparing value for '\(attributeToSet)': \(error.localizedDescription)"
            dLog(errorMessage)
            throw AccessibilityError.genericError(errorMessage)
        }
    } else {
        if !element.isActionSupported(action, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
            if action == kAXPressAction && cmd.perform_action_on_child_if_needed == true {
                let parentDesc = element.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
                dLog("Action '\(action)' not supported on element \(parentDesc). Trying on children as perform_action_on_child_if_needed is true.")
                if let children = element.children(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs), !children.isEmpty {
                    for child in children {
                        let childDesc = child.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
                        if child.isActionSupported(kAXPressAction, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
                            dLog("Attempting \(kAXPressAction) on child: \(childDesc)")
                            do {
                                try child.performAction(kAXPressAction, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
                                dLog("Successfully performed \\(kAXPressAction) on child: \\(childDesc)")
                                return PerformResponse(command_id: cmd.command_id, success: true, error: nil, debug_logs: currentDebugLogs)
                            } catch _ as AccessibilityError {
                                dLog("Child action \\(kAXPressAction) failed on \\(childDesc): (AccessibilityError)")
                            } catch {
                                dLog("Child action \\(kAXPressAction) failed on \\(childDesc) with unexpected error: \\(error.localizedDescription)")
                            }
                        }
                    }
                    dLog("No child successfully handled \(kAXPressAction).")
                    return PerformResponse(command_id: cmd.command_id, success: false, error: "Action '\(action)' not supported, and no children to attempt alternative press.", debug_logs: currentDebugLogs)
                } else {
                    dLog("Element has no children to attempt best-effort \(kAXPressAction).")
                    return PerformResponse(command_id: cmd.command_id, success: false, error: "Action '\(action)' not supported, and no children to attempt alternative press.", debug_logs: currentDebugLogs)
                }
            }
            let supportedActions: [String]? = element.supportedActions(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Action '\(action)' not supported. Supported: \(supportedActions?.joined(separator: ", ") ?? "none")", debug_logs: currentDebugLogs)
        }
        do {
            try element.performAction(action, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            return PerformResponse(command_id: cmd.command_id, success: true, error: nil, debug_logs: currentDebugLogs)
        } catch let error as AccessibilityError {
            let elementDescCatch = element.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            dLog("Action '\(action)' failed on element \(elementDescCatch): \(error.description)")
            throw error
        } catch {
            let errorMessage = "Unexpected Swift error performing action '\(action)': \(error.localizedDescription)"
            dLog(errorMessage)
            throw AccessibilityError.genericError(errorMessage)
        }
    }
}
