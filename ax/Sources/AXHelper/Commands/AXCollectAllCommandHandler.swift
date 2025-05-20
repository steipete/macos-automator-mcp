import Foundation
import ApplicationServices
import AppKit

// Note: Relies on applicationElement, navigateToElement, collectAll (from AXSearch),
// getElementAttributes, MAX_COLLECT_ALL_HITS, DEFAULT_MAX_DEPTH_COLLECT_ALL,
// collectedDebugLogs, CommandEnvelope, MultiQueryResponse, Locator, AXElement.

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