import Collections
import JSONSchema
import SwiftUI

/// Implements an object field that renders a group of property fields
struct ObjectField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: Binding<FormData>
    var required: Bool
    var onChange: ([String: Any]?) -> Void
    var propertyName: String?

    // Extract properties from schema
    private var properties: OrderedDictionary<String, JSONSchema>? {
        guard case .object = schema.type else {
            return nil
        }

        let dict = schema.objectSchema?.properties ?? [:]
        let orderedProperties = OrderedDictionary(uniqueKeys: dict.keys, values: dict.values)
        return orderedProperties
    }

    // Get required properties from schema
    private var requiredProperties: [String]? {
        guard case .object = schema.type else {
            return nil
        }

        return schema.objectSchema?.required
    }

    var body: some View {
        Section(fieldTitle) {
            // Render properties according to the order
            if let properties = properties {
                ForEach(properties.keys, id: \.self) { propertyName in
                    if let propertySchema = properties[propertyName] {
                        propertyView(name: propertyName, schema: propertySchema)
                    }
                }
            }
        }
    }

    // Render a property field
    @ViewBuilder
    private func propertyView(name: String, schema: JSONSchema) -> some View {
        if case .object(let properties) = formData.wrappedValue {
            // Get property-specific uiSchema if it exists
            let propertyUiSchema = uiSchema?[name] as? [String: Any]

            // Check if property is required
            let isRequired = requiredProperties?.contains(name) ?? false

            // Get property value from formData
            let propertyValue = properties[name] ?? FormData.object(properties: [:])

            // Create a unique ID for this field
            let fieldId = "\(id)_\(name)"

            // Property change handler
            let handlePropertyChange: (Any?) -> Void = { newValue in
                var updatedFormData = properties ?? [:]
                if let newValue = newValue {
                    // updatedFormData[name] = newValue
                } else {
                    updatedFormData.removeValue(forKey: name)
                }
                onChange(updatedFormData)
            }

            // Render the appropriate field based on schema type
            SchemaField(
                schema: schema,
                uiSchema: propertyUiSchema,
                id: fieldId,
                formData: Binding(
                    get: { propertyValue },
                    set: { newValue in
                        var updatedProperties = properties ?? [:]
                        updatedProperties[name] = newValue
                        formData.wrappedValue = FormData.object(properties: updatedProperties)
                    }),
                required: isRequired,
                onChange: handlePropertyChange,
                propertyName: name
            )
        } else {
            InvalidValueType(
                valueType: "\(type(of: formData.wrappedValue))", expectedType: "object")
        }
    }

    // Helper method to get schema type name
    private func getSchemaType(_ schema: JSONSchema) -> String {
        switch schema.type {
        case .string:
            return "string"
        case .number:
            return "number"
        case .integer:
            return "integer"
        case .boolean:
            return "boolean"
        case .array:
            return "array"
        case .object:
            return "object"
        case .null:
            return "null"
        default:
            return "unknown"
        }
    }

    // In a real implementation, you would need methods to handle:
    // - Updating individual property values
    // - Adding additional properties if allowed
    // - Removing properties
}
