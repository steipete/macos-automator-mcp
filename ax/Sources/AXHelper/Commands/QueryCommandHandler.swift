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
    
    if let foundElement = search(element: finalSearchTarget, locator: locator, requireAction: locator.requireAction, maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_SEARCH, isDebugLoggingEnabled: isDebugLoggingEnabled) {
        var attributes = getElementAttributes(
            foundElement,
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
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "No element matches single query criteria with locator.", debug_logs: collectedDebugLogs)
    }
}