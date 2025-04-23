import SwiftUI
import JSONSchema


/// WrapIfAdditionalTemplate is used to wrap fields for additional properties with controls
/// to set the property name and remove the property
struct WrapIfAdditionalTemplate: View {
    let children: AnyView
    let id: String
    let classNames: String?
    let style: [String: Any]?
    let label: String
    let required: Bool
    let readonly: Bool
    let disabled: Bool
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let onKeyChange: (String) -> () -> Void
    let onDropPropertyClick: (String) -> () -> Void
    let registry: Registry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Property name field and remove button
            HStack {
                TextField("Property name", text: Binding(
                    get: { label },
                    set: { _ in /* Read-only in this implementation */ }
                ))
                .disabled(disabled || readonly)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 200)
                .onChange(of: label) { newValue in
                    onKeyChange(newValue)()
                }
                
                Spacer()
                
                if !readonly && !disabled {
                    Button(action: {
                         onDropPropertyClick(label)()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // The actual field content
            children
                .padding(.leading, 8)
        }
        .padding(.vertical, 4)
        .id(id)
    }
}

extension WrapIfAdditionalTemplate {
    init(props: WrapIfAdditionalTemplateProps) {
        self.children = props.children
        self.id = props.id
        self.classNames = props.classNames
        self.style = props.style
        self.label = props.label
        self.required = props.required
        self.readonly = props.readonly
        self.disabled = props.disabled
        self.schema = props.schema
        self.uiSchema = props.uiSchema
        self.onKeyChange = props.onKeyChange
        self.onDropPropertyClick = props.onDropPropertyClick
        self.registry = props.registry
    }
} 