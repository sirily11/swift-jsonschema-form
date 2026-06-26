import Foundation

public struct JSONSchemaFormFieldMetadata {
    public let id: String
    public let schema: [String: Any]

    public init(id: String, schema: [String: Any]) {
        self.id = id
        self.schema = schema
    }

    public var title: String {
        stringValue("title") ?? id
    }

    public var description: String? {
        stringValue("description")
    }

    public var placeholder: String? {
        stringValue("placeholder")
    }

    public var minimumInt: Int {
        intValue("minimum") ?? 2
    }

    public var maximumInt: Int {
        intValue("maximum") ?? 6
    }

    public var options: [JSONSchemaFormFieldOption] {
        if let values = schema["x-options"] as? [Any] {
            let options = values.compactMap(JSONSchemaFormFieldOption.init(rawValue:))
            if !options.isEmpty {
                return options
            }
        }
        if let values = schema["enum"] as? [Any] {
            return values.compactMap { value in
                guard let id = Self.string(from: value) else { return nil }
                return JSONSchemaFormFieldOption(id: id, label: id, description: nil)
            }
        }
        return []
    }

    private func stringValue(_ key: String) -> String? {
        Self.string(from: schema[key])
    }

    private func intValue(_ key: String) -> Int? {
        switch schema[key] {
        case let value as Int:
            return value
        case let value as Double:
            return Int(value)
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }

    private static func string(from value: Any?) -> String? {
        switch value {
        case let value as String:
            return value
        case let value as Int:
            return String(value)
        case let value as Double:
            return String(value)
        case let value as Bool:
            return String(value)
        default:
            return nil
        }
    }
}

public struct JSONSchemaFormFieldOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let description: String?

    public init(id: String, label: String, description: String?) {
        self.id = id
        self.label = label
        self.description = description
    }

    public init?(rawValue: Any) {
        guard let values = rawValue as? [String: Any],
              let id = values["id"] as? String else {
            return nil
        }
        self.id = id
        self.label = (values["label"] as? String) ?? id
        self.description = values["description"] as? String
    }
}
