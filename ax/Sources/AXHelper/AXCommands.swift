// AXCommands.swift - Command handling logic for AXHelper

import Foundation
import ApplicationServices // For AXUIElement etc., kAXSetValueAction
import AppKit // For NSWorkspace (indirectly via getApplicationElement)
// No CoreGraphics needed directly here if point/size logic is in AXUtils

// Note: These functions rely on helpers from AXUtils.swift, AXSearch.swift, AXModels.swift,
// AXLogging.swift, and AXConstants.swift being available in the same module.

@MainActor
func handleQuery(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) throws -> QueryResponse {
    let appIdentifier = cmd.application ?? "focused"
    debug("Handling query for app: \(appIdentifier)")
    guard let appAXElement = applicationElement(for: appIdentifier) else {
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Application not found: \(appIdentifier)", debug_logs: collectedDebugLogs)
    }

    var effectiveAXElement = appAXElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        debug("Navigating with path_hint: \(pathHint.joined(separator: " -> "))")
        if let navigatedElement = navigateToElement(from: effectiveAXElement, pathHint: pathHint) {
            effectiveAXElement = navigatedElement
        } else {
            return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Element not found via path hint: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
    }
    
    guard let locator = cmd.locator else {
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Locator not provided in command.", debug_logs: collectedDebugLogs)
    }

    var searchStartAXElementForLocator = appAXElement
    if let rootPathHint = locator.root_element_path_hint, !rootPathHint.isEmpty {
        debug("Locator has root_element_path_hint: \(rootPathHint.joined(separator: " -> ")). Navigating from app element first.")
        guard let containerAXElement = navigateToElement(from: appAXElement, pathHint: rootPathHint) else {
            return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Container for locator not found via root_element_path_hint: \(rootPathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
        searchStartAXElementForLocator = containerAXElement
        debug("Searching with locator within container found by root_element_path_hint: \(searchStartAXElementForLocator.underlyingElement)")
    } else {
        searchStartAXElementForLocator = effectiveAXElement
        debug("Searching with locator from element (determined by main path_hint or app root): \(searchStartAXElementForLocator.underlyingElement)")
    }
    
    let finalSearchTargetAX = (cmd.path_hint != nil && !cmd.path_hint!.isEmpty) ? effectiveAXElement : searchStartAXElementForLocator
    
    if let foundAXElement = search(axElement: finalSearchTargetAX, locator: locator, requireAction: locator.requireAction, maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_SEARCH, isDebugLoggingEnabled: isDebugLoggingEnabled) {
        let attributes = getElementAttributes(
            foundAXElement,
            requestedAttributes: cmd.attributes ?? [],
            forMultiDefault: false, 
            targetRole: locator.criteria[kAXRoleAttribute],
            outputFormat: cmd.output_format ?? .smart
        )
        return QueryResponse(command_id: cmd.command_id, attributes: attributes, error: nil, debug_logs: collectedDebugLogs)
    } else {
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "No element matches single query criteria with locator.", debug_logs: collectedDebugLogs)
    }
}

@MainActor
func handleCollectAll(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) throws -> MultiQueryResponse {
    let appIdentifier = cmd.application ?? "focused"
    debug("Handling collect_all for app: \(appIdentifier)")
    guard let appAXElement = applicationElement(for: appIdentifier) else {
        return MultiQueryResponse(command_id: cmd.command_id, elements: nil, count: 0, error: "Application not found: \(appIdentifier)", debug_logs: collectedDebugLogs)
    }

    guard let locator = cmd.locator else {
        return MultiQueryResponse(command_id: cmd.command_id, elements: nil, count: 0, error: "CollectAll command requires a locator.", debug_logs: collectedDebugLogs)
    }

    var searchRootAXElement = appAXElement
    if let rootPathHint = locator.root_element_path_hint, !rootPathHint.isEmpty {
        debug("CollectAll: Locator has root_element_path_hint: \(rootPathHint.joined(separator: " -> ")). Navigating from app element first.")
        guard let containerAXElement = navigateToElement(from: appAXElement, pathHint: rootPathHint) else {
            return MultiQueryResponse(command_id: cmd.command_id, elements: [], count: 0, error: "Container for locator (collectAll) not found via root_element_path_hint: \(rootPathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
        searchRootAXElement = containerAXElement
        debug("CollectAll: Search root for collectAll is: \(searchRootAXElement.underlyingElement)")
    } else {
        debug("CollectAll: Search root for collectAll is the main app element (or element from main path_hint if provided).")
         if let pathHint = cmd.path_hint, !pathHint.isEmpty {
            debug("CollectAll: Main path_hint \(pathHint.joined(separator: " -> ")) is also present. Attempting to use it as search root.")
            if let navigatedAXElement = navigateToElement(from: appAXElement, pathHint: pathHint) {
                searchRootAXElement = navigatedAXElement
                debug("CollectAll: Search root updated by main path_hint to: \(searchRootAXElement.underlyingElement)")
            } else {
                 return MultiQueryResponse(command_id: cmd.command_id, elements: [], count: 0, error: "Element from main path_hint not found for collectAll: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
            }
        }
    }
    
    var foundCollectedAXElements: [AXElement] = []
    var elementsBeingProcessed = Set<AXElement>()
    let maxElementsFromCmd = cmd.max_elements ?? MAX_COLLECT_ALL_HITS
    let maxDepthForCollect = DEFAULT_MAX_DEPTH_COLLECT_ALL

    debug("Starting collectAll from element: \(searchRootAXElement.underlyingElement) with locator criteria: \(locator.criteria), maxElements: \(maxElementsFromCmd), maxDepth: \(maxDepthForCollect)")
    
    collectAll(
        appAXElement: appAXElement,
        locator: locator,
        currentAXElement: searchRootAXElement,
        depth: 0,
        maxDepth: maxDepthForCollect, 
        maxElements: maxElementsFromCmd,
        currentPath: [],
        elementsBeingProcessed: &elementsBeingProcessed,
        foundElements: &foundCollectedAXElements,
        isDebugLoggingEnabled: isDebugLoggingEnabled
    )

    debug("collectAll finished. Found \(foundCollectedAXElements.count) elements.")
    
    let attributesArray = foundCollectedAXElements.map { axEl in
        getElementAttributes(
            axEl,
            requestedAttributes: cmd.attributes ?? [],
            forMultiDefault: (cmd.attributes?.isEmpty ?? true), 
            targetRole: axEl.role,
            outputFormat: cmd.output_format ?? .smart
        )
    }
    return MultiQueryResponse(command_id: cmd.command_id, elements: attributesArray, count: attributesArray.count, error: nil, debug_logs: collectedDebugLogs)
}


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
            // Remove original title criteria to avoid conflict if it was overly specific
            smartLocatorCriteria.removeValue(forKey: kAXTitleAttribute)
            smartLocatorCriteria.removeValue(forKey: "AXTitle")
            useComputedNameForSmartSearch = true
            debug("PerformAction (Smart): Using title '\(titleFromCriteria)' for computed_name_contains.")
        } else if let idFromCriteria = smartLocatorCriteria[kAXIdentifierAttribute] ?? smartLocatorCriteria["AXIdentifier"] {
            // If no title, but there's an ID, maybe the ID is also part of a useful computed name.
            // This is less direct than title, but worth a try if title is absent.
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
                root_element_path_hint: nil, // Search from current base, not re-evaluating root hint here
                requireAction: actionToPerform, // Crucially, now require the specific action
                computed_name_equals: nil, // Rely on contains from criteria for now
                computed_name_contains: smartLocatorCriteria["computed_name_contains"] // Pass through if set
            )

            var foundCollectedElements: [AXElement] = []
            var processingSet = Set<AXElement>()
            let smartSearchMaxDepth = 3 // Limit depth for smart search

            debug("PerformAction (Smart): Collecting candidates with smart locator: \(smartSearchLocator.criteria), requireAction: '\(actionToPerform)', depth: \(smartSearchMaxDepth)")
            collectAll(
                appAXElement: appAXElement, // Pass the main app element for context if needed by collectAll internals
                locator: smartSearchLocator, 
                currentAXElement: baseAXElementForSearch, 
                depth: 0, 
                maxDepth: smartSearchMaxDepth, 
                maxElements: 5, // Collect a few candidates
                currentPath: [], 
                elementsBeingProcessed: &processingSet, 
                foundElements: &foundCollectedElements,
                isDebugLoggingEnabled: isDebugLoggingEnabled
            )

            // Filter for exact action support again, as collectAll's requireAction might be based on attributesMatch
            let trulySupportingElements = foundCollectedElements.filter { $0.isActionSupported(actionToPerform) }

            if trulySupportingElements.count == 1 {
                targetAXElement = trulySupportingElements.first
                debug("PerformAction (Smart): Found unique element via smart search: \(targetAXElement?.briefDescription(option: .verbose) ?? "nil")")
            } else if trulySupportingElements.count > 1 {
                debug("PerformAction (Smart): Found \(trulySupportingElements.count) elements via smart search. Ambiguous. Original error will be returned.")
                // targetAXElement remains nil or the original non-supporting one, leading to error below
            } else {
                debug("PerformAction (Smart): No elements found via smart search that support the action.")
                // targetAXElement remains nil or the original non-supporting one
            }
        } else {
            debug("PerformAction (Smart): Not enough criteria (no title/ID for computed_name and no role) to attempt smart search.")
        }
    }
    
    // After initial and potential smart search, check if we have a valid target
    guard let finalTargetAXElement = targetAXElement else {
        return PerformResponse(command_id: cmd.command_id, success: false, error: "Target element for action '\(actionToPerform)' not found with given locator and path hints, even after smart search.", debug_logs: collectedDebugLogs)
    }
    
    // If the action is not setValue, ensure the final element supports it (if it wasn't nil from search)
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
        
        // Determine the attribute to set. Default to kAXValueAttribute if not specified or empty.
        let attributeToSet = cmd.attribute_to_set?.isEmpty == false ? cmd.attribute_to_set! : kAXValueAttribute
        debug("AXSetValue: Attempting to set attribute '\(attributeToSet)' to value '\(valueToSetString)' on \(String(describing: axElement.underlyingElement))")

        do {
            guard let cfValueToSet = try createCFTypeRefFromString(stringValue: valueToSetString, forElement: axElement, attributeName: attributeToSet) else {
                 return PerformResponse(command_id: cmd.command_id, success: false, error: "Could not parse value '\(valueToSetString)' for attribute '\(attributeToSet)'. Parsing returned nil.", debug_logs: collectedDebugLogs)
            }
            // Ensure the CFValue is released by ARC after the call if it was created with a +1 retain count (AXValueCreate does this)
            // If it was a bridged string/number, ARC handles it.
            defer { /* _ = Unmanaged.passRetained(cfValueToSet).autorelease() */ } // Releasing AXValueCreate result is important
            
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
            let supportedActions: [String]? = axElement.supportedActions
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Action '\(action)' not supported. Supported: \(supportedActions?.joined(separator: ", ") ?? "none")", debug_logs: collectedDebugLogs)
        }
        debug("Performing action '\(action)' on \(axElement.underlyingElement)")
        try axElement.performAction(action)
        return PerformResponse(command_id: cmd.command_id, success: true, error: nil, debug_logs: collectedDebugLogs)
    }
}


