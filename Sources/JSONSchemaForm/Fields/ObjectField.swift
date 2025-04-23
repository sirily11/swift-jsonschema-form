import JSONSchema
import SwiftUI
import Collections

/// Implements an object field that renders a group of property fields
struct ObjectField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: [String: Any]?
    var required: Bool
    var onChange: ([String: Any]?) -> Void
    var propertyName: String?
    
    // Cache the property order to maintain consistency
    @State private var cachedPropertyOrder: [String] = []
    
    // Extract properties from schema
    private var properties: OrderedDictionary<String, JSONSchema>? {
        guard case .object = schema.type else {
            return nil
        }

        let dict = schema.objectSchema?.properties ?? [:]
        let orderedProperties =  OrderedDictionary(uniqueKeys: dict.keys, values: dict.values)
        return orderedProperties
    }
    
    // Get required properties from schema
    private var requiredProperties: [String]? {
        guard case .object = schema.type else {
            return nil
        }
        
        return schema.objectSchema?.required
    }
    
    // Determine property order from uiSchema or use the default order
    private var propertyOrder: [String] {
        // If we already have a cached order, use that
        if !cachedPropertyOrder.isEmpty {
            return cachedPropertyOrder
        }
        
        var order: [String] = []
        
        // Check if order is defined in uiSchema
        if let uiSchema = uiSchema, let uiOrder = uiSchema["ui:order"] as? [String] {
            order = uiOrder
        }
        
        // If properties exist, use them as default order
        if let properties = properties {
            // Add properties not specified in uiOrder
            for propertyName in properties.keys {
                if !order.contains(propertyName) {
                    order.append(propertyName)
                }
            }
        }
        
        return order
    }
    
    var body: some View {
        Section(fieldTitle) {
            // Render properties according to the order
            if let properties = properties {
                // Use onAppear to initialize cached property order
                let currentOrder = propertyOrder
                
                ForEach(currentOrder, id: \.self) { propertyName in
                    if let propertySchema = properties[propertyName] {
                        propertyView(name: propertyName, schema: propertySchema)
                    }
                }
            }
        }
        .onAppear {
            // Cache the property order when the view appears
            if cachedPropertyOrder.isEmpty {
                cachedPropertyOrder = propertyOrder
            }
        }
    }
    
    // Render a property field
    @ViewBuilder
    private func propertyView(name: String, schema: JSONSchema) -> some View {
        // Get property-specific uiSchema if it exists
        let propertyUiSchema = uiSchema?[name] as? [String: Any]
        
        // Check if property is required
        let isRequired = requiredProperties?.contains(name) ?? false
        
        // Get property value from formData
        let propertyValue = formData?[name]
        
        // Create a unique ID for this field
        let fieldId = "\(id)_\(name)"
        
        // Property change handler
        let handlePropertyChange: (Any?) -> Void = { newValue in
            var updatedFormData = formData ?? [:]
            if let newValue = newValue {
                updatedFormData[name] = newValue
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
            formData: propertyValue,
            required: isRequired,
            onChange: handlePropertyChange,
            propertyName: name
        )
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
