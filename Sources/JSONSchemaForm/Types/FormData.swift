import Foundation
import JSONSchema

protocol Describable {
    func describe() -> String
}

public enum FormData: Equatable, Describable, Codable, Sendable {
    case object(properties: [String: FormData])
    case array(items: [FormData])
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null

    public static func == (lhs: FormData, rhs: FormData) -> Bool {
        switch (lhs, rhs) {
        case (.object(let lhsProperties), .object(let rhsProperties)):
            return lhsProperties == rhsProperties
        case (.array(let lhsItems), .array(let rhsItems)):
            return lhsItems == rhsItems
        case (.string(let lhsString), .string(let rhsString)):
            return lhsString == rhsString
        case (.number(let lhsNumber), .number(let rhsNumber)):
            return lhsNumber == rhsNumber
        case (.boolean(let lhsBoolean), .boolean(let rhsBoolean)):
            return lhsBoolean == rhsBoolean
        case (.null, .null):
            return true
        default:
            return false
        }
    }

    func describe() -> String {
        switch self {
        case .object:
            return "FormData.object"
        case .array:
            return "FormData.array"
        case .string:
            return "FormData.string"
        case .number:
            return "FormData.number"
        case .boolean:
            return "FormData.boolean"
        case .null:
            return "FormData.null"
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .object(let properties):
            try container.encode(properties)
        case .array(let items):
            try container.encode(items)
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .boolean(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try each type in order
        // Note: Boolean must come before number (Swift decodes true as 1.0 otherwise)
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .boolean(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([FormData].self) {
            self = .array(items: array)
        } else if let object = try? container.decode([String: FormData].self) {
            self = .object(properties: object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode FormData"
            )
        }
    }

    public static func fromJSONString(_ jsonString: String) throws -> FormData {
        guard let data = jsonString.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid UTF-8 string"
                )
            )
        }
        return try JSONDecoder().decode(FormData.self, from: data)
    }

    public var object: [String: FormData]? {
        if case .object(let properties) = self {
            return properties
        }
        return nil
    }

    public var array: [FormData]? {
        if case .array(let items) = self {
            return items
        }
        return nil
    }

    public var string: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    public var number: Double? {
        if case .number(let value) = self {
            return value
        }
        return nil
    }

    public var boolean: Bool? {
        if case .boolean(let value) = self {
            return value
        }
        return nil
    }

    public var null: Bool {
        if case .null = self {
            return true
        }
        return false
    }
}

extension AnyCodable {
    func toValue<T>() -> T? {
        switch self.value {
        case let value as T:
            return value
        default:
            return nil
        }
    }
}

extension FormData {
    /// Convert FormData to a dictionary representation for validation
    public func toDictionary() -> Any? {
        switch self {
        case .object(let properties):
            var dict: [String: Any] = [:]
            for (key, value) in properties {
                if let converted = value.toDictionary() {
                    dict[key] = converted
                }
            }
            return dict
        case .array(let items):
            return items.compactMap { $0.toDictionary() }
        case .string(let value):
            return value
        case .number(let value):
            return value
        case .boolean(let value):
            return value
        case .null:
            return nil
        }
    }

    public static func fromSchemaType(schema: JSONSchema) -> FormData {
        switch schema.type {
        case .object:
            return .object(properties: [:])
        case .array:
            return .array(items: [])
        case .string:
            return .string(schema.defaultValue?.toValue() ?? "")
        case .number:
            let doubleDefaultValue: Double? = schema.defaultValue?.toValue()
            let intDefaultValue: Int? = schema.defaultValue?.toValue()
            return .number(doubleDefaultValue ?? Double(intDefaultValue ?? 0))
        case .boolean:
            return .boolean(schema.defaultValue?.toValue() ?? false)
        case .enum:
            return .null
        case .integer:
            return .number(0)
        case .null:
            return .null
        case .oneOf:
            // For oneOf, use the first option's schema type if available
            if let firstOption = schema.combinedSchema?.oneOf?.first {
                return fromSchemaType(schema: firstOption)
            }
            return .object(properties: [:])
        case .anyOf:
            // For anyOf, use the first option's schema type if available
            if let firstOption = schema.combinedSchema?.anyOf?.first {
                return fromSchemaType(schema: firstOption)
            }
            return .object(properties: [:])
        case .allOf:
            // For allOf, all schemas must validate so we return empty object
            // The AllOfField will handle merging and populating properties
            return .object(properties: [:])
        }
    }

    public static func fromValueType(value: Any) -> FormData {
        switch value {
        case let value as [String: FormData]:
            return .object(properties: value)
        case let value as [FormData]:
            return .array(items: value)
        case let value as String:
            return .string(value)
        case let value as Double:
            return .number(value)
        case let value as Bool:
            return .boolean(value)
        default:
            return .null
        }
    }
}
