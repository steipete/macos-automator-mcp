// Models.swift - Contains Codable structs for command handling and responses

import Foundation

// Enum for output formatting options
public enum OutputFormat: String, Codable {
    case smart        // Default, tries to be concise and informative
    case verbose      // More detailed output, includes more attributes/info
    case text_content // Primarily extracts textual content
    case json_string  // Returns the attributes as a JSON string (new)
}

// Define CommandType enum
public enum CommandType: String, Codable {
    case query
    case performAction = "perform_action"
    case getAttributes = "get_attributes"
    case batch
    case describeElement = "describe_element"
    case getFocusedElement = "get_focused_element"
    case collectAll = "collect_all"
    case extractText = "extract_text"
    // Add future commands here, ensuring case matches JSON or provide explicit raw value
}

// For encoding/decoding 'Any' type in JSON, especially for element attributes.
public struct AnyCodable: Codable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = ()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let int32 = try? container.decode(Int32.self) {
            self.value = int32
        } else if let int64 = try? container.decode(Int64.self) {
            self.value = int64
        } else if let uint = try? container.decode(UInt.self) {
            self.value = uint
        } else if let uint32 = try? container.decode(UInt32.self) {
            self.value = uint32
        } else if let uint64 = try? container.decode(UInt64.self) {
            self.value = uint64
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let float = try? container.decode(Float.self) {
            self.value = float
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let int32 as Int32:
            try container.encode(Int(int32))
        case let int64 as Int64:
            try container.encode(int64)
        case let uint as UInt:
            try container.encode(uint)
        case let uint32 as UInt32:
            try container.encode(uint32)
        case let uint64 as UInt64:
            try container.encode(uint64)
        case let double as Double:
            try container.encode(double)
        case let float as Float:
            try container.encode(float)
        case let string as String:
            try container.encode(string)
        case let array as [AnyCodable]:
            try container.encode(array)
        case let array as [Any?]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: AnyCodable]:
            try container.encode(dictionary)
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// Type alias for element attributes dictionary
public typealias ElementAttributes = [String: AnyCodable]

// Main command envelope
public struct CommandEnvelope: Codable {
    public let command_id: String
    public let command: CommandType
    public let application: String?
    public let locator: Locator?
    public let action: String?
    public let value: String?
    public let attribute_to_set: String?
    public let attributes: [String]?
    public let path_hint: [String]?
    public let debug_logging: Bool?
    public let max_elements: Int?
    public let output_format: OutputFormat?
    public let perform_action_on_child_if_needed: Bool?

    public init(command_id: String, command: CommandType, application: String? = nil, locator: Locator? = nil, action: String? = nil, value: String? = nil, attribute_to_set: String? = nil, attributes: [String]? = nil, path_hint: [String]? = nil, debug_logging: Bool? = nil, max_elements: Int? = nil, output_format: OutputFormat? = .smart, perform_action_on_child_if_needed: Bool? = false) {
        self.command_id = command_id
        self.command = command
        self.application = application
        self.locator = locator
        self.action = action
        self.value = value
        self.attribute_to_set = attribute_to_set
        self.attributes = attributes
        self.path_hint = path_hint
        self.debug_logging = debug_logging
        self.max_elements = max_elements
        self.output_format = output_format
        self.perform_action_on_child_if_needed = perform_action_on_child_if_needed
    }
}

// Locator for finding elements
public struct Locator: Codable {
    public var match_all: Bool?
    public var criteria: [String: String]
    public var root_element_path_hint: [String]?
    public var requireAction: String?
    public var computed_name_equals: String?
    public var computed_name_contains: String?

    enum CodingKeys: String, CodingKey {
        case match_all
        case criteria
        case root_element_path_hint
        case requireAction = "require_action"
        case computed_name_equals = "computed_name_equals"
        case computed_name_contains = "computed_name_contains"
    }
    
    public init(match_all: Bool? = nil, criteria: [String: String] = [:], root_element_path_hint: [String]? = nil, requireAction: String? = nil, computed_name_equals: String? = nil, computed_name_contains: String? = nil) {
        self.match_all = match_all
        self.criteria = criteria
        self.root_element_path_hint = root_element_path_hint
        self.requireAction = requireAction
        self.computed_name_equals = computed_name_equals
        self.computed_name_contains = computed_name_contains
    }
}

// Response for query command (single element)
public struct QueryResponse: Codable {
    public var command_id: String
    public var attributes: ElementAttributes?
    public var error: String?
    public var debug_logs: [String]?

    public init(command_id: String, attributes: ElementAttributes? = nil, error: String? = nil, debug_logs: [String]? = nil) {
        self.command_id = command_id
        self.attributes = attributes
        self.error = error
        self.debug_logs = debug_logs
    }
}

// Response for collect_all command (multiple elements)
public struct MultiQueryResponse: Codable {
    public var command_id: String
    public var elements: [ElementAttributes]?
    public var count: Int?
    public var error: String?
    public var debug_logs: [String]?

    public init(command_id: String, elements: [ElementAttributes]? = nil, count: Int? = nil, error: String? = nil, debug_logs: [String]? = nil) {
        self.command_id = command_id
        self.elements = elements
        self.count = count ?? elements?.count
        self.error = error
        self.debug_logs = debug_logs
    }
}

// Response for perform_action command
public struct PerformResponse: Codable {
    public var command_id: String
    public var success: Bool
    public var error: String?
    public var debug_logs: [String]?

    public init(command_id: String, success: Bool, error: String? = nil, debug_logs: [String]? = nil) {
        self.command_id = command_id
        self.success = success
        self.error = error
        self.debug_logs = debug_logs
    }
}

// Response for extract_text command
public struct TextContentResponse: Codable {
    public var command_id: String
    public var text_content: String?
    public var error: String?
    public var debug_logs: [String]?

    public init(command_id: String, text_content: String? = nil, error: String? = nil, debug_logs: [String]? = nil) {
        self.command_id = command_id
        self.text_content = text_content
        self.error = error
        self.debug_logs = debug_logs
    }
}


// Generic error response
public struct ErrorResponse: Codable {
    public var command_id: String
    public let error: String
    public var debug_logs: [String]?

    public init(command_id: String, error: String, debug_logs: [String]? = nil) {
        self.command_id = command_id
        self.error = error
        self.debug_logs = debug_logs
    }
}