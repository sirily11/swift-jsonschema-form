import SwiftUI
import JSONSchema



/// BaseInputTemplate renders the appropriate HTML input for a given schema type
struct BaseInputTemplate: View {
    let id: String
    let schema: JSONSchema
    let type: String
    let value: Any?
    let required: Bool
    let disabled: Bool
    let readonly: Bool
    let autofocus: Bool
    let onChange: (Any?) -> Void
    let onBlur: (String, Any?) -> Void
    let onFocus: (String, Any?) -> Void
    let placeholder: String?
    let uiSchema: [String: Any]?
    let registry: Registry
    
    var body: some View {
        Group {
            switch type {
            case "text", "email", "password", "url", "tel":
                textField
            case "number":
                numberField
            case "checkbox":
                checkboxField
            default:
                textField
            }
        }
    }
    
    private var textField: some View {
        TextField(placeholder ?? "", text: Binding(
            get: { value as? String ?? "" },
            set: { onChange($0) }
        ))
        .id(id)
        .disabled(disabled || readonly)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .disableAutocorrection(true)
        .onSubmit {
            onBlur(id, value)
        }
    }
    
    private var numberField: some View {
        TextField(placeholder ?? "", text: Binding(
            get: {
                if let numberValue = value as? Double {
                    return String(numberValue)
                } else if let numberValue = value as? Int {
                    return String(numberValue)
                }
                return ""
            },
            set: { newValue in
                if let doubleValue = Double(newValue) {
                    onChange(doubleValue)
                } else {
                    onChange(nil)
                }
            }
        ))
        .id(id)
        .disabled(disabled || readonly)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .onSubmit {
            onBlur(id, value)
        }
    }
    
    private var checkboxField: some View {
        Toggle(isOn: Binding(
            get: { value as? Bool ?? false },
            set: { onChange($0) }
        )) {
            EmptyView()
        }
        .id(id)
        .disabled(disabled || readonly)
        .labelsHidden()
    }
    
}

extension BaseInputTemplate {
    init(props: BaseInputTemplateProps) {
        self.id = props.id
        self.schema = props.schema
        self.type = props.type
        self.value = props.value
        self.required = props.required
        self.disabled = props.disabled
        self.readonly = props.readonly
        self.autofocus = props.autofocus
        self.onChange = props.onChange
        self.onBlur = props.onBlur
        self.onFocus = props.onFocus
        self.placeholder = props.placeholder
        self.uiSchema = props.uiSchema
        self.registry = props.registry
    }
} 