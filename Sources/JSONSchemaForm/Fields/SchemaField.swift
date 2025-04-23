import SwiftUI
import JSONSchema

/// SchemaField is the main field component that determines which specific field to render
/// based on the schema type.
struct SchemaField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: Any?
    var required: Bool
    var onChange: (Any?) -> Void
    
    // Extract the field widget from uiSchema if present
    private var uiField: String? {
        return uiSchema?["ui:field"] as? String
    }
    
    var body: some View {
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
    
    @ViewBuilder
    private func renderFieldBasedOnSchemaType() -> some View {
        switch schema.type {
        case .string:
            StringField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: formData as? String,
                required: required,
                onChange: { newValue in
                    onChange(newValue)
                }
            )
            
        case .number:
            NumberField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: formData as? Double,
                required: required,
                onChange: { newValue in
                    onChange(newValue)
                }
            )
            
        case .integer:
            // Integer fields use the same NumberField but with integer values
            NumberField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: (formData as? Int).map { Double($0) },
                required: required,
                onChange: { newValue in
                    // Convert Double back to Int for integer fields
                    onChange(newValue.map { Int($0) })
                }
            )
            
        case .boolean:
            BooleanField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: formData as? Bool,
                required: required,
                onChange: { newValue in
                    onChange(newValue)
                }
            )
            
        case .object:
            ObjectField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: formData as? [String: Any],
                required: required,
                onChange: { newValue in
                    onChange(newValue)
                }
            )
            
        case .array:
            ArrayField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: formData as? [Any],
                required: required,
                onChange: { newValue in
                    onChange(newValue)
                }
            )
            
        case .null:
            // NullField would be a simple placeholder
            Text("null")
                .foregroundColor(.gray)
                .italic()
            
//        case .anyOf:
//            // In a complete implementation, this would render a selection
//            // of possible schemas
//            Text("anyOf field (not fully implemented)")
//                .foregroundColor(.orange)
            
//        case .oneOf:
//            // In a complete implementation, this would render a selection
//            // of possible schemas
//            Text("oneOf field (not fully implemented)")
//                .foregroundColor(.orange)
            
        default:
            // Fallback for unsupported schema types
            UnsupportedField(
                reason: "Unsupported schema type"
            )
        }
    }
} 
