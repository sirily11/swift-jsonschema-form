import SwiftUI
import JSONSchema

/// Implements an object field that renders a group of property fields
struct ObjectField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: [String: Any]?
    var required: Bool
    var onChange: ([String: Any]?) -> Void
    
    // Extract properties from schema
    private var properties: [String: JSONSchema]? {
        guard case .object = schema.type else {
            return nil
        }
        
        return schema.objectSchema?.properties
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
        VStack(alignment: .leading, spacing: 16) {
            // Show title if not empty
            if !fieldTitle.isEmpty {
                Text(fieldTitle)
                    .font(.title3)
                    .bold()
            }
            
            // Render properties according to the order
            if let properties = properties {
                ForEach(propertyOrder, id: \.self) { propertyName in
                    if let propertySchema = properties[propertyName] {
                        propertyView(name: propertyName, schema: propertySchema)
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    // Render a property field
    private func propertyView(name: String, schema: JSONSchema) -> some View {
        // Get property-specific uiSchema if it exists
        let propertyUiSchema = uiSchema?[name] as? [String: Any]
        
        // Check if property is required
        let isRequired = requiredProperties?.contains(name) ?? false
        
        // Get property value from formData
        let propertyValue = formData?[name]
        
        // Placeholder for actual field rendering
        // In a complete implementation, this would use SchemaField to render
        // the appropriate field type based on the schema
        return VStack(alignment: .leading) {
            Text(name)
                .font(.headline)
            
            Text("Property type: \(getSchemaType(schema))")
                .foregroundColor(.secondary)
                .font(.caption)
            
            if isRequired {
                Text("Required")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            if let value = propertyValue {
                Text("Current value: \(String(describing: value))")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
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