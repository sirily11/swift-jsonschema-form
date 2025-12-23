import Foundation
import JSONSchema

protocol Describable {
    func describe() -> String
}

public enum FormData: Equatable, Describable {
    case object(properties: [String: FormData])
    case array(items: [FormData])
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null

    public static func == (lhs: FormData, rhs: FormData) -> Bool {
        switch (lhs, rhs) {
        case (.object(let lhsProperties), .object(let rhsProperties)):
            return NSDictionary(dictionary: lhsProperties).isEqual(to: rhsProperties)
        case (.array(let lhsItems), .array(let rhsItems)):
            return NSArray(array: lhsItems).isEqual(to: rhsItems)
        case (.string(let lhsString), .string(let rhsString)):
            return lhsString == rhsString
        case (.number(let lhsNumber), .number(let rhsNumber)):
            return lhsNumber == rhsNumber
        case (.boolean(let lhsBoolean), .boolean(let rhsBoolean)):
            return lhsBoolean == rhsBoolean
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

public extension FormData {
    /// Convert FormData to a dictionary representation for validation
    func toDictionary() -> Any? {
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

    static func fromSchemaType(schema: JSONSchema) -> FormData {
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

    static func fromValueType(value: Any) -> FormData {
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
