import Foundation
import ApplicationServices
import AppKit

// Note: Relies on applicationElement, navigateToElement, collectAll (from ElementSearch),
// getElementAttributes, MAX_COLLECT_ALL_HITS, DEFAULT_MAX_DEPTH_COLLECT_ALL,
// collectedDebugLogs, CommandEnvelope, MultiQueryResponse, Locator, Element.

@MainActor
func handleCollectAll(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) throws -> MultiQueryResponse {
    let appIdentifier = cmd.application ?? "focused"
    debug("Handling collect_all for app: \(appIdentifier)")
    guard let appElement = applicationElement(for: appIdentifier) else {
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
        debug("CollectAll: Search root for collectAll is: \(searchRootElement.underlyingElement)")
    } else {
        debug("CollectAll: Search root for collectAll is the main app element (or element from main path_hint if provided).")
         if let pathHint = cmd.path_hint, !pathHint.isEmpty {
            debug("CollectAll: Main path_hint \(pathHint.joined(separator: " -> ")) is also present. Attempting to use it as search root.")
            if let navigatedElement = navigateToElement(from: appElement, pathHint: pathHint) {
                searchRootElement = navigatedElement
                debug("CollectAll: Search root updated by main path_hint to: \(searchRootElement.underlyingElement)")
            } else {
                 return MultiQueryResponse(command_id: cmd.command_id, elements: [], count: 0, error: "Element from main path_hint not found for collectAll: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
            }
        }
    }
    
    var foundCollectedElements: [Element] = []
    var elementsBeingProcessed = Set<Element>()
    let maxElementsFromCmd = cmd.max_elements ?? MAX_COLLECT_ALL_HITS
    let maxDepthForCollect = DEFAULT_MAX_DEPTH_COLLECT_ALL

    debug("Starting collectAll from element: \(searchRootElement.underlyingElement) with locator criteria: \(locator.criteria), maxElements: \(maxElementsFromCmd), maxDepth: \(maxDepthForCollect)")
    
    collectAll(
        appElement: appElement,
        locator: locator,
        currentElement: searchRootElement,
        depth: 0,
        maxDepth: maxDepthForCollect, 
        maxElements: maxElementsFromCmd,
        currentPath: [],
        elementsBeingProcessed: &elementsBeingProcessed,
        foundElements: &foundCollectedElements,
        isDebugLoggingEnabled: isDebugLoggingEnabled
    )

    debug("collectAll finished. Found \(foundCollectedElements.count) elements.")
    
    let attributesArray = foundCollectedElements.map { el in
        getElementAttributes(
            el,
            requestedAttributes: cmd.attributes ?? [],
            forMultiDefault: (cmd.attributes?.isEmpty ?? true), 
            targetRole: el.role,
            outputFormat: cmd.output_format ?? .smart
        )
    }
    return MultiQueryResponse(command_id: cmd.command_id, elements: attributesArray, count: attributesArray.count, error: nil, debug_logs: collectedDebugLogs)
}