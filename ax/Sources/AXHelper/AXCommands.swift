// AXCommands.swift - Command handling logic for AXHelper

import Foundation
import ApplicationServices // For AXUIElement etc., kAXSetValueAction
import AppKit // For NSWorkspace (indirectly via getApplicationElement)
// No CoreGraphics needed directly here if point/size logic is in AXUtils

// Note: These functions rely on helpers from AXUtils.swift, AXSearch.swift, AXModels.swift,
// AXLogging.swift, and AXConstants.swift being available in the same module.

@MainActor
func handleQuery(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) throws -> QueryResponse {
    let appIdentifier = cmd.application ?? "focused" // Default to focused if not specified
    debug("Handling query for app: \(appIdentifier)")
    guard let appElement = getApplicationElement(bundleIdOrName: appIdentifier) else {
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Application not found: \(appIdentifier)", debug_logs: collectedDebugLogs)
    }

    var effectiveElement = appElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        debug("Navigating with path_hint: \(pathHint.joined(separator: " -> "))")
        if let navigatedElement = navigateToElement(from: appElement, pathHint: pathHint) {
            effectiveElement = navigatedElement
        } else {
            return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Element not found via path hint: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
    }
    
    guard let locator = cmd.locator else {
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Locator not provided in command.", debug_logs: collectedDebugLogs)
    }

    // Determine search root for locator
    var searchStartElementForLocator = appElement // Default to app element if no root_element_path_hint
    if let rootPathHint = locator.root_element_path_hint, !rootPathHint.isEmpty {
        debug("Locator has root_element_path_hint: \(rootPathHint.joined(separator: " -> ")). Navigating from app element first.")
        guard let containerElement = navigateToElement(from: appElement, pathHint: rootPathHint) else {
            return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Container for locator not found via root_element_path_hint: \(rootPathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
        searchStartElementForLocator = containerElement
        debug("Searching with locator within container found by root_element_path_hint: \(searchStartElementForLocator)")
    } else {
        // If no root_element_path_hint, the effectiveElement (after main path_hint) is the search root for the locator.
        searchStartElementForLocator = effectiveElement
        debug("Searching with locator from element (determined by main path_hint or app root): \(searchStartElementForLocator)")
    }
    
    // If path_hint was applied, effectiveElement is already potentially deep.
    // If locator is also present, it searches *from* searchStartElementForLocator.
    // If only locator (no main path_hint), effectiveElement is appElement, and locator searches from it (or its root_element_path_hint part).

    let finalSearchTarget = (cmd.path_hint != nil && !cmd.path_hint!.isEmpty) ? effectiveElement : searchStartElementForLocator
    
    if let foundElement = search(element: finalSearchTarget, locator: locator, requireAction: locator.requireAction, maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_SEARCH, isDebugLoggingEnabled: isDebugLoggingEnabled) {
        let attributes = getElementAttributes(
            foundElement,
            requestedAttributes: cmd.attributes ?? [],
            forMultiDefault: false, 
            targetRole: locator.criteria[kAXRoleAttribute as String] ?? locator.criteria["AXRole"],
            outputFormat: cmd.output_format ?? "smart"
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
    guard let appElement = getApplicationElement(bundleIdOrName: appIdentifier) else {
        return MultiQueryResponse(command_id: cmd.command_id, elements: nil, count: 0, error: "Application not found: \(appIdentifier)", debug_logs: collectedDebugLogs)
    }

    guard let locator = cmd.locator else {
        return MultiQueryResponse(command_id: cmd.command_id, elements: nil, count: 0, error: "CollectAll command requires a locator.", debug_logs: collectedDebugLogs)
    }

    var searchRootElement = appElement
    if let rootPathHint = locator.root_element_path_hint, !rootPathHint.isEmpty {
        debug("CollectAll: Locator has root_element_path_hint: \(rootPathHint.joined(separator: " -> ")). Navigating from app element first.")
        guard let containerElement = navigateToElement(from: appElement, pathHint: rootPathHint) else {
            return MultiQueryResponse(command_id: cmd.command_id, elements: [], count: 0, error: "Container for locator (collectAll) not found via root_element_path_hint: \(rootPathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
        searchRootElement = containerElement
        debug("CollectAll: Search root for collectAll is: \(searchRootElement)")
    } else {
        debug("CollectAll: Search root for collectAll is the main app element (or element from main path_hint if provided - though path_hint is not typical for collect_all root, usually it is locator.root_element_path_hint).")
        // If cmd.path_hint is provided for collect_all, it should ideally define the searchRootElement here.
        // For now, assuming collect_all either uses appElement or locator.root_element_path_hint to define its scope.
        // If cmd.path_hint is also relevant, this logic might need adjustment.
         if let pathHint = cmd.path_hint, !pathHint.isEmpty {
            debug("CollectAll: Main path_hint \(pathHint.joined(separator: " -> ")) is also present. Attempting to use it as search root.")
            if let navigatedElement = navigateToElement(from: appElement, pathHint: pathHint) {
                searchRootElement = navigatedElement
                debug("CollectAll: Search root updated by main path_hint to: \(searchRootElement)")
            } else {
                 return MultiQueryResponse(command_id: cmd.command_id, elements: [], count: 0, error: "Element from main path_hint not found for collectAll: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
            }
        }
    }
    
    var foundAxsElements: [AXUIElement] = []
    var elementsBeingProcessed = Set<AXUIElementHashableWrapper>()
    let maxElementsFromCmd = cmd.max_elements ?? MAX_COLLECT_ALL_HITS
    let maxDepthForCollect = DEFAULT_MAX_DEPTH_COLLECT_ALL // Or use a cmd specific field if available

    debug("Starting collectAll from element: \(searchRootElement) with locator criteria: \(locator.criteria), maxElements: \(maxElementsFromCmd), maxDepth: \(maxDepthForCollect)")
    
    collectAll(
        appElement: appElement, 
        locator: locator,
        currentElement: searchRootElement, 
        depth: 0,
        maxDepth: maxDepthForCollect, 
        maxElements: maxElementsFromCmd,
        currentPath: [], // Initialize currentPath as empty Array of AXUIElementHashableWrapper
        elementsBeingProcessed: &elementsBeingProcessed,
        foundElements: &foundAxsElements,
        isDebugLoggingEnabled: isDebugLoggingEnabled
    )

    debug("collectAll finished. Found \(foundAxsElements.count) elements.")
    
    let attributesArray = foundAxsElements.map { el in
        getElementAttributes(
            el,
            requestedAttributes: cmd.attributes ?? [],
            forMultiDefault: (cmd.attributes?.isEmpty ?? true), 
            targetRole: axValue(of: el, attr: kAXRoleAttribute),
            outputFormat: cmd.output_format ?? "smart"
        )
    }
    return MultiQueryResponse(command_id: cmd.command_id, elements: attributesArray, count: attributesArray.count, error: nil, debug_logs: collectedDebugLogs)
}


@MainActor
func handlePerform(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) throws -> PerformResponse {
    let appIdentifier = cmd.application ?? "focused"
    debug("Handling perform_action for app: \(appIdentifier), action: \(cmd.action ?? "nil")")

    guard let appElement = getApplicationElement(bundleIdOrName: appIdentifier) else {
        return PerformResponse(command_id: cmd.command_id, success: false, error: "Application not found: \(appIdentifier)", debug_logs: collectedDebugLogs)
    }
    guard let actionToPerform = cmd.action, !actionToPerform.isEmpty else {
        return PerformResponse(command_id: cmd.command_id, success: false, error: "Action not specified", debug_logs: collectedDebugLogs)
    }
    guard let locator = cmd.locator else {
        // If no locator, action is performed on element found by path_hint, or appElement if no path_hint.
        // This path requires targetElement to be determined before this guard.
        var elementForDirectAction = appElement
        if let pathHint = cmd.path_hint, !pathHint.isEmpty {
            debug("No locator for Perform. Navigating with path_hint: \(pathHint.joined(separator: " -> ")) for action \(actionToPerform)")
            guard let navigatedElement = navigateToElement(from: appElement, pathHint: pathHint) else {
                return PerformResponse(command_id: cmd.command_id, success: false, error: "Element for action (no locator) not found via path_hint: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
            }
            elementForDirectAction = navigatedElement
        }
        debug("No locator. Performing action '\(actionToPerform)' directly on element: \(elementForDirectAction)")
        // Proceed to action logic with elementForDirectAction as targetElement
        return try performActionOnElement(element: elementForDirectAction, action: actionToPerform, cmd: cmd)
    }

    // Locator IS provided
    // If cmd.path_hint is also present, it means the element to search *within* is defined by path_hint,
    // and then the locator applies within that, potentially with its own root_element_path_hint relative to appElement.
    // This logic implies cmd.path_hint might define a broader context than locator.root_element_path_hint.
    // Current logic: if cmd.path_hint exists, it sets the context. If locator.root_element_path_hint exists, it further refines from app root.
    // Let's clarify: if cmd.path_hint exists, it defines the base. Locator.criteria applies to this base.
    // locator.root_element_path_hint is for when the locator needs its own base from app root, independent of cmd.path_hint.

    var baseElementForSearch = appElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        debug("PerformAction: Main path_hint \(pathHint.joined(separator: " -> ")) present. Navigating to establish base for search.")
        guard let navigatedBase = navigateToElement(from: appElement, pathHint: pathHint) else {
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Base element for search (from main path_hint) not found: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
        baseElementForSearch = navigatedBase
    }
    // If locator.root_element_path_hint is set, it overrides baseElementForSearch that might have been set by cmd.path_hint.
    if let rootPathHint = locator.root_element_path_hint, !rootPathHint.isEmpty {
        debug("PerformAction: locator.root_element_path_hint \(rootPathHint.joined(separator: " -> ")) overrides main path_hint for search base. Navigating from app root.")
        guard let newBaseFromLocatorRoot = navigateToElement(from: appElement, pathHint: rootPathHint) else {
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Search base from locator.root_element_path_hint not found: \(rootPathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
        baseElementForSearch = newBaseFromLocatorRoot
    }
    debug("PerformAction: Searching for action element within: \(baseElementForSearch) using locator criteria: \(locator.criteria)")
        
    guard let targetElement = search(element: baseElementForSearch, locator: locator, requireAction: cmd.action, maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_SEARCH, isDebugLoggingEnabled: isDebugLoggingEnabled) else {
        return PerformResponse(command_id: cmd.command_id, success: false, error: "Target element for action not found or does not support action '\(actionToPerform)' with given locator and path hints.", debug_logs: collectedDebugLogs)
    }
    
    return try performActionOnElement(element: targetElement, action: actionToPerform, cmd: cmd)
}

// Helper for actual action performance, extracted for clarity
@MainActor
private func performActionOnElement(element: AXUIElement, action: String, cmd: CommandEnvelope) throws -> PerformResponse {
    debug("Final target element for action '\(action)': \(element)")
    if action == "AXSetValue" {
        guard let valueToSet = cmd.value else {
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Value not provided for AXSetValue action", debug_logs: collectedDebugLogs)
        }
        debug("Attempting to set value '\(valueToSet)' for attribute \(kAXValueAttribute) on \(element)")
        let axErr = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, valueToSet as CFTypeRef)
        if axErr == .success {
            return PerformResponse(command_id: cmd.command_id, success: true, error: nil, debug_logs: collectedDebugLogs)
        } else {
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Failed to set value. Error: \(axErr.rawValue)", debug_logs: collectedDebugLogs)
        }
    } else {
        if !elementSupportsAction(element, action: action) {
            let supportedActions: [String]? = axValue(of: element, attr: kAXActionNamesAttribute)
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Action '\(action)' not supported. Supported: \(supportedActions?.joined(separator: ", ") ?? "none")", debug_logs: collectedDebugLogs)
        }
        debug("Performing action '\(action)' on \(element)")
        let axErr = AXUIElementPerformAction(element, action as CFString)
        if axErr == .success {
            return PerformResponse(command_id: cmd.command_id, success: true, error: nil, debug_logs: collectedDebugLogs)
        } else {
            return PerformResponse(command_id: cmd.command_id, success: false, error: "Action '\(action)' failed. Error: \(axErr.rawValue)", debug_logs: collectedDebugLogs)
        }
    }
}


@MainActor
func handleExtractText(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) throws -> TextContentResponse {
    let appIdentifier = cmd.application ?? "focused"
    debug("Handling extract_text for app: \(appIdentifier)")
    guard let appElement = getApplicationElement(bundleIdOrName: appIdentifier) else {
        return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "Application not found: \(appIdentifier)", debug_logs: collectedDebugLogs)
    }

    var effectiveElement = appElement // Start with appElement or element from path_hint
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        debug("ExtractText: Navigating with path_hint: \(pathHint.joined(separator: " -> "))")
        if let navigatedElement = navigateToElement(from: appElement, pathHint: pathHint) {
            effectiveElement = navigatedElement
        } else {
            return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "Element for text extraction (path_hint) not found: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
    }

    var elementsToExtractFrom: [AXUIElement] = []

    if let locator = cmd.locator {
        debug("ExtractText: Locator provided. Searching for element(s) based on locator criteria: \(locator.criteria)")
        var searchBaseForLocator = appElement // Default to appElement if locator has no root hint and no main path_hint was used
        if cmd.path_hint != nil && !cmd.path_hint!.isEmpty { // If main path_hint set effectiveElement, locator searches within it.
            searchBaseForLocator = effectiveElement
        }
        if let rootPathHint = locator.root_element_path_hint, !rootPathHint.isEmpty {
            debug("ExtractText: Locator has root_element_path_hint: \(rootPathHint.joined(separator: " -> ")). Overriding search base.")
            guard let container = navigateToElement(from: appElement, pathHint: rootPathHint) else {
                return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "Container for text extraction (locator.root_path_hint) not found: \(rootPathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
            }
            searchBaseForLocator = container
        }
        debug("ExtractText: Searching for text elements within \(searchBaseForLocator)")

        // For text extraction, usually we want all matches from collectAll if a locator is general.
        // If locator is very specific, search might be okay.
        // Let's use collectAll for broader text gathering if locator is present.
        var allMatchingElements: [AXUIElement] = []
        var processingSetForExtract = Set<AXUIElementHashableWrapper>()
        let maxElements = cmd.max_elements ?? MAX_COLLECT_ALL_HITS // Use a reasonable default or specific for text
        let maxDepth = DEFAULT_MAX_DEPTH_COLLECT_ALL

        collectAll(appElement: appElement, 
                   locator: locator, 
                   currentElement: searchBaseForLocator, 
                   depth: 0, 
                   maxDepth: maxDepth, 
                   maxElements: maxElements, 
                   currentPath: [], 
                   elementsBeingProcessed: &processingSetForExtract, 
                   foundElements: &allMatchingElements,
                   isDebugLoggingEnabled: isDebugLoggingEnabled
        )
        
        if allMatchingElements.isEmpty {
             debug("ExtractText: No elements matched locator criteria within \(searchBaseForLocator).")
        }
        elementsToExtractFrom.append(contentsOf: allMatchingElements)

    } else {
        // No locator provided, extract text from the effectiveElement (app root or element from path_hint)
        debug("ExtractText: No locator. Extracting from effective element: \(effectiveElement)")
        elementsToExtractFrom.append(effectiveElement)
    }

    if elementsToExtractFrom.isEmpty {
         return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "No elements found to extract text from.", debug_logs: collectedDebugLogs)
    }

    var allTexts: [String] = []
    for el in elementsToExtractFrom {
        allTexts.append(extractTextContent(element: el))
    }
    
    return TextContentResponse(command_id: cmd.command_id, text_content: allTexts.filter { !$0.isEmpty }.joined(separator: "\n\n"), error: nil, debug_logs: collectedDebugLogs)
} 