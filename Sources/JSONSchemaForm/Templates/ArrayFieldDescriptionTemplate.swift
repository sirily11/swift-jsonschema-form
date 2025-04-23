import SwiftUI
import JSONSchema

/// The ArrayFieldDescriptionTemplate component renders a DescriptionFieldTemplate with an id derived from
/// the idSchema.
struct ArrayFieldDescriptionTemplate: View {
    let idSchema: [String: Any]
    let description: String?
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let registry: Registry
    
    var body: some View {
        if let description = description, displayLabel {
            let descriptionFieldTemplate = registry.templates.descriptionFieldTemplate
            
            return AnyView(
                descriptionFieldTemplate(
                    DescriptionFieldTemplateProps(
                        id: descriptionId(idSchema: idSchema),
                        description: description,
                        schema: schema,
                        uiSchema: uiSchema,
                        registry: registry
                    )
                )
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    private var displayLabel: Bool {
        let options = getUiOptions(uiSchema: uiSchema, globalUiOptions: registry.globalUiOptions)
        return options?["label"] as? Bool ?? true
    }
    
    private func descriptionId(idSchema: [String: Any]) -> String {
        guard let id = idSchema["$id"] as? String else {
            return ""
        }
        return "\(id)__description"
    }
    
    private func getUiOptions(uiSchema: [String: Any]?, globalUiOptions: [String: Any]?) -> [String: Any]? {
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
}

extension ArrayFieldDescriptionTemplate {
    init(props: ArrayFieldDescriptionTemplateProps) {
        self.idSchema = props.idSchema
        self.description = props.description
        self.schema = props.schema
        self.uiSchema = props.uiSchema
        self.registry = props.registry
    }
} 