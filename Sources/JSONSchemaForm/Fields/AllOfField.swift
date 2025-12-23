import Collections
import JSONSchema
import SwiftUI

/// Implements an allOf field that merges all sub-schemas and renders combined fields
/// allOf requires ALL sub-schemas to validate, so we merge their properties
/// Supports if/then/else conditionals extracted during preprocessing
struct AllOfField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: Binding<FormData>
    var required: Bool
    var propertyName: String?

    /// Conditional schemas extracted from if/then/else during preprocessing
    var conditionalSchemas: [ConditionalSchema]?

    /// Track previous conditional property names for cleanup
    @State private var previousConditionalPropertyNames: Set<String> = []

    /// Get the allOf schemas from the combined schema
    private var allOfSchemas: [JSONSchema] {
        schema.combinedSchema?.allOf ?? []
    }

    /// Merge all schemas to get combined properties (base without conditionals)
    private var baseMergedSchema: SchemaMerger.MergedSchema {
        SchemaMerger.merge(schemas: allOfSchemas, baseSchema: schema)
    }

    /// Get applicable conditional schemas based on current form data
    private var applicableConditionalSchemas: [[String: Any]] {
        guard let conditionals = conditionalSchemas else { return [] }
        return ConditionEvaluator.getApplicableSchemas(
            conditionals: conditionals,
            formData: formData.wrappedValue
        )
    }

    /// Get current conditional property names
    private var currentConditionalPropertyNames: Set<String> {
        SchemaMerger.getPropertyNamesFromConditionals(applicableConditionalSchemas)
    }

    /// Effective merged schema including applicable conditionals
    private var effectiveMergedSchema: SchemaMerger.MergedSchema {
        let applicable = applicableConditionalSchemas
        if applicable.isEmpty {
            return baseMergedSchema
        }
        return SchemaMerger.mergeWithConditionals(
            baseMerged: baseMergedSchema,
            conditionalSchemas: applicable
        )
    }

    /// Get ordered properties from effective merged schema
    private var orderedProperties: OrderedDictionary<String, JSONSchema> {
        let dict = effectiveMergedSchema.properties
        return OrderedDictionary(uniqueKeys: dict.keys.sorted(), values: dict.keys.sorted().compactMap { dict[$0] })
    }

    var body: some View {
        Group {
            if effectiveMergedSchema.isPrimitive {
                // Render primitive field based on merged type
                primitiveFieldView
            } else if !effectiveMergedSchema.isEmpty {
                // Render object properties
                Section(fieldTitle) {
                    ForEach(orderedProperties.keys.sorted(), id: \.self) { propertyName in
                        if let propertySchema = orderedProperties[propertyName] {
                            propertyView(name: propertyName, schema: propertySchema)
                        }
                    }
                }
            } else {
                // No properties to render
                Text("Empty allOf schema")
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .onChange(of: formData.wrappedValue) { _, newValue in
            cleanupConditionalFields(newFormData: newValue)
        }
    }

    /// Clean up fields that are no longer applicable due to condition changes
    private func cleanupConditionalFields(newFormData: FormData) {
        let currentNames = currentConditionalPropertyNames

        // Find properties that were in previous conditionals but not in current
        let removedProperties = previousConditionalPropertyNames.subtracting(currentNames)

        if !removedProperties.isEmpty, case .object(var properties) = newFormData {
            var needsUpdate = false
            for propertyName in removedProperties {
                // Only remove if it's not a base property
                if baseMergedSchema.properties[propertyName] == nil {
                    properties.removeValue(forKey: propertyName)
                    needsUpdate = true
                }
            }
            if needsUpdate {
                formData.wrappedValue = .object(properties: properties)
            }
        }

        // Update previous names for next comparison
        previousConditionalPropertyNames = currentNames
    }

    /// Render primitive field for merged primitive types
    @ViewBuilder
    private var primitiveFieldView: some View {
        switch effectiveMergedSchema.mergedType {
        case .integer, .number:
            NumberField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: formData,
                required: required,
                propertyName: propertyName
            )
        case .string:
            StringField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: formData,
                required: required,
                propertyName: propertyName
            )
        case .boolean:
            BooleanField(
                schema: schema,
                uiSchema: uiSchema,
                id: id,
                formData: formData,
                required: required,
                propertyName: propertyName
            )
        default:
            Text("Unsupported primitive allOf type")
                .foregroundColor(.gray)
                .italic()
        }
    }

    /// Create a binding for a specific property
    private func schemaBinding(name: String) -> Binding<FormData> {
        if case .object(let properties) = formData.wrappedValue {
            return Binding<FormData>(
                get: {
                    properties[name] ?? FormData.fromSchemaType(schema: orderedProperties[name] ?? schema)
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

    /// Render a property field
    @ViewBuilder
    private func propertyView(name: String, schema: JSONSchema) -> some View {
        if case .object = formData.wrappedValue {
            // Get property-specific uiSchema if it exists
            let propertyUiSchema = uiSchema?[name] as? [String: Any]

            // Check if property is required
            let isRequired = effectiveMergedSchema.required.contains(name)

            // Create a unique ID for this field
            let fieldId = "\(id)_\(name)"

            // Render the appropriate field based on schema type
            SchemaField(
                schema: schema,
                uiSchema: propertyUiSchema,
                id: fieldId,
                formData: schemaBinding(name: name),
                required: isRequired,
                propertyName: name
            )
        } else {
            InvalidValueType(
                valueType: formData.wrappedValue,
                expectedType: FormData.object(properties: [:])
            )
        }
    }
}
