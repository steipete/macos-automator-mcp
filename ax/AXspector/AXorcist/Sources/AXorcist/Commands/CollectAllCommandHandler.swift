import Foundation
import ApplicationServices
import AppKit

// Note: Relies on applicationElement, navigateToElement, collectAll (from ElementSearch),
// getElementAttributes, MAX_COLLECT_ALL_HITS, DEFAULT_MAX_DEPTH_COLLECT_ALL,
// collectedDebugLogs, CommandEnvelope, MultiQueryResponse, Locator, Element.

@MainActor
public func handleCollectAll(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) throws -> MultiQueryResponse {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    let appIdentifier = cmd.application ?? focusedApplicationKey
    dLog("Handling collect_all for app: \(appIdentifier)")

    // Pass logging parameters to applicationElement
    guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
        return MultiQueryResponse(command_id: cmd.command_id, elements: nil, count: 0, error: "Application not found: \(appIdentifier)", debug_logs: currentDebugLogs)
    }

    guard let locator = cmd.locator else {
        return MultiQueryResponse(command_id: cmd.command_id, elements: nil, count: 0, error: "CollectAll command requires a locator.", debug_logs: currentDebugLogs)
    }

    var searchRootElement = appElement
    if let rootPathHint = locator.root_element_path_hint, !rootPathHint.isEmpty {
        dLog("CollectAll: Locator has root_element_path_hint: \(rootPathHint.joined(separator: " -> ")). Navigating from app element first.")
        // Pass logging parameters to navigateToElement
        guard let containerElement = navigateToElement(from: appElement, pathHint: rootPathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
            return MultiQueryResponse(command_id: cmd.command_id, elements: [], count: 0, error: "Container for locator (collectAll) not found via root_element_path_hint: \(rootPathHint.joined(separator: " -> "))", debug_logs: currentDebugLogs)
        }
        searchRootElement = containerElement
        dLog("CollectAll: Search root for collectAll is: \(searchRootElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs))")
    } else {
        dLog("CollectAll: Search root for collectAll is the main app element (or element from main path_hint if provided).")
         if let pathHint = cmd.path_hint, !pathHint.isEmpty {
            dLog("CollectAll: Main path_hint \(pathHint.joined(separator: " -> ")) is also present. Attempting to use it as search root.")
            // Pass logging parameters to navigateToElement
            if let navigatedElement = navigateToElement(from: appElement, pathHint: pathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
                searchRootElement = navigatedElement
                dLog("CollectAll: Search root updated by main path_hint to: \(searchRootElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs))")
            } else {
                 return MultiQueryResponse(command_id: cmd.command_id, elements: [], count: 0, error: "Element from main path_hint not found for collectAll: \(pathHint.joined(separator: " -> "))", debug_logs: currentDebugLogs)
            }
        }
    }
    
    var foundCollectedElements: [Element] = []
    var elementsBeingProcessed = Set<Element>()
    let maxElementsFromCmd = cmd.max_elements ?? MAX_COLLECT_ALL_HITS
    let maxDepthForCollect = DEFAULT_MAX_DEPTH_COLLECT_ALL

    dLog("Starting collectAll from element: \(searchRootElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)) with locator criteria: \(locator.criteria), maxElements: \(maxElementsFromCmd), maxDepth: \(maxDepthForCollect)")
    
    // Pass logging parameters to collectAll
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
        isDebugLoggingEnabled: isDebugLoggingEnabled,
        currentDebugLogs: &currentDebugLogs
    )

    dLog("collectAll finished. Found \(foundCollectedElements.count) elements.")
    
    let attributesArray = foundCollectedElements.map { el -> ElementAttributes in // Explicit return type for clarity
        // Pass logging parameters to getElementAttributes
        // And call el.role as a method
        var roleTempLogs: [String] = []
        let roleOfEl = el.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &roleTempLogs)
        currentDebugLogs.append(contentsOf: roleTempLogs)
        
        return getElementAttributes(
            el,
            requestedAttributes: cmd.attributes ?? [],
            forMultiDefault: (cmd.attributes?.isEmpty ?? true), 
            targetRole: roleOfEl,
            outputFormat: cmd.output_format ?? .smart,
            isDebugLoggingEnabled: isDebugLoggingEnabled,
            currentDebugLogs: &currentDebugLogs
        )
    }
    return MultiQueryResponse(command_id: cmd.command_id, elements: attributesArray, count: attributesArray.count, error: nil, debug_logs: currentDebugLogs)
}