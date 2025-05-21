import Foundation
import ApplicationServices
import AppKit

@MainActor
public func handleGetFocusedElement(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) throws -> QueryResponse {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    dLog("Handling get_focused_element command for app: \(cmd.application ?? "focused app")")

    let appIdentifier = cmd.application ?? focusedApplicationKey
    guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
        // applicationElement already logs the failure internally
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Application not found for get_focused_element: \(appIdentifier)", debug_logs: currentDebugLogs)
    }

    // Get the focused element from the application element
    var cfValue: CFTypeRef? = nil
    let copyAttributeStatus = AXUIElementCopyAttributeValue(appElement.underlyingElement, kAXFocusedUIElementAttribute as CFString, &cfValue)

    guard copyAttributeStatus == .success, let rawAXElement = cfValue else {
        dLog("Failed to copy focused element attribute or it was nil. Status: \(copyAttributeStatus.rawValue). Application: \(appIdentifier)")
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Could not get the focused UI element for \(appIdentifier). Ensure a window of the application is focused.", debug_logs: currentDebugLogs)
    }
    
    // Ensure it's an AXUIElement
    guard CFGetTypeID(rawAXElement) == AXUIElementGetTypeID() else {
        dLog("Focused element attribute was not an AXUIElement. Application: \(appIdentifier)")
         return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Focused element was not a valid UI element for \(appIdentifier).", debug_logs: currentDebugLogs)
    }

    let focusedElement = Element(rawAXElement as! AXUIElement)
    let focusedElementDesc = focusedElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
    dLog("Successfully obtained focused element: \(focusedElementDesc) for application \(appIdentifier)")

    var attributes = getElementAttributes(
        focusedElement,
        requestedAttributes: cmd.attributes ?? [], 
        forMultiDefault: false, 
        targetRole: nil, 
        outputFormat: cmd.output_format ?? .smart,
        isDebugLoggingEnabled: isDebugLoggingEnabled,
        currentDebugLogs: &currentDebugLogs
    )
    if cmd.output_format == .json_string {
        attributes = encodeAttributesToJSONStringRepresentation(attributes)
    }
    return QueryResponse(command_id: cmd.command_id, attributes: attributes, error: nil, debug_logs: currentDebugLogs)
} 