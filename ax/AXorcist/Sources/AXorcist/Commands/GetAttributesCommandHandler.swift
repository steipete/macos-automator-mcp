import Foundation
import ApplicationServices
import AppKit

// Placeholder for GetAttributesCommand if it were a distinct struct
// public struct GetAttributesCommand: Codable { ... }

@MainActor
public func handleGetAttributes(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) throws -> QueryResponse {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    dLog("Handling get_attributes command for app: \(cmd.application ?? "focused app")")

    let appIdentifier = cmd.application ?? focusedApplicationKey
    guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
        let errorMessage = "Application not found: \(appIdentifier)"
        dLog("handleGetAttributes: \(errorMessage)")
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: errorMessage, debug_logs: currentDebugLogs)
    }

    // Find element to get attributes from
    var effectiveElement = appElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        dLog("handleGetAttributes: Navigating with path_hint: \(pathHint.joined(separator: " -> "))")
        if let navigatedElement = navigateToElement(from: effectiveElement, pathHint: pathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
            effectiveElement = navigatedElement
        } else {
            let errorMessage = "Element not found via path hint: \(pathHint.joined(separator: " -> "))"
            dLog("handleGetAttributes: \(errorMessage)")
            return QueryResponse(command_id: cmd.command_id, attributes: nil, error: errorMessage, debug_logs: currentDebugLogs)
        }
    }
    
    guard let locator = cmd.locator else {
        let errorMessage = "Locator not provided for get_attributes."
        dLog("handleGetAttributes: \(errorMessage)")
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: errorMessage, debug_logs: currentDebugLogs)
    }

    dLog("handleGetAttributes: Searching for element with locator: \(locator.criteria) from root: \(effectiveElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs))")
    let foundElement = search(
        element: effectiveElement, 
        locator: locator, 
        requireAction: locator.requireAction, 
        maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_SEARCH, 
        isDebugLoggingEnabled: isDebugLoggingEnabled, 
        currentDebugLogs: &currentDebugLogs
    )

    if let elementToQuery = foundElement {
        dLog("handleGetAttributes: Element found: \(elementToQuery.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)). Fetching attributes: \(cmd.attributes ?? ["all"])...")
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
        dLog("Successfully fetched attributes for element \(elementToQuery.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)).")
        return QueryResponse(command_id: cmd.command_id, attributes: attributes, error: nil, debug_logs: currentDebugLogs)
    } else {
        let errorMessage = "No element found for get_attributes with locator: \(String(describing: locator))"
        dLog("handleGetAttributes: \(errorMessage)")
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: errorMessage, debug_logs: currentDebugLogs)
    }
} 