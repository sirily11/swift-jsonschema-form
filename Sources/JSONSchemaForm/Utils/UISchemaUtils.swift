import Foundation
import JSONSchema
import SwiftUI

/// Get UI options from either the uiSchema or fall back to globalUiOptions
/// @param uiSchema - The UI schema object
/// @param globalUiOptions - The global UI options
/// @returns The UI options
func getUiOptions(uiSchema: [String: Any]?, globalUiOptions: [String: Any]?) -> [String: Any]? {
    if let uiSchema = uiSchema {
        if let uiOptions = uiSchema["ui:options"] as? [String: Any] {
            return uiOptions
        }
        
        // Create a dictionary with all ui: prefixed properties
        var options: [String: Any] = [:]
        for (key, value) in uiSchema {
            if key.hasPrefix("ui:") && key != "ui:options" && key != "ui:widget" && key != "ui:field" {
                let optionName = key.replacingOccurrences(of: "ui:", with: "")
                options[optionName] = value
            }
        }
        
        if !options.isEmpty {
            return options
        }
    }
    
    return globalUiOptions
}

/// Generate an id for a description field
/// @param idSchema - The id schema
/// @returns The id for the description field
func descriptionId(idSchema: [String: Any]) -> String {
    guard let id = idSchema["$id"] as? String else {
        return ""
    }
    return "\(id)__description"
}

/// Generate an id for a title field
/// @param idSchema - The id schema
/// @returns The id for the title field
func titleId(idSchema: [String: Any]) -> String {
    guard let id = idSchema["$id"] as? String else {
        return ""
    }
    return "\(id)__title"
}

/// Get a template from the registry
/// @param templateName - The name of the template
/// @param registry - The registry
/// @param uiOptions - Optional UI options that might specify a custom template
/// @returns The template
func getTemplate(
    templateName: String,
    registry: Registry,
    uiOptions: [String: Any]? = nil
) -> Any? {
    // This is a simplified version - in practice, this would need to
    // check for custom templates in uiOptions and fallback to registry
    // TODO: Implement proper template resolution
    return nil
}

/// Get a widget from the registry
/// @param widgetName - The name of the widget
/// @param registry - The registry
/// @returns The widget
func getWidget(
    widgetName: String,
    registry: Registry
) -> AnyView? {
    return registry.widgets[widgetName]
}

/// Get a field from the registry
/// @param fieldName - The name of the field
/// @param registry - The registry
/// @returns The field
func getField(
    fieldName: String,
    registry: Registry
) -> AnyView? {
    return registry.fields[fieldName]
} 