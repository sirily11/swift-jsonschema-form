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
    case enumField([EnumValue])
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
        case .object(_):
            return "FormData.object"
        case .array(_):
            return "FormData.array"
        case .string(_):
            return "FormData.string"
        case .number(_):
            return "FormData.number"
        case .boolean(_):
            return "FormData.boolean"
        case .enumField(_):
            return "FormData.enumField"
        case .null:
            return "FormData.null"

        }

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
    public static func fromSchemaType(schema: JSONSchema) -> FormData {
        switch schema.type {
        case .object:
            return .object(properties: [:])
        case .array:
            return .array(items: [])
        case .string:
            return .string(schema.defaultValue?.toValue() ?? "")
        case .number:
            return .number(schema.defaultValue?.toValue() ?? 0)
        case .boolean:
            return .boolean(schema.defaultValue?.toValue() ?? false)
        case .enum:
            return .enumField([])
        case .integer:
            return .number(0)
        case .null:
            return .null
        case .oneOf:
            return .null
        case .anyOf:
            return .null
        case .allOf:
            return .null
        }
    }
}
