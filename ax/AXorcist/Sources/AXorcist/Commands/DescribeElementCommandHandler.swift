import Foundation
import ApplicationServices
import AppKit

@MainActor
public func handleDescribeElement(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) throws -> QueryResponse {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    dLog("Handling describe_element command for app: \(cmd.application ?? "focused app")")

    let appIdentifier = cmd.application ?? focusedApplicationKey
    guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
        let errorMessage = "Application not found: \(appIdentifier)"
        dLog("handleDescribeElement: \(errorMessage)")
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: errorMessage, debug_logs: currentDebugLogs)
    }

    var effectiveElement = appElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        dLog("handleDescribeElement: Navigating with path_hint: \(pathHint.joined(separator: " -> "))")
        if let navigatedElement = navigateToElement(from: effectiveElement, pathHint: pathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
            effectiveElement = navigatedElement
        } else {
            let errorMessage = "Element not found via path hint for describe_element: \(pathHint.joined(separator: " -> "))"
            dLog("handleDescribeElement: \(errorMessage)")
            return QueryResponse(command_id: cmd.command_id, attributes: nil, error: errorMessage, debug_logs: currentDebugLogs)
        }
    }

    guard let locator = cmd.locator else {
        let errorMessage = "Locator not provided for describe_element."
        dLog("handleDescribeElement: \(errorMessage)")
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: errorMessage, debug_logs: currentDebugLogs)
    }

    dLog("handleDescribeElement: Searching for element with locator: \(locator.criteria) from root: \(effectiveElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs))")
    let foundElement = search(
        element: effectiveElement, 
        locator: locator, 
        requireAction: locator.requireAction, 
        maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_SEARCH, 
        isDebugLoggingEnabled: isDebugLoggingEnabled, 
        currentDebugLogs: &currentDebugLogs
    )

    if let elementToDescribe = foundElement {
        dLog("handleDescribeElement: Element found: \(elementToDescribe.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)). Describing with verbose output...")
        // For describe_element, we typically want ALL attributes, or a very comprehensive default set.
        // The `getElementAttributes` function will fetch all if `requestedAttributes` is empty.
        var attributes = getElementAttributes(
            elementToDescribe,
            requestedAttributes: [], // Requesting empty means 'all standard' or 'all known'
            forMultiDefault: false, 
            targetRole: locator.criteria[kAXRoleAttribute],
            outputFormat: .verbose, // Describe usually implies verbose
            isDebugLoggingEnabled: isDebugLoggingEnabled,
            currentDebugLogs: &currentDebugLogs
        )
         if cmd.output_format == .json_string {
            attributes = encodeAttributesToJSONStringRepresentation(attributes)
        }
        dLog("Successfully described element \(elementToDescribe.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)).")
        return QueryResponse(command_id: cmd.command_id, attributes: attributes, error: nil, debug_logs: currentDebugLogs)
    } else {
        let errorMessage = "No element found for describe_element with locator: \(String(describing: locator))"
        dLog("handleDescribeElement: \(errorMessage)")
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: errorMessage, debug_logs: currentDebugLogs)
    }
} 