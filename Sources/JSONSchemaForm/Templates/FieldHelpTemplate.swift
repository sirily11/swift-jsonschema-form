import SwiftUI
import JSONSchema



/// FieldHelpTemplate displays help text for a field
struct FieldHelpTemplate: View {
    let help: String?
    let idSchema: [String: Any]
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let hasErrors: Bool
    let registry: Registry
    
    var body: some View {
        if let help = help, !help.isEmpty {
            Text(help)
                .font(.caption)
                .foregroundColor(hasErrors ? .secondary.opacity(0.8) : .secondary)
                .padding(.top, 2)
                .id(helpId)
        } else {
            EmptyView()
        }
    }
    
    private var helpId: String {
        guard let id = idSchema["$id"] as? String else {
            return ""
        }
        return "\(id)__help"
    }
}

extension FieldHelpTemplate {
    init(props: FieldHelpTemplateProps) {
        self.help = props.help
        self.idSchema = props.idSchema
        self.schema = props.schema
        self.uiSchema = props.uiSchema
        self.hasErrors = props.hasErrors
        self.registry = props.registry
    }
} 