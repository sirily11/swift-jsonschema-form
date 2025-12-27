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
            FieldTemplate(
                id: id,
                label: fieldTitle,
                description: schema.description,
                required: required
            ) {
                StringField(
                    schema: schema,
                    uiSchema: uiSchema,
                    id: id,
                    formData: schemaDataBinding(schemaType: schema.type),
                    required: required,
                    propertyName: propertyName
                )
            }

        case .number:
            FieldTemplate(
                id: id,
                label: fieldTitle,
                description: schema.description,
                required: required
            ) {
                NumberField(
                    schema: schema,
                    uiSchema: uiSchema,
                    id: id,
                    formData: schemaDataBinding(schemaType: schema.type),
                    required: required,
                    propertyName: propertyName
                )
            }

        case .integer:
            FieldTemplate(
                id: id,
                label: fieldTitle,
                description: schema.description,
                required: required
            ) {
                NumberField(
                    schema: schema,
                    uiSchema: uiSchema,
                    id: id,
                    formData: schemaDataBinding(schemaType: schema.type),
                    required: required,
                    propertyName: propertyName
                )
            }

        case .boolean:
            FieldTemplate(
                id: id,
                label: fieldTitle,
                description: schema.description,
                required: required
            ) {
                BooleanField(
                    schema: schema,
                    uiSchema: uiSchema,
                    id: id,
                    formData: schemaDataBinding(schemaType: schema.type),
                    required: required,
                    propertyName: propertyName
                )
            }

        case .object:
            // Object fields have their own template (ObjectFieldTemplate)
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
            // Array fields have their own template (ArrayFieldTemplate)
            ArrayField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName
            )

        case .null:
            FieldTemplate(
                id: id,
                label: fieldTitle,
                description: schema.description,
                required: required
            ) {
                Text("null")
                    .foregroundColor(.gray)
                    .italic()
            }

        case .enum:
            FieldTemplate(
                id: id,
                label: fieldTitle,
                description: schema.description,
                required: required
            ) {
                EnumField(
                    schema: schema,
                    uiSchema: uiSchema,
                    id: id,
                    formData: schemaDataBinding(schemaType: schema.type),
                    required: required,
                    propertyName: propertyName
                )
            }

        case .oneOf:
            // OneOf fields have their own complex layout
            OneOfField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName
            )

        case .anyOf:
            // AnyOf fields use OneOfField with their own layout
            OneOfField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName
            )

        case .allOf:
            // AllOf fields have their own complex layout
            AllOfField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: schemaDataBinding(schemaType: schema.type),
                required: required,
                propertyName: propertyName,
                conditionalSchemas: conditionalSchemas
            )
        }
    }
}
