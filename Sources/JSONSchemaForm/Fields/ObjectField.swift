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
    var propertyName: String?
    var widgets: [String: JSONSchemaFormWidget] = [:]

    @Environment(\.formTemplates) private var templates

    // Extract properties from schema, using ui:order or JSON-defined order when available
    private var properties: OrderedDictionary<String, JSONSchema>? {
        guard case .object = schema.type else {
            return nil
        }

        let dict = schema.objectSchema?.properties ?? [:]

        // Priority: 1. ui:order from uiSchema, 2. JSON-defined order, 3. dictionary iteration order
        let orderedKeys: [String]
        if let uiOrder = uiSchema?["ui:order"] as? [String] {
            // Use ui:order from uiSchema. Keys missing from schema can still render
            // when they declare a custom widget in uiSchema.
            let orderedFromUi = uiOrder.filter { dict.keys.contains($0) || hasCustomWidget($0) }
            let remainingKeys = dict.keys.filter { !uiOrder.contains($0) }
            orderedKeys = orderedFromUi + remainingKeys
        } else if let orderMap = uiSchema?["__propertyKeyOrder"] as? [String: [String]],
            let jsonOrder = orderMap[id]
        {
            // Use the original JSON property order, filtering to keys present in schema
            orderedKeys = jsonOrder.filter { dict.keys.contains($0) }
        } else {
            orderedKeys = Array(dict.keys)
        }

        var orderedProperties = OrderedDictionary<String, JSONSchema>()
        for key in orderedKeys {
            orderedProperties[key] = dict[key] ?? virtualSchema(for: key)
        }
        return orderedProperties
    }

    private func hasCustomWidget(_ name: String) -> Bool {
        guard let propertyUiSchema = uiSchema?[name] as? [String: Any],
              let widgetName = propertyUiSchema["ui:widget"] as? String else {
            return false
        }
        return widgets[widgetName] != nil
    }

    private func virtualSchema(for name: String) -> JSONSchema? {
        guard hasCustomWidget(name) else { return nil }
        return JSONSchema.string()
    }

    // Get required properties from schema
    private var requiredProperties: [String]? {
        guard case .object = schema.type else {
            return nil
        }

        return schema.objectSchema?.required
    }

    /// Object template name requested by the schema's uiSchema, if any.
    private var objectTemplateName: String? {
        uiSchema?["ui:objectTemplate"] as? String
    }

    var body: some View {
        if let template = templates.object(for: objectTemplateName) {
            // Custom (rjsf-style) object layout supplied by the consumer.
            template(
                JSONSchemaFormObjectTemplateContext(
                    id: id,
                    title: fieldTitle,
                    description: schema.description,
                    required: required,
                    uiSchema: uiSchema,
                    properties: templateProperties()
                ))
        } else if fieldTitle.isEmpty {
            Section {
                propertyList
            }
        } else {
            Section(fieldTitle) {
                propertyList
            }
        }
    }

    @ViewBuilder
    private var propertyList: some View {
        // Render properties according to the order
        if let properties = properties {
            ForEach(Array(properties.keys), id: \.self) { propertyName in
                if let propertySchema = properties[propertyName] {
                    propertyView(name: propertyName, schema: propertySchema)
                }
            }
        }
    }

    /// Build the ordered list of rendered child properties for a custom template.
    private func templateProperties() -> [JSONSchemaFormObjectTemplateProperty] {
        guard let properties = properties else { return [] }
        return properties.keys.compactMap { name in
            guard let propertySchema = properties[name] else { return nil }
            return JSONSchemaFormObjectTemplateProperty(
                name: name,
                id: "\(id)_\(name)",
                content: AnyView(propertyView(name: name, schema: propertySchema))
            )
        }
    }

    private func schemaBinding(name: String) -> Binding<FormData> {
        if case .object(let properties) = formData.wrappedValue {
            return Binding<FormData>(
                get: {
                    properties[name] ?? FormData.fromSchemaType(schema: schema)
                },
                set: { newValue in
                    var updatedProperties = properties
                    updatedProperties[name] = newValue
                    formData.wrappedValue = FormData.object(properties: updatedProperties)
                }
            )
        }
        return formData
    }

    /// Computes the uiSchema for a child property, propagating property key order
    private func childUiSchema(for name: String) -> [String: Any]? {
        var result = uiSchema?[name] as? [String: Any]
        if let orderMap = uiSchema?["__propertyKeyOrder"] {
            if result == nil {
                result = [:]
            }
            result?["__propertyKeyOrder"] = orderMap
        }
        return result
    }

    // Render a property field
    @ViewBuilder
    private func propertyView(name: String, schema: JSONSchema) -> some View {
        if case .object = formData.wrappedValue {
            // Get property-specific uiSchema with propagated property key order
            let propertyUiSchema = childUiSchema(for: name)

            // Check if property is required
            let isRequired = requiredProperties?.contains(name) ?? false

            // Create a unique ID for this field
            let fieldId = "\(id)_\(name)"

            // Render the appropriate field based on schema type
            SchemaField(
                schema: schema,
                uiSchema: propertyUiSchema,
                id: fieldId,
                formData: schemaBinding(name: name),
                required: isRequired,
                propertyName: name,
                widgets: widgets
            )
        } else {
            InvalidValueType(
                valueType: formData.wrappedValue,
                expectedType: FormData.object(properties: [:])
            )
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
