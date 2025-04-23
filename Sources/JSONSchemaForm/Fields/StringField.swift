import JSONSchema
import SwiftUI

/// Implements a string field that can render as text input, textarea, select, etc. based on uiSchema
struct StringField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: String?
    var required: Bool
    var onChange: (String?) -> Void
    var propertyName: String?
    
    private var widget: String? {
        if let uiSchema = uiSchema,
           let widgetType = uiSchema["ui:widget"] as? String
        {
            return widgetType
        }
        return nil
    }

    // Extract format from schema if available
    private var format: String? {
        // TODO: Implement
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            switch widget {
            case "textarea":
                TextAreaWidget(
                    id: id,
                    label: fieldTitle,
                    value: formData ?? "",
                    required: required,
                    onChange: onChange
                )
            case "password":
                PasswordWidget(
                    id: id,
                    label: fieldTitle,
                    value: formData ?? "",
                    required: required,
                    onChange: onChange
                )
            case "color":
                ColorWidget(
                    id: id,
                    label: fieldTitle,
                    value: formData ?? "#000000",
                    required: required,
                    onChange: onChange
                )
            default:
                // Handle formats for specialized widgets
                if let format = format {
                    switch format {
                    case "email":
                        EmailWidget(
                            id: id,
                            label: fieldTitle,
                            value: formData ?? "",
                            required: required,
                            onChange: onChange
                        )
                    case "uri":
                        URLWidget(
                            id: id,
                            label: fieldTitle,
                            value: formData ?? "",
                            required: required,
                            onChange: onChange
                        )
                    case "date-time":
                        DateTimeWidget(
                            id: id,
                            label: fieldTitle,
                            value: formData,
                            required: required,
                            onChange: onChange
                        )
                    case "date":
                        DateWidget(
                            id: id,
                            label: fieldTitle,
                            value: formData,
                            required: required,
                            onChange: onChange
                        )
                    default:
                        // Default to text input for unknown formats
                        TextWidget(
                            id: id,
                            label: fieldTitle,
                            value: formData ?? "",
                            required: required,
                            onChange: onChange
                        )
                    }
                } else {
                    // Default to text input
                    TextWidget(
                        id: id,
                        label: fieldTitle,
                        value: formData ?? "",
                        required: required,
                        onChange: onChange
                    )
                }
            }
        }
    }
}

// MARK: - Widget Implementations

/// A standard text input widget
private struct TextWidget: View {
    var id: String
    var label: String
    var value: String
    var required: Bool
    var onChange: (String?) -> Void
    
    var body: some View {
        var title = label
        if required {
            title += " *"
        }
        return TextField(title, text: Binding(
            get: { self.value },
            set: { onChange($0.isEmpty ? nil : $0) }
        ))
        .id(id)
    }
}

/// A textarea widget for multiline text input
private struct TextAreaWidget: View {
    var id: String
    var label: String
    var value: String
    var required: Bool
    var onChange: (String?) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
            }
            TextEditor(text: Binding(
                get: { self.value },
                set: { onChange($0.isEmpty ? nil : $0) }
            ))
            .frame(minHeight: 100)
            .id(id)
        }
    }
}

/// A password input widget
private struct PasswordWidget: View {
    var id: String
    var label: String
    var value: String
    var required: Bool
    var onChange: (String?) -> Void
    
    @State private var isSecured: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if isSecured {
                    SecureField(label, text: Binding(
                        get: { self.value },
                        set: { onChange($0.isEmpty ? nil : $0) }
                    ))
                } else {
                    TextField(label, text: Binding(
                        get: { self.value },
                        set: { onChange($0.isEmpty ? nil : $0) }
                    ))
                }
                
                Button(action: {
                    isSecured.toggle()
                }) {
                    Image(systemName: isSecured ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .id(id)
        }
    }
}

/// A color picker widget
private struct ColorWidget: View {
    var id: String
    var label: String
    var value: String
    var required: Bool
    var onChange: (String?) -> Void
    
    // Convert hex string to Color
    private var color: Color {
        Color(hex: value) ?? .black
    }
    
    var body: some View {
        ColorPicker(
            label,
            selection: Binding(
                get: { self.color },
                set: { newColor in
                    // Convert Color to hex string
                    if let hex = newColor.toHex() {
                        onChange(hex)
                    }
                }
            )
        )
        .id(id)
    }
}

/// An email input widget
private struct EmailWidget: View {
    var id: String
    var label: String
    var value: String
    var required: Bool
    var onChange: (String?) -> Void
    
    var body: some View {
        TextField(label, text: Binding(
            get: { self.value },
            set: { onChange($0.isEmpty ? nil : $0) }
        ))
        .id(id)
    }
}

/// A URL input widget
private struct URLWidget: View {
    var id: String
    var label: String
    var value: String
    var required: Bool
    var onChange: (String?) -> Void
    
    var body: some View {
        TextField(label, text: Binding(
            get: { self.value },
            set: { onChange($0.isEmpty ? nil : $0) }
        ))
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .id(id)
    }
}

/// A date-time input widget
private struct DateTimeWidget: View {
    var id: String
    var label: String
    var value: String?
    var required: Bool
    var onChange: (String?) -> Void
    
    @State private var date: Date
    
    init(id: String, label: String, value: String?, required: Bool, onChange: @escaping (String?) -> Void) {
        self.id = id
        self.label = label
        self.value = value
        self.required = required
        self.onChange = onChange
        
        // Initialize date from string or current date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        if let value = value, let parsedDate = formatter.date(from: value) {
            _date = State(initialValue: parsedDate)
        } else {
            _date = State(initialValue: Date())
        }
    }
    
    var body: some View {
        DatePicker(
            label,
            selection: Binding(
                get: { self.date },
                set: { newDate in
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime]
                    onChange(formatter.string(from: newDate))
                }
            ),
            displayedComponents: [.date, .hourAndMinute]
        )
        .id(id)
    }
}

/// A date input widget
private struct DateWidget: View {
    var id: String
    var label: String
    var value: String?
    var required: Bool
    var onChange: (String?) -> Void
    
    @State private var date: Date
    
    init(id: String, label: String, value: String?, required: Bool, onChange: @escaping (String?) -> Void) {
        self.id = id
        self.label = label
        self.value = value
        self.required = required
        self.onChange = onChange
        
        // Initialize date from string or current date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let value = value, let parsedDate = formatter.date(from: value) {
            _date = State(initialValue: parsedDate)
        } else {
            _date = State(initialValue: Date())
        }
    }
    
    var body: some View {
        DatePicker(
            label,
            selection: Binding(
                get: { self.date },
                set: { newDate in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    onChange(formatter.string(from: newDate))
                }
            ),
            displayedComponents: .date
        )
        .id(id)
    }
}

// MARK: - Helper Extensions

// Color extensions for hex conversion
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0,
            opacity: 1.0
        )
    }
    
    func toHex() -> String? {
        guard let components = cgColor?.components else { return nil }
        guard components.count >= 3 else { return nil }
        let r = components[0]
        let g = components[1]
        let b = components[2]
        let hex = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        return hex
    }
}
