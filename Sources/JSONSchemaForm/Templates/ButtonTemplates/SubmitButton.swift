import SwiftUI
import JSONSchema

/// SubmitButton template for form submission
struct SubmitButton: View {
    var uiSchema: [String: Any]?
    
    private var buttonText: String {
        if let uiSchema = uiSchema,
           let options = uiSchema["ui:submitButtonOptions"] as? [String: Any],
           let text = options["submitText"] as? String {
            return text
        }
        return "Submit"
    }
    
    private var buttonProps: [String: Any]? {
        if let uiSchema = uiSchema,
           let options = uiSchema["ui:submitButtonOptions"] as? [String: Any],
           let props = options["props"] as? [String: Any] {
            return props
        }
        return nil
    }
    
    private var isDisabled: Bool {
        if let props = buttonProps,
           let disabled = props["disabled"] as? Bool {
            return disabled
        }
        return false
    }
    
    private var className: String {
        if let props = buttonProps,
           let className = props["className"] as? String {
            return className
        }
        return ""
    }
    
    var body: some View {
        Button(action: {
            // Submit action is handled by the form, not the button itself
        }) {
            Text(buttonText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isDisabled ? Color.gray.opacity(0.3) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
        }
        .disabled(isDisabled)
        .id("submit-button")
    }
} 