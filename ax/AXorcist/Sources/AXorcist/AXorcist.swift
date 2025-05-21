import Foundation
import ApplicationServices
import AppKit

// Placeholder for the actual accessibility logic.
// For now, this module is very thin and AXorcist.swift is the main public API.
// Other files like Element.swift, Models.swift, Search.swift, etc. are in Core/ Utils/ etc.

public struct HandlerResponse {
    public var data: AXElement?
    public var error: String?
    public var debug_logs: [String]?

    public init(data: AXElement? = nil, error: String? = nil, debug_logs: [String]? = nil) {
        self.data = data
        self.error = error
        self.debug_logs = debug_logs
    }
}

public class AXorcist {

    private let focusedAppKeyValue = "focused"

    public init() {
        // Future initialization logic can go here.
        // For now, ensure debug logs can be collected if needed.
        // Note: The actual logging enable/disable should be managed per-call.
        // This init doesn't take global logging flags anymore.
    }

    // Placeholder for getting the focused element.
    // It should accept debug logging parameters and update logs.
    @MainActor
    public func handleGetFocusedElement(
        for appIdentifierOrNil: String? = nil,
        requestedAttributes: [String]? = nil,
        isDebugLoggingEnabled: Bool,
        currentDebugLogs: inout [String]
    ) -> HandlerResponse {
        func dLog(_ message: String) {
            if isDebugLoggingEnabled {
                currentDebugLogs.append(message)
            }
        }

        let appIdentifier = appIdentifierOrNil ?? focusedAppKeyValue
        dLog("[AXorcist.handleGetFocusedElement] Handling for app: \\(appIdentifier)")

        guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
            let errorMsgText = "Application not found: \\\\(appIdentifier)"
            dLog("[AXorcist.handleGetFocusedElement] \\\\(errorMsgText)")
            return HandlerResponse(data: nil, error: errorMsgText, debug_logs: currentDebugLogs)
        }
        dLog("[AXorcist.handleGetFocusedElement] Successfully obtained application element for \\\\(appIdentifier)")

        var cfValue: CFTypeRef?
        let copyAttributeStatus = AXUIElementCopyAttributeValue(appElement.underlyingElement, kAXFocusedUIElementAttribute as CFString, &cfValue)

        guard copyAttributeStatus == .success, let rawAXElement = cfValue else {
            dLog("[AXorcist.handleGetFocusedElement] Failed to copy focused element attribute or it was nil. Status: \\\\(axErrorToString(copyAttributeStatus)). Application: \\\\(appIdentifier)")
            return HandlerResponse(data: nil, error: "Could not get the focused UI element for \\\\(appIdentifier). Ensure a window of the application is focused. AXError: \\\\(axErrorToString(copyAttributeStatus))", debug_logs: currentDebugLogs)
        }
        
        guard CFGetTypeID(rawAXElement) == AXUIElementGetTypeID() else {
            dLog("[AXorcist.handleGetFocusedElement] Focused element attribute was not an AXUIElement. Application: \\\\(appIdentifier)")
            return HandlerResponse(data: nil, error: "Focused element was not a valid UI element for \\\\(appIdentifier).", debug_logs: currentDebugLogs)
        }

        let focusedElement = Element(rawAXElement as! AXUIElement)
        dLog("[AXorcist.handleGetFocusedElement] Successfully obtained focused element: \\(focusedElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)) for application \\\\(appIdentifier)")
        
        let fetchedAttributes = getElementAttributes(
            focusedElement,
            requestedAttributes: requestedAttributes ?? [],
            forMultiDefault: false,
            targetRole: nil,
            outputFormat: .smart,
            isDebugLoggingEnabled: isDebugLoggingEnabled,
            currentDebugLogs: &currentDebugLogs
        )
        
        let elementPathArray = focusedElement.generatePathArray(upTo: appElement, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        
        let axElement = AXElement(attributes: fetchedAttributes, path: elementPathArray)

        return HandlerResponse(data: axElement, error: nil, debug_logs: currentDebugLogs)
    }

    // Add other public API methods here as they are refactored or created.
    // For example:
    // public func handlePerformAction(...) async -> HandlerResponse { ... }
    // public func handleGetAttributes(...) async -> HandlerResponse { ... }
} 