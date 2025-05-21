import Foundation
import ApplicationServices
import AppKit 

// Note: Relies on applicationElement, navigateToElement, search, getElementAttributes, 
// DEFAULT_MAX_DEPTH_SEARCH, collectedDebugLogs, CommandEnvelope, QueryResponse, Locator.

@MainActor
public func handleQuery(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) throws -> QueryResponse {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    let appIdentifier = cmd.application ?? focusedApplicationKey
    dLog("Handling query for app: \(appIdentifier)")

    // Pass logging parameters to applicationElement
    guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Application not found: \(appIdentifier)", debug_logs: currentDebugLogs)
    }

    var effectiveElement = appElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        dLog("Navigating with path_hint: \(pathHint.joined(separator: " -> "))")
        // Pass logging parameters to navigateToElement
        if let navigatedElement = navigateToElement(from: effectiveElement, pathHint: pathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
            effectiveElement = navigatedElement
        } else {
            return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Element not found via path hint: \(pathHint.joined(separator: " -> "))", debug_logs: currentDebugLogs)
        }
    }
    
    guard let locator = cmd.locator else {
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Locator not provided in command.", debug_logs: currentDebugLogs)
    }

    let appSpecifiers = ["application", "bundle_id", "pid", "path"]
    let criteriaKeys = locator.criteria.keys
    let isAppOnlyLocator = criteriaKeys.allSatisfy { appSpecifiers.contains($0) } && criteriaKeys.count == 1

    var foundElement: Element? = nil

    if isAppOnlyLocator {
        dLog("Locator is app-only (criteria: \(locator.criteria)). Using appElement directly.")
        foundElement = effectiveElement
    } else {
        dLog("Locator contains element-specific criteria or is complex. Proceeding with search.")
        var searchStartElementForLocator = appElement
        if let rootPathHint = locator.root_element_path_hint, !rootPathHint.isEmpty {
            dLog("Locator has root_element_path_hint: \(rootPathHint.joined(separator: " -> ")). Navigating from app element first.")
            // Pass logging parameters to navigateToElement
            guard let containerElement = navigateToElement(from: appElement, pathHint: rootPathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
                return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Container for locator not found via root_element_path_hint: \(rootPathHint.joined(separator: " -> "))", debug_logs: currentDebugLogs)
            }
            searchStartElementForLocator = containerElement
            dLog("Searching with locator within container found by root_element_path_hint: \(searchStartElementForLocator.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs))")
        } else {
            searchStartElementForLocator = effectiveElement
            dLog("Searching with locator from element (determined by main path_hint or app root): \(searchStartElementForLocator.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs))")
        }
        
        let finalSearchTarget = (cmd.path_hint != nil && !cmd.path_hint!.isEmpty) ? effectiveElement : searchStartElementForLocator
        
        // Pass logging parameters to search
        foundElement = search(
            element: finalSearchTarget,
            locator: locator,
            requireAction: locator.requireAction,
            maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_SEARCH,
            isDebugLoggingEnabled: isDebugLoggingEnabled,
            currentDebugLogs: &currentDebugLogs
        )
    }
    
    if let elementToQuery = foundElement {
        // Pass logging parameters to getElementAttributes
        var attributes = getElementAttributes(
            elementToQuery,
            requestedAttributes: cmd.attributes ?? [],
            forMultiDefault: false, 
            targetRole: locator.criteria[kAXRoleAttribute],
            outputFormat: cmd.output_format ?? .smart,
            isDebugLoggingEnabled: isDebugLoggingEnabled,
            currentDebugLogs: &currentDebugLogs
        )
        if cmd.output_format == .json_string {
            attributes = encodeAttributesToJSONStringRepresentation(attributes)
        }
        return QueryResponse(command_id: cmd.command_id, attributes: attributes, error: nil, debug_logs: currentDebugLogs)
    } else {
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "No element matches single query criteria with locator or app-only locator failed to resolve.", debug_logs: currentDebugLogs)
    }
}