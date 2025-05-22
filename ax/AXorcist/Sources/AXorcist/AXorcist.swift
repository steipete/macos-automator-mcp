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
    private var recursiveCallDebugLogs: [String] = [] // Added for recursive logging

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
        dLog("[AXorcist.handleGetFocusedElement] Handling for app: \(appIdentifier)")

        guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
            let errorMsgText = "Application not found: \(appIdentifier)"
            dLog("[AXorcist.handleGetFocusedElement] \(errorMsgText)")
            return HandlerResponse(data: nil, error: errorMsgText, debug_logs: currentDebugLogs)
        }
        dLog("[AXorcist.handleGetFocusedElement] Successfully obtained application element for \(appIdentifier)")

        var cfValue: CFTypeRef?
        let copyAttributeStatus = AXUIElementCopyAttributeValue(appElement.underlyingElement, kAXFocusedUIElementAttribute as CFString, &cfValue)

        guard copyAttributeStatus == .success, let rawAXElement = cfValue else {
            dLog("[AXorcist.handleGetFocusedElement] Failed to copy focused element attribute or it was nil. Status: \(axErrorToString(copyAttributeStatus)). Application: \(appIdentifier)")
            return HandlerResponse(data: nil, error: "Could not get the focused UI element for \(appIdentifier). Ensure a window of the application is focused. AXError: \(axErrorToString(copyAttributeStatus))", debug_logs: currentDebugLogs)
        }
        
        guard CFGetTypeID(rawAXElement) == AXUIElementGetTypeID() else {
            dLog("[AXorcist.handleGetFocusedElement] Focused element attribute was not an AXUIElement. Application: \(appIdentifier)")
            return HandlerResponse(data: nil, error: "Focused element was not a valid UI element for \(appIdentifier).", debug_logs: currentDebugLogs)
        }

        let focusedElement = Element(rawAXElement as! AXUIElement)
        dLog("[AXorcist.handleGetFocusedElement] Successfully obtained focused element: \(focusedElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)) for application \(appIdentifier)")
        
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

    // Handle getting attributes for a specific element using locator
    @MainActor
    public func handleGetAttributes(
        for appIdentifierOrNil: String? = nil,
        locator: Locator,
        requestedAttributes: [String]? = nil,
        pathHint: [String]? = nil,
        maxDepth: Int? = nil,
        outputFormat: OutputFormat? = nil,
        isDebugLoggingEnabled: Bool,
        currentDebugLogs: inout [String]
    ) -> HandlerResponse {
        func dLog(_ message: String) {
            if isDebugLoggingEnabled {
                currentDebugLogs.append(message)
            }
        }

        let appIdentifier = appIdentifierOrNil ?? focusedAppKeyValue
        dLog("[AXorcist.handleGetAttributes] Handling for app: \(appIdentifier)")

        guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
            let errorMessage = "Application not found: \(appIdentifier)"
            dLog("[AXorcist.handleGetAttributes] \(errorMessage)")
            return HandlerResponse(data: nil, error: errorMessage, debug_logs: currentDebugLogs)
        }

        // Find element to get attributes from
        var effectiveElement = appElement
        if let pathHint = pathHint, !pathHint.isEmpty {
            let pathHintString = pathHint.joined(separator: " -> ")
            _ = pathHintString // Silences compiler warning
            let logMessage = "[AXorcist.handleGetAttributes] Navigating with path_hint: \(pathHintString)"
            dLog(logMessage)
            if let navigatedElement = navigateToElement(from: effectiveElement, pathHint: pathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
                effectiveElement = navigatedElement
            } else {
                let pathHintStringForError = pathHint.joined(separator: " -> ")
                _ = pathHintStringForError // Silences compiler warning
                let errorMessageText = "Element not found via path hint: \(pathHintStringForError)"
                dLog("[AXorcist.handleGetAttributes] \(errorMessageText)")
                return HandlerResponse(data: nil, error: errorMessageText, debug_logs: currentDebugLogs)
            }
        }

        let rootElementDescription = effectiveElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        _ = rootElementDescription // Silences compiler warning
        let searchLogMessage = "[AXorcist.handleGetAttributes] Searching for element with locator: \(locator.criteria) from root: \(rootElementDescription)"
        dLog(searchLogMessage)
        let foundElement = search(
            element: effectiveElement, 
            locator: locator, 
            requireAction: locator.requireAction, 
            maxDepth: maxDepth ?? DEFAULT_MAX_DEPTH_SEARCH, 
            isDebugLoggingEnabled: isDebugLoggingEnabled, 
            currentDebugLogs: &currentDebugLogs
        )

        if let elementToQuery = foundElement {
            let elementDescription = elementToQuery.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            _ = elementDescription // Silences compiler warning
            let attributesDescription = (requestedAttributes ?? ["all"]).description
            _ = attributesDescription // Silences compiler warning
            let foundElementLogMessage = "[AXorcist.handleGetAttributes] Element found: \(elementDescription). Fetching attributes: \(attributesDescription)..."
            dLog(foundElementLogMessage)
            var attributes = getElementAttributes(
                elementToQuery,
                requestedAttributes: requestedAttributes ?? [],
                forMultiDefault: false, 
                targetRole: locator.criteria[kAXRoleAttribute],
                outputFormat: outputFormat ?? .smart,
                isDebugLoggingEnabled: isDebugLoggingEnabled,
                currentDebugLogs: &currentDebugLogs
            )
            if outputFormat == .json_string {
                attributes = encodeAttributesToJSONStringRepresentation(attributes)
            }
            
            let elementPathArray = elementToQuery.generatePathArray(upTo: appElement, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            let axElement = AXElement(attributes: attributes, path: elementPathArray)
            
            dLog("[AXorcist.handleGetAttributes] Successfully fetched attributes for element \(elementToQuery.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)).")
            return HandlerResponse(data: axElement, error: nil, debug_logs: currentDebugLogs)
        } else {
            let errorMessage = "No element found for get_attributes with locator: \(String(describing: locator))"
            dLog("[AXorcist.handleGetAttributes] \(errorMessage)")
            return HandlerResponse(data: nil, error: errorMessage, debug_logs: currentDebugLogs)
        }
    }

    // Handle query command - find an element matching criteria
    @MainActor
    public func handleQuery(
        for appIdentifierOrNil: String? = nil,
        locator: Locator,
        pathHint: [String]? = nil,
        maxDepth: Int? = nil,
        requestedAttributes: [String]? = nil,
        outputFormat: OutputFormat? = nil,
        isDebugLoggingEnabled: Bool,
        currentDebugLogs: inout [String]
    ) -> HandlerResponse {
        func dLog(_ message: String) {
            if isDebugLoggingEnabled {
                currentDebugLogs.append(message)
            }
        }

        let appIdentifier = appIdentifierOrNil ?? focusedAppKeyValue
        dLog("[AXorcist.handleQuery] Handling query for app: \(appIdentifier)")

        guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
            let errorMessage = "Application not found: \(appIdentifier)"
            dLog("[AXorcist.handleQuery] \(errorMessage)")
            return HandlerResponse(data: nil, error: errorMessage, debug_logs: currentDebugLogs)
        }

        var effectiveElement = appElement
        if let pathHint = pathHint, !pathHint.isEmpty {
            let pathHintString = pathHint.joined(separator: " -> ")
            _ = pathHintString // Silences compiler warning
            dLog("[AXorcist.handleQuery] Navigating with path_hint: \(pathHintString)")
            if let navigatedElement = navigateToElement(from: effectiveElement, pathHint: pathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
                effectiveElement = navigatedElement
            } else {
                let errorMessage = "Element not found via path hint: \(pathHintString)"
                dLog("[AXorcist.handleQuery] \(errorMessage)")
                return HandlerResponse(data: nil, error: errorMessage, debug_logs: currentDebugLogs)
            }
        }

        // Check if this is an app-only locator (only application/bundle_id/pid/path criteria)
        let appSpecifiers = ["application", "bundle_id", "pid", "path"]
        let criteriaKeys = locator.criteria.keys
        let isAppOnlyLocator = criteriaKeys.allSatisfy { appSpecifiers.contains($0) } && criteriaKeys.count == 1

        var foundElement: Element? = nil

        if isAppOnlyLocator {
            dLog("[AXorcist.handleQuery] Locator is app-only (criteria: \(locator.criteria)). Using appElement directly.")
            foundElement = effectiveElement
        } else {
            dLog("[AXorcist.handleQuery] Locator contains element-specific criteria. Proceeding with search.")
            var searchStartElementForLocator = appElement
            
            if let rootPathHint = locator.root_element_path_hint, !rootPathHint.isEmpty {
                let rootPathHintString = rootPathHint.joined(separator: " -> ")
                _ = rootPathHintString // Silences compiler warning
                dLog("[AXorcist.handleQuery] Locator has root_element_path_hint: \(rootPathHintString). Navigating from app element first.")
                guard let containerElement = navigateToElement(from: appElement, pathHint: rootPathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
                    let errorMessage = "Container for locator not found via root_element_path_hint: \(rootPathHintString)"
                    dLog("[AXorcist.handleQuery] \(errorMessage)")
                    return HandlerResponse(data: nil, error: errorMessage, debug_logs: currentDebugLogs)
                }
                searchStartElementForLocator = containerElement
                let containerDescription = searchStartElementForLocator.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
                _ = containerDescription // Silences compiler warning
                dLog("[AXorcist.handleQuery] Searching with locator within container found by root_element_path_hint: \(containerDescription)")
            } else {
                searchStartElementForLocator = effectiveElement
                let searchDescription = searchStartElementForLocator.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
                _ = searchDescription // Silences compiler warning
                dLog("[AXorcist.handleQuery] Searching with locator from element (determined by main path_hint or app root): \(searchDescription)")
            }
            
            let finalSearchTarget = (pathHint != nil && !pathHint!.isEmpty) ? effectiveElement : searchStartElementForLocator
            
            foundElement = search(
                element: finalSearchTarget,
                locator: locator,
                requireAction: locator.requireAction,
                maxDepth: maxDepth ?? DEFAULT_MAX_DEPTH_SEARCH,
                isDebugLoggingEnabled: isDebugLoggingEnabled,
                currentDebugLogs: &currentDebugLogs
            )
        }
        
        if let elementToQuery = foundElement {
            let elementDescription = elementToQuery.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            _ = elementDescription // Silences compiler warning
            dLog("[AXorcist.handleQuery] Element found: \(elementDescription). Fetching attributes...")
            
            var attributes = getElementAttributes(
                elementToQuery,
                requestedAttributes: requestedAttributes ?? [],
                forMultiDefault: false, 
                targetRole: locator.criteria[kAXRoleAttribute],
                outputFormat: outputFormat ?? .smart,
                isDebugLoggingEnabled: isDebugLoggingEnabled,
                currentDebugLogs: &currentDebugLogs
            )
            
            if outputFormat == .json_string {
                attributes = encodeAttributesToJSONStringRepresentation(attributes)
            }
            
            let elementPathArray = elementToQuery.generatePathArray(upTo: appElement, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            let axElement = AXElement(attributes: attributes, path: elementPathArray)
            
            dLog("[AXorcist.handleQuery] Successfully found and processed element with query.")
            return HandlerResponse(data: axElement, error: nil, debug_logs: currentDebugLogs)
        } else {
            let errorMessage = "No element matches query criteria with locator: \(String(describing: locator))"
            dLog("[AXorcist.handleQuery] \(errorMessage)")
            return HandlerResponse(data: nil, error: errorMessage, debug_logs: currentDebugLogs)
        }
    }

    // Handle describe element command - provides comprehensive details about a specific element
    @MainActor
    public func handleDescribeElement(
        for appIdentifierOrNil: String? = nil,
        locator: Locator,
        pathHint: [String]? = nil,
        maxDepth: Int? = nil,
        outputFormat: OutputFormat? = nil,
        isDebugLoggingEnabled: Bool,
        currentDebugLogs: inout [String]
    ) -> HandlerResponse {
        func dLog(_ message: String) {
            if isDebugLoggingEnabled {
                currentDebugLogs.append(message)
            }
        }

        let appIdentifier = appIdentifierOrNil ?? focusedAppKeyValue
        dLog("[AXorcist.handleDescribeElement] Handling for app: \(appIdentifier)")

        guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
            let errorMessage = "Application not found: \(appIdentifier)"
            dLog("[AXorcist.handleDescribeElement] \(errorMessage)")
            return HandlerResponse(data: nil, error: errorMessage, debug_logs: currentDebugLogs)
        }

        var effectiveElement = appElement
        if let pathHint = pathHint, !pathHint.isEmpty {
            let pathHintString = pathHint.joined(separator: " -> ")
            _ = pathHintString // Silences compiler warning
            dLog("[AXorcist.handleDescribeElement] Navigating with path_hint: \(pathHintString)")
            if let navigatedElement = navigateToElement(from: effectiveElement, pathHint: pathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
                effectiveElement = navigatedElement
            } else {
                let errorMessage = "Element not found via path hint for describe_element: \(pathHintString)"
                dLog("[AXorcist.handleDescribeElement] \(errorMessage)")
                return HandlerResponse(data: nil, error: errorMessage, debug_logs: currentDebugLogs)
            }
        }

        let rootElementDescription = effectiveElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        _ = rootElementDescription // Silences compiler warning
        dLog("[AXorcist.handleDescribeElement] Searching for element with locator: \(locator.criteria) from root: \(rootElementDescription)")
        let foundElement = search(
            element: effectiveElement, 
            locator: locator, 
            requireAction: locator.requireAction, 
            maxDepth: maxDepth ?? DEFAULT_MAX_DEPTH_SEARCH, 
            isDebugLoggingEnabled: isDebugLoggingEnabled, 
            currentDebugLogs: &currentDebugLogs
        )

        if let elementToDescribe = foundElement {
            let elementDescription = elementToDescribe.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            _ = elementDescription // Silences compiler warning
            dLog("[AXorcist.handleDescribeElement] Element found: \(elementDescription). Describing with verbose output...")
            
            // For describe_element, we typically want ALL attributes with verbose output
            var attributes = getElementAttributes(
                elementToDescribe,
                requestedAttributes: [], // Empty means 'all standard' or 'all known'
                forMultiDefault: false, 
                targetRole: locator.criteria[kAXRoleAttribute],
                outputFormat: .verbose, // Describe implies verbose
                isDebugLoggingEnabled: isDebugLoggingEnabled,
                currentDebugLogs: &currentDebugLogs
            )
            
            if outputFormat == .json_string {
                attributes = encodeAttributesToJSONStringRepresentation(attributes)
            }
            
            let elementPathArray = elementToDescribe.generatePathArray(upTo: appElement, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
            let axElement = AXElement(attributes: attributes, path: elementPathArray)
            
            dLog("[AXorcist.handleDescribeElement] Successfully described element \(elementToDescribe.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)).")
            return HandlerResponse(data: axElement, error: nil, debug_logs: currentDebugLogs)
        } else {
            let errorMessage = "No element found for describe_element with locator: \(String(describing: locator))"
            dLog("[AXorcist.handleDescribeElement] \(errorMessage)")
            return HandlerResponse(data: nil, error: errorMessage, debug_logs: currentDebugLogs)
        }
    }

    // Add other public API methods here as they are refactored or created.
    // For example:
    // public func handlePerformAction(...) async -> HandlerResponse { ... }

    @MainActor
    public func handlePerformAction(
        for appIdentifierOrNil: String? = nil,
        locator: Locator,
        pathHint: [String]? = nil,
        actionName: String,
        actionValue: AnyCodable?,
        maxDepth: Int? = nil,
        isDebugLoggingEnabled: Bool,
        currentDebugLogs: inout [String]
    ) -> HandlerResponse {
        
        func dLog(_ message: String) {
            if isDebugLoggingEnabled {
                currentDebugLogs.append(message)
            }
        }
        
        let appIdentifier = appIdentifierOrNil ?? focusedAppKeyValue
        dLog("[AXorcist.handlePerformAction] Handling for app: \(appIdentifier), action: \(actionName)")

        guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
            let error = "[AXorcist.handlePerformAction] Failed to get application element for identifier: \(appIdentifier)"
            dLog(error)
            return HandlerResponse(data: nil, error: error, debug_logs: currentDebugLogs)
        }
        
        var effectiveElement = appElement
        
        if let pathHint = pathHint, !pathHint.isEmpty {
            dLog("[AXorcist.handlePerformAction] Navigating with path_hint: \(pathHint.joined(separator: " -> "))")
            guard let navigatedElement = navigateToElement(from: effectiveElement, pathHint: pathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
                let error = "[AXorcist.handlePerformAction] Failed to navigate using path hint: \(pathHint.joined(separator: " -> "))"
                dLog(error)
                return HandlerResponse(data: nil, error: error, debug_logs: currentDebugLogs)
            }
            effectiveElement = navigatedElement
        }
        
        dLog("[AXorcist.handlePerformAction] Searching for element with locator: \(locator.criteria) from root: \(effectiveElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs))")
        guard let foundElement = search(element: effectiveElement, locator: locator, requireAction: locator.requireAction, maxDepth: maxDepth ?? DEFAULT_MAX_DEPTH_SEARCH, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
            let error = "[AXorcist.handlePerformAction] Failed to find element with locator: \(locator)"
            dLog(error)
            return HandlerResponse(data: nil, error: error, debug_logs: currentDebugLogs)
        }
        
        dLog("[AXorcist.handlePerformAction] Found element: \(foundElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs))")
        if let actionValue = actionValue {
            // Attempt to get a string representation of actionValue.value for logging
            // This is a basic attempt; complex types might not log well.
            let valueDescription = String(describing: actionValue.value)
            dLog("[AXorcist.handlePerformAction] Performing action '\(actionName)' with value: \(valueDescription)")
        } else {
            dLog("[AXorcist.handlePerformAction] Performing action '\(actionName)'")
        }
        
        var errorMessage: String?
        var axStatus: AXError = .success // Initialize to success
        
        switch actionName.lowercased() {
        case "press":
            axStatus = AXUIElementPerformAction(foundElement.underlyingElement, kAXPressAction as CFString)
            if axStatus != .success {
                errorMessage = "[AXorcist.handlePerformAction] Failed to perform press action: \(axErrorToString(axStatus))"
            }
        case "increment":
            axStatus = AXUIElementPerformAction(foundElement.underlyingElement, kAXIncrementAction as CFString)
            if axStatus != .success {
                errorMessage = "[AXorcist.handlePerformAction] Failed to perform increment action: \(axErrorToString(axStatus))"
            }
        case "decrement":
            axStatus = AXUIElementPerformAction(foundElement.underlyingElement, kAXDecrementAction as CFString)
            if axStatus != .success {
                errorMessage = "[AXorcist.handlePerformAction] Failed to perform decrement action: \(axErrorToString(axStatus))"
            }
        case "showmenu":
            axStatus = AXUIElementPerformAction(foundElement.underlyingElement, kAXShowMenuAction as CFString)
            if axStatus != .success {
                errorMessage = "[AXorcist.handlePerformAction] Failed to perform showmenu action: \(axErrorToString(axStatus))"
            }
        case "pick":
            axStatus = AXUIElementPerformAction(foundElement.underlyingElement, kAXPickAction as CFString)
            if axStatus != .success {
                errorMessage = "[AXorcist.handlePerformAction] Failed to perform pick action: \(axErrorToString(axStatus))"
            }
        case "cancel":
            axStatus = AXUIElementPerformAction(foundElement.underlyingElement, kAXCancelAction as CFString)
            if axStatus != .success {
                errorMessage = "[AXorcist.handlePerformAction] Failed to perform cancel action: \(axErrorToString(axStatus))"
            }
        default:
            if actionName.hasPrefix("AX") {
                axStatus = AXUIElementPerformAction(foundElement.underlyingElement, actionName as CFString)
                if axStatus != .success {
                    errorMessage = "[AXorcist.handlePerformAction] Failed to perform action '\(actionName)': \(axErrorToString(axStatus))"
                }
            } else {
                if let actionValue = actionValue {
                    var cfValue: CFTypeRef?
                    // Convert basic Swift types to CFTypeRef for setting attributes
                    switch actionValue.value {
                    case let stringValue as String:
                        cfValue = stringValue as CFString
                    case let boolValue as Bool:
                        cfValue = boolValue as CFBoolean
                    case let intValue as Int:
                        var number = intValue
                        cfValue = CFNumberCreate(kCFAllocatorDefault, .intType, &number)
                    case let doubleValue as Double:
                        var number = doubleValue
                        cfValue = CFNumberCreate(kCFAllocatorDefault, .doubleType, &number)
                    // TODO: Consider other CFNumber types if necessary (CGFloat, etc.)
                    // TODO: Consider CFArray, CFDictionary if complex values are needed.
                    default:
                        // For other types, attempt a direct cast if possible, or log/error.
                        // This is a simplification; robust conversion is more involved.
                        if CFGetTypeID(actionValue.value as AnyObject) != 0 { // Basic check if it *might* be a CFType
                             cfValue = actionValue.value as AnyObject // bridge from Any to AnyObject then to CFTypeRef
                             dLog("[AXorcist.handlePerformAction] Warning: Attempting to use actionValue of type '\(type(of: actionValue.value))' directly as CFTypeRef for attribute '\(actionName)'. This might not work as expected.")
                        } else {
                            errorMessage = "[AXorcist.handlePerformAction] Unsupported value type '\(type(of: actionValue.value))' for attribute '\(actionName)'. Cannot convert to CFTypeRef."
                            dLog(errorMessage!)
                        }
                    }
                    
                    if errorMessage == nil, let finalCFValue = cfValue {
                        axStatus = AXUIElementSetAttributeValue(foundElement.underlyingElement, actionName as CFString, finalCFValue)
                        if axStatus != .success {
                            errorMessage = "[AXorcist.handlePerformAction] Failed to set attribute '\(actionName)' to value '\(String(describing: actionValue.value))': \(axErrorToString(axStatus))"
                        }
                    } else if errorMessage == nil { // cfValue was nil, means conversion failed earlier but wasn't caught by the default error
                         errorMessage = "[AXorcist.handlePerformAction] Failed to convert value for attribute '\(actionName)' to a CoreFoundation type."
                    }
                } else {
                    errorMessage = "[AXorcist.handlePerformAction] Unknown action '\(actionName)' and no action_value provided to interpret as an attribute."
                }
            }
        }
        
        if let currentErrorMessage = errorMessage {
            dLog(currentErrorMessage)
            return HandlerResponse(data: nil, error: currentErrorMessage, debug_logs: currentDebugLogs)
        }
        
        dLog("[AXorcist.handlePerformAction] Action '\(actionName)' performed successfully.")
        return HandlerResponse(data: nil, error: nil, debug_logs: currentDebugLogs)
    }

    @MainActor
    public func handleExtractText(
        for appIdentifierOrNil: String? = nil,
        locator: Locator,
        pathHint: [String]? = nil,
        isDebugLoggingEnabled: Bool,
        currentDebugLogs: inout [String]
    ) -> HandlerResponse {
        func dLog(_ message: String) {
            if isDebugLoggingEnabled {
                currentDebugLogs.append("[handleExtractText] \(message)")
            }
        }

        let appIdentifier = appIdentifierOrNil ?? focusedAppKeyValue
        dLog("Starting text extraction for app: \(appIdentifier)")

        guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
            let errorMessage = "Failed to get application element for \(appIdentifier)"
            dLog(errorMessage)
            return HandlerResponse(data: nil, error: errorMessage, debug_logs: currentDebugLogs)
        }

        var effectiveElement = appElement
        if let pathHint = pathHint, !pathHint.isEmpty {
            dLog("Navigating to element using path hint: \(pathHint.joined(separator: " -> "))")
            guard let navigatedElement = navigateToElement(from: appElement, pathHint: pathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
                let errorMessage = "Failed to navigate to element using path hint: \(pathHint.joined(separator: " -> "))"
                dLog(errorMessage)
                return HandlerResponse(data: nil, error: errorMessage, debug_logs: currentDebugLogs)
            }
            effectiveElement = navigatedElement
        }

        dLog("Searching for target element with locator: \(locator)")
        // Assuming DEFAULT_MAX_DEPTH_SEARCH is defined elsewhere, e.g., in AXConstants.swift or similar.
        // If not, replace with a sensible default like 10.
        guard let foundElement = search(element: effectiveElement, locator: locator, requireAction: locator.requireAction, maxDepth: DEFAULT_MAX_DEPTH_SEARCH, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
            let errorMessage = "Target element not found for locator: \(locator)"
            dLog(errorMessage)
            return HandlerResponse(data: nil, error: errorMessage, debug_logs: currentDebugLogs)
        }

        dLog("Target element found: \(foundElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)), attempting to extract text")
        var attributes: [String: AnyCodable] = [:]
        var extractedValueText: String?
        var extractedSelectedText: String?

        var cfValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(foundElement.underlyingElement, kAXValueAttribute as CFString, &cfValue) == .success, let value = cfValue {
            if CFGetTypeID(value) == CFStringGetTypeID() {
                extractedValueText = (value as! CFString) as String
                if let extractedValueText = extractedValueText, !extractedValueText.isEmpty {
                     attributes["extractedValue"] = AnyCodable(extractedValueText)
                     dLog("Extracted text from kAXValueAttribute (length: \(extractedValueText.count)): \(extractedValueText.prefix(80))...")
                } else {
                    dLog("kAXValueAttribute was empty or not a string.")
                }
            } else {
                 dLog("kAXValueAttribute was present but not a CFString. TypeID: \(CFGetTypeID(value))")
            }
        } else {
            dLog("Failed to get kAXValueAttribute or it was nil.")
        }
        
        cfValue = nil // Reset for next attribute
        if AXUIElementCopyAttributeValue(foundElement.underlyingElement, kAXSelectedTextAttribute as CFString, &cfValue) == .success, let selectedValue = cfValue {
            if CFGetTypeID(selectedValue) == CFStringGetTypeID() {
                extractedSelectedText = (selectedValue as! CFString) as String
                if let extractedSelectedText = extractedSelectedText, !extractedSelectedText.isEmpty {
                    attributes["extractedSelectedText"] = AnyCodable(extractedSelectedText)
                    dLog("Extracted selected text from kAXSelectedTextAttribute (length: \(extractedSelectedText.count)): \(extractedSelectedText.prefix(80))...")
                } else {
                    dLog("kAXSelectedTextAttribute was empty or not a string.")
                }
            } else {
                dLog("kAXSelectedTextAttribute was present but not a CFString. TypeID: \(CFGetTypeID(selectedValue))")
            }
        } else {
            dLog("Failed to get kAXSelectedTextAttribute or it was nil.")
        }


        if attributes.isEmpty {
            dLog("Warning: No text could be extracted from the element via kAXValueAttribute or kAXSelectedTextAttribute.")
            // It's not an error, just means no text content via these primary attributes.
            // Other attributes might still be relevant, so we return the element.
        }

        let elementPathArray = foundElement.generatePathArray(upTo: appElement, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs)
        // Include any other relevant attributes if needed, for now just the extracted text
        let axElement = AXElement(attributes: attributes, path: elementPathArray)

        dLog("Text extraction process completed.")
        return HandlerResponse(data: axElement, error: nil, debug_logs: currentDebugLogs)
    }

    @MainActor
    public func handleBatchCommands(
        batchCommandID: String, // The ID of the overall batch command
        subCommands: [CommandEnvelope], // The array of sub-commands to process
        isDebugLoggingEnabled: Bool,
        currentDebugLogs: inout [String]
    ) -> [HandlerResponse] {
        // Local debug logging function
        func dLog(_ message: String, subCommandID: String? = nil) {
            if isDebugLoggingEnabled {
                let prefix = subCommandID != nil ? "[AXorcist.handleBatchCommands][SubCmdID: \(subCommandID!)]" : "[AXorcist.handleBatchCommands][BatchID: \(batchCommandID)]"
                currentDebugLogs.append("\(prefix) \(message)")
            }
        }

        dLog("Starting batch processing with \(subCommands.count) sub-commands.")

        var batchResults: [HandlerResponse] = []

        for subCommandEnvelope in subCommands {
            let subCmdID = subCommandEnvelope.command_id
            // Create a temporary log array for this specific sub-command to pass to handlers if needed,
            // or decide if currentDebugLogs should be directly mutated by sub-handlers and reflect cumulative logs.
            // For simplicity here, let's assume sub-handlers append to the main currentDebugLogs.
            dLog("Processing sub-command: \(subCmdID), type: \(subCommandEnvelope.command)", subCommandID: subCmdID)
            
            var subCommandResponse: HandlerResponse

            switch subCommandEnvelope.command {
            case .getFocusedElement:
                subCommandResponse = self.handleGetFocusedElement(
                    for: subCommandEnvelope.application,
                    requestedAttributes: subCommandEnvelope.attributes,
                    isDebugLoggingEnabled: isDebugLoggingEnabled,
                    currentDebugLogs: &currentDebugLogs // Pass the main log array
                )
            
            case .getAttributes:
                guard let locator = subCommandEnvelope.locator else {
                    let errorMsg = "Locator missing for getAttributes in batch (sub-command ID: \(subCmdID))"
                    dLog(errorMsg, subCommandID: subCmdID)
                    subCommandResponse = HandlerResponse(data: nil, error: errorMsg, debug_logs: nil) // Keep debug_logs nil for specific error, main logs will have the dLog entry
                    break
                }
                subCommandResponse = self.handleGetAttributes(
                    for: subCommandEnvelope.application,
                    locator: locator,
                    requestedAttributes: subCommandEnvelope.attributes,
                    pathHint: subCommandEnvelope.path_hint,
                    maxDepth: subCommandEnvelope.max_elements,
                    outputFormat: subCommandEnvelope.output_format,
                    isDebugLoggingEnabled: isDebugLoggingEnabled,
                    currentDebugLogs: &currentDebugLogs
                )
                
            case .query:
                guard let locator = subCommandEnvelope.locator else {
                    let errorMsg = "Locator missing for query in batch (sub-command ID: \(subCmdID))"
                    dLog(errorMsg, subCommandID: subCmdID)
                    subCommandResponse = HandlerResponse(data: nil, error: errorMsg, debug_logs: nil)
                    break
                }
                subCommandResponse = self.handleQuery(
                    for: subCommandEnvelope.application,
                    locator: locator,
                    pathHint: subCommandEnvelope.path_hint,
                    maxDepth: subCommandEnvelope.max_elements,
                    requestedAttributes: subCommandEnvelope.attributes,
                    outputFormat: subCommandEnvelope.output_format,
                    isDebugLoggingEnabled: isDebugLoggingEnabled,
                    currentDebugLogs: &currentDebugLogs
                )
                
            case .describeElement:
                guard let locator = subCommandEnvelope.locator else {
                    let errorMsg = "Locator missing for describeElement in batch (sub-command ID: \(subCmdID))"
                    dLog(errorMsg, subCommandID: subCmdID)
                    subCommandResponse = HandlerResponse(data: nil, error: errorMsg, debug_logs: nil)
                    break
                }
                subCommandResponse = self.handleDescribeElement(
                    for: subCommandEnvelope.application,
                    locator: locator,
                    pathHint: subCommandEnvelope.path_hint,
                    maxDepth: subCommandEnvelope.max_elements,
                    outputFormat: subCommandEnvelope.output_format,
                    isDebugLoggingEnabled: isDebugLoggingEnabled,
                    currentDebugLogs: &currentDebugLogs
                )
                
            case .performAction:
                guard let locator = subCommandEnvelope.locator else {
                    let errorMsg = "Locator missing for performAction in batch (sub-command ID: \(subCmdID))"
                    dLog(errorMsg, subCommandID: subCmdID)
                    subCommandResponse = HandlerResponse(data: nil, error: errorMsg, debug_logs: nil)
                    break
                }
                guard let actionName = subCommandEnvelope.action_name else {
                    let errorMsg = "Action name missing for performAction in batch (sub-command ID: \(subCmdID))"
                    dLog(errorMsg, subCommandID: subCmdID)
                    subCommandResponse = HandlerResponse(data: nil, error: errorMsg, debug_logs: nil)
                    break
                }
                subCommandResponse = self.handlePerformAction(
                    for: subCommandEnvelope.application,
                    locator: locator,
                    pathHint: subCommandEnvelope.path_hint,
                    actionName: actionName,
                    actionValue: subCommandEnvelope.action_value,
                    maxDepth: subCommandEnvelope.max_elements, // Added maxDepth, though performAction doesn't currently use it directly, for consistency
                    isDebugLoggingEnabled: isDebugLoggingEnabled,
                    currentDebugLogs: &currentDebugLogs
                )
                
            case .extractText:
                guard let locator = subCommandEnvelope.locator else {
                    let errorMsg = "Locator missing for extractText in batch (sub-command ID: \(subCmdID))"
                    dLog(errorMsg, subCommandID: subCmdID)
                    subCommandResponse = HandlerResponse(data: nil, error: errorMsg, debug_logs: nil)
                    break
                }
                subCommandResponse = self.handleExtractText(
                    for: subCommandEnvelope.application,
                    locator: locator,
                    pathHint: subCommandEnvelope.path_hint,
                    isDebugLoggingEnabled: isDebugLoggingEnabled,
                    currentDebugLogs: &currentDebugLogs
                )
                
            case .ping:
                let pingMsg = "Ping command handled within batch (sub-command ID: \(subCmdID))"
                dLog(pingMsg, subCommandID: subCmdID)
                // For ping, the handlerResponse itself won't carry much data from AXorcist, 
                // but it should indicate success and carry the logs up to this point for this sub-command.
                subCommandResponse = HandlerResponse(data: nil, error: nil, debug_logs: isDebugLoggingEnabled ? currentDebugLogs : nil)
            
            // .batch command cannot be nested. .collectAll is also not handled by AXorcist lib directly.
            case .collectAll, .batch:
                let errorMsg = "Command type '\(subCommandEnvelope.command)' not supported within batch execution by AXorcist (sub-command ID: \(subCmdID))"
                dLog(errorMsg, subCommandID: subCmdID)
                subCommandResponse = HandlerResponse(data: nil, error: errorMsg, debug_logs: nil)
                
            // default case for any command types that might be added to CommandType enum 
            // but not handled by this switch statement within handleBatchCommands.
            // This is distinct from commands axorc itself might handle outside of AXorcist library.
            // @unknown default: // This would be better if Swift enums allowed it easily here for non-frozen enums from other modules.
            // Since CommandType is in axorc, this default captures any CommandType case not explicitly handled above.
            default:
                let errorMsg = "Unknown or unhandled command type '\(subCommandEnvelope.command)' in batch processing within AXorcist (sub-command ID: \(subCmdID))"
                dLog(errorMsg, subCommandID: subCmdID)
                subCommandResponse = HandlerResponse(data: nil, error: errorMsg, debug_logs: nil)
            }
            batchResults.append(subCommandResponse)
        }

        dLog("Completed batch command processing, returning \(batchResults.count) results.")
        return batchResults
    }

    @MainActor
    public func handleCollectAll(
        for appIdentifierOrNil: String?,
        locator: Locator?,
        pathHint: [String]?,
        maxDepth: Int?,
        requestedAttributes: [String]?,
        outputFormat: OutputFormat?,
        isDebugLoggingEnabled: Bool,
        currentDebugLogs: [String] // No longer inout, logs from caller
    ) -> HandlerResponse {
        self.recursiveCallDebugLogs.removeAll()
        self.recursiveCallDebugLogs.append(contentsOf: currentDebugLogs) // Incorporate initial logs

        // Local dLog now appends to self.recursiveCallDebugLogs
        func dLog(_ message: String) {
            if isDebugLoggingEnabled {
                let logMessage = "[AXorcist.handleCollectAll] \(message)"
                self.recursiveCallDebugLogs.append(logMessage)
            }
        }

        dLog("Starting handleCollectAll")

        let appIdentifier = appIdentifierOrNil ?? focusedAppKeyValue
        dLog("Using app identifier: \(appIdentifier)")

        guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &self.recursiveCallDebugLogs) else {
            let errorMsg = "Failed to get app element for identifier: \(appIdentifier)"
            dLog(errorMsg)
            // Return all accumulated logs up to this point
            return HandlerResponse(data: nil, error: errorMsg, debug_logs: self.recursiveCallDebugLogs)
        }

        var startElement: Element
        if let hint = pathHint, !hint.isEmpty {
            dLog("Navigating to path hint: \(hint.joined(separator: " -> "))")
            guard let navigatedElement = navigateToElement(from: appElement, pathHint: hint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &self.recursiveCallDebugLogs) else {
                let errorMsg = "Failed to navigate to path: \(hint.joined(separator: " -> "))"
                dLog(errorMsg)
                return HandlerResponse(data: nil, error: errorMsg, debug_logs: self.recursiveCallDebugLogs)
            }
            startElement = navigatedElement
        } else {
            dLog("Using app element as start element")
            startElement = appElement
        }

        var collectedAXElements: [AXElement] = []
        let effectiveMaxDepth = maxDepth ?? 8 
        dLog("Max collection depth: \(effectiveMaxDepth)")

        var collectRecursively: ((AXUIElement, Int) -> Void)!
        collectRecursively = { axUIElement, currentDepth in
            if currentDepth > effectiveMaxDepth {
                // Pass &self.recursiveCallDebugLogs to briefDescription
                dLog("Reached max depth \(effectiveMaxDepth) at element \(Element(axUIElement).briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &self.recursiveCallDebugLogs)), stopping recursion for this branch.")
                return
            }
            
            let currentElement = Element(axUIElement)
            
            var shouldIncludeElement = true // Default to include if no locator
            if let loc = locator {
                let matchStatus = evaluateElementAgainstCriteria(
                    element: currentElement,
                    locator: loc,
                    actionToVerify: loc.requireAction, // Pass requireAction from locator
                    depth: currentDepth,               // Pass currentDepth
                    isDebugLoggingEnabled: isDebugLoggingEnabled,
                    currentDebugLogs: &self.recursiveCallDebugLogs
                )
                if matchStatus != .fullMatch {
                    shouldIncludeElement = false
                    // Log if not a full match, but still recurse for children
                    dLog("Element \(currentElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &self.recursiveCallDebugLogs)) at depth \(currentDepth) did not fully match locator (status: \(matchStatus)), not collecting it.")
                 }
            }
            
            if shouldIncludeElement {
                dLog("Collecting element \(currentElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &self.recursiveCallDebugLogs)) at depth \(currentDepth)")
                
                let fetchedAttrs = getElementAttributes(
                    currentElement,
                    requestedAttributes: requestedAttributes ?? [],
                    forMultiDefault: true, 
                    targetRole: nil as String?,
                    outputFormat: outputFormat ?? .smart,
                    isDebugLoggingEnabled: isDebugLoggingEnabled,
                    currentDebugLogs: &self.recursiveCallDebugLogs // Pass self.recursiveCallDebugLogs
                )
                
                let elementPath = currentElement.generatePathArray(
                    upTo: appElement,
                    isDebugLoggingEnabled: isDebugLoggingEnabled,
                    currentDebugLogs: &self.recursiveCallDebugLogs // Pass self.recursiveCallDebugLogs
                )
                
                let axElement = AXElement(attributes: fetchedAttrs, path: elementPath)
                collectedAXElements.append(axElement)
            } else if locator != nil {
                 dLog("Element \(currentElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &self.recursiveCallDebugLogs)) did not match locator. Still checking children.")
            }
            
            var childrenRef: CFTypeRef?
            let childrenResult = AXUIElementCopyAttributeValue(axUIElement, kAXChildrenAttribute as CFString, &childrenRef)
            
            if childrenResult == .success, let children = childrenRef as? [AXUIElement] {
                dLog("Element \(currentElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &self.recursiveCallDebugLogs)) has \(children.count) children at depth \(currentDepth). Recursing.")
                for childElement in children {
                    collectRecursively(childElement, currentDepth + 1)
                }
            } else if childrenResult != .success {
                dLog("Failed to get children for element \(currentElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &self.recursiveCallDebugLogs)): \(axErrorToString(childrenResult))")
            } else {
                 dLog("No children found for element \(currentElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &self.recursiveCallDebugLogs)) at depth \(currentDepth)")
            }
        }

        dLog("Starting recursive collection from start element: \(startElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &self.recursiveCallDebugLogs))")
        collectRecursively(startElement.underlyingElement, 0)

        dLog("Collection complete. Found \(collectedAXElements.count) elements matching criteria (if any). Naming them 'collected_elements' in response.")

        let responseDataElement = AXElement(
            attributes: ["collected_elements": AnyCodable(collectedAXElements)],
            path: startElement.generatePathArray(upTo: appElement, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &self.recursiveCallDebugLogs)
        )

        return HandlerResponse(data: responseDataElement, error: nil, debug_logs: self.recursiveCallDebugLogs)
    }
} 