// AXModels.swift - Defines Codable structs for communication and data representation.

import Foundation

// Enum for command types
public enum CommandType: String, Codable {
    case query
    case perform
}

// Structure for the overall command received by the binary
public struct CommandEnvelope: Codable {
    public let cmd: CommandType
    public let locator: Locator
    public let attributes: [String]?
    public let action: String?
    public let value: String? // For setting values, if implemented
    public let multi: Bool?
    public let max_elements: Int? // Max elements to return for multi-queries
    public let debug_logging: Bool?
    public let output_format: String? // "smart", "verbose", "text_content"
}

// Structure to specify the target UI element
public struct Locator: Codable {
    public let app: String          // Bundle identifier or app name
    public let role: String?        // e.g., "AXButton", "AXTextField", "*" for wildcard
    public let title: String?
    public let value: String?       // AXValue
    public let description: String? // AXDescription
    public let identifier: String?  // AXIdentifier (e.g., "action-button")
    public let id: String?          // For web content, HTML id attribute (maps to AXIdentifier usually)
    public let class_name: String?  // For web content, HTML class attribute (maps to AXDOMClassList)
    public let pathHint: [String]?  // e.g. ["window[1]", "group[2]", "button[1]"]
    public let requireAction: String? // Ensure element supports this action (e.g., kAXPressAction)
    public let match: [String: String]? // Dictionary for flexible attribute matching
                                        // Example: {"AXMain": "true", "AXEnabled": "true", "AXDOMClassList": "classA,classB"}
}

public typealias ElementAttributes = [String: AnyCodable]

// Response for a single element query
public struct QueryResponse: Codable {
    public let attributes: ElementAttributes
    public var debug_logs: [String]?
}

// Response for a multi-element query
public struct MultiQueryResponse: Codable {
    public let elements: [ElementAttributes]
    public var debug_logs: [String]?
}

// Response for a perform action command
public struct PerformResponse: Codable {
    public let status: String // "ok" or "error"
    public let message: String?
    public var debug_logs: [String]?
}

// Response for text_content output format
public struct TextContentResponse: Codable {
    public let text_content: String
    public var debug_logs: [String]?
}

// Generic error response
public struct ErrorResponse: Codable, Error { // Make it conform to Error for throwing
    public let error: String
    public var debug_logs: [String]?
}

// Wrapper for AnyCodable to handle mixed types in ElementAttributes
public struct AnyCodable: Codable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
            case let string as String: try container.encode(string)
            case let int as Int: try container.encode(int)
            case let double as Double: try container.encode(double)
            case let bool as Bool: try container.encode(bool)
            case let array as [AnyCodable]: try container.encode(array)
            case let dictionary as [String: AnyCodable]: try container.encode(dictionary)
            case is Void, is (): try container.encodeNil() // Represents nil or an empty tuple for nil values
            default: throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Invalid AnyCodable value"))
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self.value = () } // Store nil as an empty tuple
        else if let bool = try? container.decode(Bool.self) { self.value = bool }
        else if let int = try? container.decode(Int.self) { self.value = int }
        else if let double = try? container.decode(Double.self) { self.value = double }
        else if let string = try? container.decode(String.self) { self.value = string }
        else if let array = try? container.decode([AnyCodable].self) { self.value = array.map { $0.value } }
        else if let dictionary = try? container.decode([String: AnyCodable].self) { self.value = dictionary.mapValues { $0.value } }
        else { throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid AnyCodable value")) }
    }
} 