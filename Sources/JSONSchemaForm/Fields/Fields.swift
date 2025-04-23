import SwiftUI
import JSONSchema

enum FieldType: String {
    case AnyOfField
    case ArrayField
    case BooleanField
    case NumberField
    case ObjectField
    case OneOfField
    case SchemaField
    case StringField
    case NullField
}

protocol Field: View, Sendable {
    var schema: JSONSchema { get }
    var fieldTitle: String { get }
}

extension Field {
    var fieldTitle: String {
        return schema.title ?? ""
    }
}