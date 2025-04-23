import SwiftUI
import JSONSchema

/// Determines the appropriate field type for a given schema
func getFieldType(for schema: JSONSchema) -> FieldType {
    switch schema.type {
    case .array:
        return .ArrayField
    case .boolean:
        return .BooleanField
    case .number, .integer:
        return .NumberField
    case .object:
        return .ObjectField
    case .string:
        return .StringField
    case .null:
        return .NullField
    default:
        // This is a catch-all for any other schema type
        return .SchemaField
    }
}

/// Extracts UI options from a uiSchema
func getUiOptions(uiSchema: [String: Any]?) -> [String: Any]? {
    guard let uiSchema = uiSchema else {
        return nil
    }
    
    // Look for "ui:options" in the uiSchema
    if let options = uiSchema["ui:options"] as? [String: Any] {
        return options
    }
    
    // Extract all ui:* properties except special ones
    var extractedOptions: [String: Any] = [:]
    for (key, value) in uiSchema {
        if key.hasPrefix("ui:") && 
           key != "ui:field" && 
           key != "ui:widget" &&
           key != "ui:options" &&
           key != "ui:order" {
            // Remove the "ui:" prefix and use the rest as the option key
            let optionKey = String(key.dropFirst(3))
            extractedOptions[optionKey] = value
        }
    }
    
    return extractedOptions.isEmpty ? nil : extractedOptions
}

/// Gets the widget name for a field based on schema type and uiSchema
func getWidgetName(schema: JSONSchema, uiSchema: [String: Any]?) -> String? {
    // // First check if a specific widget is requested in uiSchema
    // if let uiSchema = uiSchema, let widget = uiSchema["ui:widget"] as? String {
    //     return widget
    // }
    
    // // Otherwise determine default widget based on schema
    // switch schema.type {
    // case .string:
    //     if let format = schema.stringSchema?.format {
    //         switch format {
    //         case "date-time": return "datetime"
    //         case "date": return "date"
    //         case "time": return "time"
    //         case "email": return "email"
    //         case "uri": return "uri"
    //         case "data-url": return "file"
    //         default: return "text"
    //         }
    //     }
    //     return "text"
        
    // case .number, .integer:
    //     return "text"
        
    // case .boolean:
    //     return "checkbox"
        
    // default:
    //     return nil // No specific widget for other types
    // }

    return nil
}

/// Creates an ID schema based on the JSON schema structure
func createIdSchema(schema: JSONSchema, id: String, formData: Any?) -> [String: Any] {
    var idSchema: [String: Any] = ["$id": id]
    
    // // For object schemas, create ids for each property
    // if case .object(let context) = schema, let properties = context.properties {
    //     for (name, propSchema) in properties {
    //         let propId = "\(id)_\(name)"
    //         let propData = (formData as? [String: Any])?[name]
    //         idSchema[name] = createIdSchema(schema: propSchema, id: propId, formData: propData)
    //     }
    // }
    
    // // For array schemas, create ids for each item if formData exists
    // if case .array(let context) = schema, let formArray = formData as? [Any] {
    //     for (index, itemData) in formArray.enumerated() {
    //         let itemId = "\(id)_\(index)"
    //         if let itemSchema = context.items {
    //             idSchema["\(index)"] = createIdSchema(schema: itemSchema, id: itemId, formData: itemData)
    //         }
    //     }
    // }
    
    return idSchema
}

/// Creates default form data based on the schema
func createDefaultFormData(schema: JSONSchema) -> Any? {
    switch schema.type {
    case .string:
        // Return nil or an empty string based on preference
        return nil
        
    case .number, .integer:
        // Return nil or a default number based on preference
        return nil
        
    case .boolean:
        // Boolean defaults to false
        return false
        
    case .object:
        guard let properties = schema.objectSchema?.properties else {
            return [String: Any]()
        }
        
        var defaultData: [String: Any] = [:]
        let required = schema.objectSchema?.required ?? []
        
        for (name, propSchema) in properties {
            // Create default for required properties or those with a default
            if required.contains(name) {
                if let propDefault = createDefaultFormData(schema: propSchema) {
                    defaultData[name] = propDefault
                }
            }
        }
        
        return defaultData.isEmpty ? nil : defaultData
        
    case .array:
        // Check for minItems to create required array items
        if let minItems = schema.arraySchema?.minItems, minItems > 0, let itemSchema = schema.arraySchema?.items {
            var defaultItems: [Any] = []
            for _ in 0..<minItems {
                if let itemDefault = createDefaultFormData(schema: itemSchema) {
                    defaultItems.append(itemDefault)
                }
            }
            return defaultItems.isEmpty ? nil : defaultItems
        }
        return nil
        
    default:
        return nil
    }
} 