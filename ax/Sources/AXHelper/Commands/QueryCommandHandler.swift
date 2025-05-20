import Foundation
import ApplicationServices
import AppKit 

// Note: Relies on applicationElement, navigateToElement, search, getElementAttributes, 
// DEFAULT_MAX_DEPTH_SEARCH, collectedDebugLogs, CommandEnvelope, QueryResponse, Locator.

@MainActor
func handleQuery(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) throws -> QueryResponse {
    let appIdentifier = cmd.application ?? "focused"
    debug("Handling query for app: \(appIdentifier)")
    guard let appElement = applicationElement(for: appIdentifier) else {
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Application not found: \(appIdentifier)", debug_logs: collectedDebugLogs)
    }

    var effectiveElement = appElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        debug("Navigating with path_hint: \(pathHint.joined(separator: " -> "))")
        if let navigatedElement = navigateToElement(from: effectiveElement, pathHint: pathHint) {
            effectiveElement = navigatedElement
        } else {
            return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Element not found via path hint: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
    }
    
    guard let locator = cmd.locator else {
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Locator not provided in command.", debug_logs: collectedDebugLogs)
    }

    // Check if the locator criteria *only* specifies an application identifier
    // and no other element-specific criteria.
    let appSpecifiers = ["application", "bundle_id", "pid", "path"]
    let criteriaKeys = locator.criteria.keys
    let isAppOnlyLocator = criteriaKeys.allSatisfy { appSpecifiers.contains($0) } && criteriaKeys.count == 1

    var foundElement: Element? = nil

    if isAppOnlyLocator {
        debug("Locator is app-only (criteria: \(locator.criteria)). Using appElement directly.")
        // If the locator is only specifying the application (e.g., {"application": "focused"}),
        // and we have an effectiveElement (which should be the appElement or one derived via path_hint),
        // then this is the element we want to query.
        // The 'effectiveElement' would have been determined by initial app lookup + optional path_hint.
        // If path_hint was used, effectiveElement is already the target.
        // If no path_hint, effectiveElement is appElement.
        foundElement = effectiveElement
    } else {
        debug("Locator contains element-specific criteria or is complex. Proceeding with search.")
        var searchStartElementForLocator = appElement
        if let rootPathHint = locator.root_element_path_hint, !rootPathHint.isEmpty {
            debug("Locator has root_element_path_hint: \(rootPathHint.joined(separator: " -> ")). Navigating from app element first.")
            guard let containerElement = navigateToElement(from: appElement, pathHint: rootPathHint) else {
                return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Container for locator not found via root_element_path_hint: \(rootPathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
            }
            searchStartElementForLocator = containerElement
            debug("Searching with locator within container found by root_element_path_hint: \(searchStartElementForLocator.underlyingElement)")
        } else {
            searchStartElementForLocator = effectiveElement
            debug("Searching with locator from element (determined by main path_hint or app root): \(searchStartElementForLocator.underlyingElement)")
        }
        
        let finalSearchTarget = (cmd.path_hint != nil && !cmd.path_hint!.isEmpty) ? effectiveElement : searchStartElementForLocator
        
        foundElement = search(
            element: finalSearchTarget,
            locator: locator,
            requireAction: locator.requireAction,
            maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_SEARCH,
            isDebugLoggingEnabled: isDebugLoggingEnabled
        )
    }
    
    if let elementToQuery = foundElement {
        var attributes = getElementAttributes(
            elementToQuery,
            requestedAttributes: cmd.attributes ?? [],
            forMultiDefault: false, 
            targetRole: locator.criteria[kAXRoleAttribute],
            outputFormat: cmd.output_format ?? .smart
        )
        // If output format is json_string, encode the attributes dictionary.
        if cmd.output_format == .json_string {
            attributes = encodeAttributesToJSONStringRepresentation(attributes)
        }
        return QueryResponse(command_id: cmd.command_id, attributes: attributes, error: nil, debug_logs: collectedDebugLogs)
    } else {
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "No element matches single query criteria with locator or app-only locator failed to resolve.", debug_logs: collectedDebugLogs)
    }
}