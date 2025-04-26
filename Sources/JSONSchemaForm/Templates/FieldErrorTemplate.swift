import SwiftUI
import JSONSchema

struct FieldErrorTemplateProps {
    let errors: [String]?
    let idSchema: [String: Any]
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let registry: Registry
}

/// FieldErrorTemplate displays validation errors for a field
struct FieldErrorTemplate: View {
    let errors: [String]?
    let idSchema: [String: Any]
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let registry: Registry
    
    var body: some View {
        if let errors = errors, !errors.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(errors, id: \.self) { error in
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 4)
        } else {
            EmptyView()
        }
    }
}

extension FieldErrorTemplate {
    init(props: FieldErrorTemplateProps) {
        self.errors = props.errors
        self.idSchema = props.idSchema
        self.schema = props.schema
        self.uiSchema = props.uiSchema
        self.registry = props.registry
    }
} 