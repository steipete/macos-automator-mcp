/// Represents errors that can occur within the AX tool.
public enum AccessibilityError: Error, CustomStringConvertible {
    // Authorization & Setup Errors
    case apiDisabled // Accessibility API is disabled.
    case notAuthorized(String?) // Process is not authorized. Optional AXError for more detail.

    // Command & Input Errors
    case invalidCommand(String?) // Command is invalid or not recognized. Optional message.
    case missingArgument(String) // A required argument is missing.
    case invalidArgument(String) // An argument has an invalid value or format.

    // Element & Search Errors
    case appNotFound(String) // Application with specified bundle ID or name not found or not running.
    case elementNotFound(String?) // Element matching criteria or path not found. Optional message.
    case invalidElement // The AXUIElementRef is invalid or stale.

    // Attribute Errors
    case attributeUnsupported(String) // Attribute is not supported by the element.
    case attributeNotReadable(String) // Attribute value cannot be read.
    case attributeNotSettable(String) // Attribute is not settable.
    case typeMismatch(expected: String, actual: String) // Value type does not match attribute's expected type.
    case valueParsingFailed(details: String) // Failed to parse string into the required type for an attribute.
    case valueNotAXValue(String) // Value is not an AXValue type when one is expected.

    // Action Errors
    case actionUnsupported(String) // Action is not supported by the element.
    case actionFailed(String?, AXError?) // Action failed. Optional message and AXError.

    // Generic & System Errors
    case unknownAXError(AXError) // An unknown or unexpected AXError occurred.
    case jsonEncodingFailed(Error?) // Failed to encode response to JSON.
    case jsonDecodingFailed(Error?) // Failed to decode request from JSON.
    case genericError(String) // A generic error with a custom message.

    public var description: String {
        switch self {
        case .notAuthorized(let detail):
            return "AX API not authorized. Ensure AXESS_AUTHORIZED is true or run with sudo. Detail: \(detail ?? "Unknown")"
        }
    }

    var exitCode: Int32 {
        // Implementation of exitCode property
        return 0 // Placeholder return, actual implementation needed
    }
} 