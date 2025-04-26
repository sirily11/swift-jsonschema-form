import SwiftUI
import JSONSchema

/// The ArrayFieldTitleTemplate component renders a TitleFieldTemplate with an id derived from the idSchema.
struct ArrayFieldTitleTemplate: View {
    let idSchema: [String: Any]
    let title: String?
    let required: Bool
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let registry: Registry
    
    var body: some View {
        if let title = title, displayLabel {
            let titleFieldTemplate = registry.templates.titleFieldTemplate
            
            return AnyView(
                titleFieldTemplate(
                    TitleFieldTemplateProps(
                        id: titleId(idSchema: idSchema),
                        title: title,
                        schema: schema,
                        uiSchema: uiSchema,
                        required: required,
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
    
    private func titleId(idSchema: [String: Any]) -> String {
        guard let id = idSchema["$id"] as? String else {
            return ""
        }
        return "\(id)__title"
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

extension ArrayFieldTitleTemplate {
    init(props: ArrayFieldTitleTemplateProps) {
        self.idSchema = props.idSchema
        self.title = props.title
        self.required = props.required
        self.schema = props.schema
        self.uiSchema = props.uiSchema
        self.registry = props.registry
    }
} 