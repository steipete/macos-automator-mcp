// AXModels.swift - Contains Codable data models for the AXHelper utility

import Foundation

// Original models from the older main.swift version, made public
public struct CommandEnvelope: Codable {
    public enum Verb: String, Codable { case query, perform }
    public let cmd: Verb
    public let locator: Locator
    public let attributes: [String]?        // for query
    public let action: String?              // for perform
    public let multi: Bool?                 // NEW in that version
    public let requireAction: String?       // NEW in that version
    // Added new fields from more recent versions
    public let debug_logging: Bool?
    public let max_elements: Int?
    public let output_format: String?
}

public struct Locator: Codable {
    public let app      : String
    public let role     : String
    public let match    : [String:String]
    public let pathHint : [String]?
}

public struct QueryResponse: Codable {
    public let attributes: [String: AnyCodable]
    public var debug_logs: [String]? // Added
    
    public init(attributes: [String: Any], debug_logs: [String]? = nil) { // Updated init
        self.attributes = attributes.mapValues(AnyCodable.init)
        self.debug_logs = debug_logs
    }
}

public struct MultiQueryResponse: Codable {
    public let elements: [[String: AnyCodable]]
    public var debug_logs: [String]? // Added
    
    public init(elements: [[String: Any]], debug_logs: [String]? = nil) { // Updated init
        self.elements = elements.map { element in
            element.mapValues(AnyCodable.init)
        }
        self.debug_logs = debug_logs
    }
}

public struct PerformResponse: Codable {
    public let status: String
    public var debug_logs: [String]? // Added
}

public struct ErrorResponse: Codable {
    public let error: String
    public var debug_logs: [String]? // Added
}

// Added new response type from more recent versions
public struct TextContentResponse: Codable {
    public let text_content: String
    public var debug_logs: [String]?
}

// AnyCodable wrapper type for JSON encoding of Any values
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable cannot decode value"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map(AnyCodable.init))
        case let dict as [String: Any]:
            try container.encode(dict.mapValues(AnyCodable.init))
        default:
            try container.encode(String(describing: value))
        }
    }
}

public typealias ElementAttributes = [String: Any] 