import Foundation
import ApplicationServices
import AppKit

// @MainActor // Removed for testing test hang
public func handleGetFocusedElement(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) async throws -> QueryResponse {
    var handlerLogs: [String] = []
    func dLog(_ message: String) { if isDebugLoggingEnabled { handlerLogs.append(message) } }
    
    let focusedAppKeyValue = "focused" // Using string literal directly
    dLog("Handling get_focused_element command for app: \(cmd.application ?? focusedAppKeyValue)")

    let appIdentifier = cmd.application ?? focusedAppKeyValue
    // applicationElement is @MainActor and async
    guard let appElement = await applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &handlerLogs) else {
        return QueryResponse(command_id: cmd.command_id, attributes: nil, error: "Application not found for get_focused_element: \(appIdentifier)", debug_logs: isDebugLoggingEnabled ? handlerLogs : nil)
    }
    
    // This closure will run on the MainActor
    let focusedElementResult = await MainActor.run { () -> (element: AXUIElement?, error: String?, logs: [String]) in
        var mainActorLogs: [String] = []
        func maLog(_ message: String) { if isDebugLoggingEnabled { mainActorLogs.append(message) } }

        var cfValue: CFTypeRef? = nil
        let copyAttributeStatus = AXUIElementCopyAttributeValue(appElement.underlyingElement, kAXFocusedUIElementAttribute as CFString, &cfValue)

        if copyAttributeStatus == .success, let rawAXElement = cfValue {
            if CFGetTypeID(rawAXElement) == AXUIElementGetTypeID() {
                return (element: (rawAXElement as! AXUIElement), error: nil, logs: mainActorLogs)
            } else {
                let errorMsg = "Focused element attribute was not an AXUIElement. Application: \(appIdentifier)"
                maLog(errorMsg)
                return (element: nil, error: errorMsg, logs: mainActorLogs)
            }
        } else {
            let errorMsg = "Failed to copy focused element attribute or it was nil. Status: \(copyAttributeStatus.rawValue). Application: \(appIdentifier)"
            maLog(errorMsg)
            return (element: nil, error: errorMsg, logs: mainActorLogs)
        }
    }

    handlerLogs.append(contentsOf: focusedElementResult.logs)

    guard let finalFocusedAXElement = focusedElementResult.element else {
         return QueryResponse(command_id: cmd.command_id, attributes: nil, error: focusedElementResult.error ?? "Could not get the focused UI element for \(appIdentifier). Ensure a window of the application is focused.", debug_logs: isDebugLoggingEnabled ? handlerLogs : nil)
    }
    
    let focusedElement = Element(finalFocusedAXElement)
    // briefDescription is @MainActor and async
    let focusedElementDesc = await focusedElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &handlerLogs)
    dLog("Successfully obtained focused element: \(focusedElementDesc) for application \(appIdentifier)")

    var attributes = await getElementAttributes(
        focusedElement, 
        requestedAttributes: cmd.attributes ?? [], 
        forMultiDefault: false, 
        targetRole: nil, 
        outputFormat: cmd.output_format ?? .smart,
        isDebugLoggingEnabled: isDebugLoggingEnabled, 
        currentDebugLogs: &handlerLogs
    )
    if cmd.output_format == .json_string {
        attributes = await encodeAttributesToJSONStringRepresentation(attributes)
    }
    
    return QueryResponse(command_id: cmd.command_id, attributes: attributes, error: nil, debug_logs: isDebugLoggingEnabled ? handlerLogs : nil)
} 