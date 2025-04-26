import SwiftUI
import JSONSchema

/// The DescriptionFieldTemplate is the template to use to render the description of a field
struct DescriptionFieldTemplate: View {
    let id: String
    let description: String?
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let registry: Registry
    
    var body: some View {
        if let description = description {
            if let description = description as? String {
                Text(description)
                    .id(id)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
            } else {
                // For non-string descriptions, provide a generic container
                // In a more complete implementation, this would handle ReactElement equivalents
                VStack(alignment: .leading) {
                    Text("Description")
                        .id(id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 5)
            }
        } else {
            EmptyView()
        }
    }
}

/// Props for DescriptionFieldTemplate
struct DescriptionFieldTemplateProps {
    let id: String
    let description: String?
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let registry: Registry
}

extension DescriptionFieldTemplate {
    init(props: DescriptionFieldTemplateProps) {
        self.id = props.id
        self.description = props.description
        self.schema = props.schema
        self.uiSchema = props.uiSchema
        self.registry = props.registry
    }
} 