@MainActor
func handleExtractText(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) throws -> TextContentResponse {
    let appIdentifier = cmd.application ?? "focused"
    debug("Handling extract_text for app: \(appIdentifier)")
    guard let appAXElement = applicationElement(for: appIdentifier) else {
        return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "Application not found: \(appIdentifier)", debug_logs: collectedDebugLogs)
    }

    var effectiveAXElement = appAXElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        debug("ExtractText: Navigating with path_hint: \(pathHint.joined(separator: " -> "))")
        if let navigatedAXElement = navigateToElement(from: effectiveAXElement, pathHint: pathHint) {
            effectiveAXElement = navigatedAXElement
        } else {
            return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "Element for text extraction (path_hint) not found: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
    }

    var elementsToExtractFromAX: [AXElement] = []

    if let locator = cmd.locator {
        var foundCollectedAXElements: [AXElement] = []
        var processingSet = Set<AXElement>()
        collectAll(
            appAXElement: appAXElement,
            locator: locator, 
            currentAXElement: effectiveAXElement,
            depth: 0, 
            maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_COLLECT_ALL, 
            maxElements: cmd.max_elements ?? MAX_COLLECT_ALL_HITS,
            currentPath: [], 
            elementsBeingProcessed: &processingSet, 
            foundElements: &foundCollectedAXElements,
            isDebugLoggingEnabled: isDebugLoggingEnabled
        )
        elementsToExtractFromAX = foundCollectedAXElements
    } else {
        elementsToExtractFromAX = [effectiveAXElement]
    }
    
    if elementsToExtractFromAX.isEmpty && cmd.locator != nil {
         return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "No elements found by locator for text extraction.", debug_logs: collectedDebugLogs)
    }

    var allTexts: [String] = []
    for axEl in elementsToExtractFromAX {
        allTexts.append(extractTextContent(axElement: axEl))
    }
    
    let combinedText = allTexts.filter { !$0.isEmpty }.joined(separator: "\n\n---\n\n")
    return TextContentResponse(command_id: cmd.command_id, text_content: combinedText.isEmpty ? nil : combinedText, error: nil, debug_logs: collectedDebugLogs)
} 