import JSONSchema
import SwiftUI

public struct JSONSchemaFormWidgetContext {
    public let id: String
    public let propertyName: String?
    public let schema: JSONSchema
    public let uiSchema: [String: Any]?
    public let formData: Binding<FormData>
    public let required: Bool

    public init(
        id: String,
        propertyName: String?,
        schema: JSONSchema,
        uiSchema: [String: Any]?,
        formData: Binding<FormData>,
        required: Bool
    ) {
        self.id = id
        self.propertyName = propertyName
        self.schema = schema
        self.uiSchema = uiSchema
        self.formData = formData
        self.required = required
    }
}

public typealias JSONSchemaFormWidget = @MainActor (JSONSchemaFormWidgetContext) -> AnyView
