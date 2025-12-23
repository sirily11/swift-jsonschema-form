import JSONSchema
import SwiftUI

/// SchemaField is the main field component that determines which specific field to render
/// based on the schema type.
struct SchemaField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: Binding<FormData>
    var required: Bool
    var propertyName: String?

    /// Conditional schemas for if/then/else support (passed to AllOfField)
    var conditionalSchemas: [ConditionalSchema]?

    // Extract the field widget from uiSchema if present
    private var uiField: String? {
        return uiSchema?["ui:field"] as? String
    }

    init(
        schema: JSONSchema, uiSchema: [String: Any]?, id: String, formData: Binding<FormData>,
        required: Bool, propertyName: String? = nil, conditionalSchemas: [ConditionalSchema]? = nil
    ) {
        self.schema = schema
        self.uiSchema = uiSchema
        self.id = id
        self.formData = formData
        self.required = required
        self.propertyName = propertyName
        self.conditionalSchemas = conditionalSchemas
    }

    /// Returns a binding for schema data that correctly updates the parent form data
    private func schemaDataBinding(schemaType: JSONSchema.SchemaType) -> Binding<FormData> {
        if let propertyName = propertyName {
            // This is a nested field, create a binding that updates the parent
            return Binding<FormData>(
                get: {
                    if schemaType == .object {
                        return formData.wrappedValue
                    }
                    if case .object(let properties) = formData.wrappedValue {
                        return properties[propertyName] ?? FormData.fromSchemaType(schema: schema)
                    }
                    return formData.wrappedValue
                },
                set: { newValue in
                    formData.wrappedValue = newValue
                }
            )
        } else {
            // This is a root-level field, use the formData binding directly
            return formData
        }
    }

    var body: some View {
        Group {
            // If a custom field is specified in uiSchema, use it
            if let customField = uiField {
                // In a complete implementation, this would look up the custom field
                // from a registry and render it
                Text("Custom field: \(customField)")
                    .foregroundColor(.blue)
            } else {
                // Otherwise, determine the appropriate field based on schema type
                renderFieldBasedOnSchemaType()
            }
        }
    }

    @ViewBuilder
    private func renderFieldBasedOnSchemaType() -> some View {
        switch schema.type {
        case .string:
            StringField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName
            )

        case .number:
            NumberField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName
            )

        case .integer:
            // Integer fields use the same NumberField but with integer values
            NumberField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName
            )

        case .boolean:
            BooleanField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName
            )

        case .object:
            // Check if this object schema also has allOf (common pattern for conditionals)
            if schema.combinedSchema?.allOf != nil || conditionalSchemas?.isEmpty == false {
                AllOfField(
                    schema: schema,
                    uiSchema: uiSchema,
                    id: id,
                    formData: schemaDataBinding(schemaType: schema.type),
                    required: required,
                    propertyName: propertyName,
                    conditionalSchemas: conditionalSchemas
                )
            } else {
                ObjectField(
                    schema: schema,
                    uiSchema: uiSchema,
                    id: id,
                    formData: schemaDataBinding(schemaType: schema.type),
                    required: required,
                    propertyName: propertyName
                )
            }

        case .array:
            ArrayField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName
            )

        case .null:
            // NullField would be a simple placeholder
            Text("null")
                .foregroundColor(.gray)
                .italic()

        case .enum:
            // EnumField would render a selection of possible values
            EnumField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName
            )

        case .oneOf:
            // OneOfField renders a picker to select between mutually exclusive schemas
            OneOfField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName
            )

        case .anyOf:
            // AnyOfField is similar to OneOfField but allows multiple schemas to validate
            // For now, use OneOfField as a reasonable approximation
            OneOfField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName
            )

        case .allOf:
            // AllOfField merges all sub-schemas and renders combined fields
            AllOfField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName,
                conditionalSchemas: conditionalSchemas
            )

        default:
            // Fallback for unsupported schema types
            UnsupportedField(
                reason: "Unsupported schema type"
            )
        }
    }
}
