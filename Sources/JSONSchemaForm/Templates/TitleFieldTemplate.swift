import SwiftUI
import JSONSchema



/// The TitleFieldTemplate is the template to use for rendering the title of a field
struct TitleFieldTemplate: View {
    let id: String
    let title: String
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let required: Bool?
    let registry: Registry
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .id(id)
                .font(.headline)
                .foregroundColor(.primary)
            
            if required == true {
                Text("*")
                    .foregroundColor(.red)
                    .font(.headline)
            }
        }
        .padding(.bottom, 5)
    }
}

extension TitleFieldTemplate {
    init(props: TitleFieldTemplateProps) {
        self.id = props.id
        self.title = props.title
        self.schema = props.schema
        self.uiSchema = props.uiSchema
        self.required = props.required
        self.registry = props.registry
    }
} 