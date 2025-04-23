import JSONSchema
import SwiftUI

/// Implements a boolean field that can render as checkbox, radio, or select based on uiSchema
struct BooleanField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: Bool?
    var required: Bool
    var onChange: (Bool?) -> Void
    var propertyName: String?

    private var widget: String? {
        if let uiSchema = uiSchema,
           let widgetType = uiSchema["ui:widget"] as? String
        {
            return widgetType
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading) {
            switch widget {
            case "radio":
                RadioWidget(
                    id: id,
                    label: fieldTitle,
                    value: formData,
                    required: required,
                    onChange: onChange
                )
            case "select":
                SelectWidget(
                    id: id,
                    label: fieldTitle,
                    value: formData,
                    required: required,
                    onChange: onChange
                )
            default:
                CheckboxWidget(
                    id: id,
                    label: fieldTitle,
                    value: formData ?? false,
                    required: required,
                    onChange: onChange
                )
            }
        }
    }
}

// MARK: - Widget Implementations

/// A radio button widget for boolean choice
private struct RadioWidget: View {
    var id: String
    var label: String
    var value: Bool?
    var required: Bool
    var onChange: (Bool?) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
                    .font(.headline)
                    .padding(.bottom, 4)
            }

            VStack(alignment: .leading) {
                Button {
                    onChange(true)
                } label: {
                    HStack {
                        Image(systemName: value == true ? "circle.fill" : "circle")
                        Text("True")
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    onChange(false)
                } label: {
                    HStack {
                        Image(systemName: value == false ? "circle.fill" : "circle")
                        Text("False")
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// A select/picker widget for boolean choice
private struct SelectWidget: View {
    var id: String
    var label: String
    var value: Bool?
    var required: Bool
    var onChange: (Bool?) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
                    .font(.headline)
                    .padding(.bottom, 4)
            }

            Picker(selection: Binding(
                get: { self.value },
                set: { onChange($0) }
            )) {
                if !required {
                    Text("").tag(nil as Bool?)
                }
                Text("True").tag(true as Bool?)
                Text("False").tag(false as Bool?)
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
        }
    }
}

/// A checkbox widget for boolean choice
private struct CheckboxWidget: View {
    var id: String
    var label: String
    var value: Bool
    var required: Bool
    var onChange: (Bool?) -> Void

    var body: some View {
        Toggle(isOn: Binding(
            get: { self.value },
            set: { onChange($0) }
        )) {
            Text(label)
                .font(.headline)
        }
    }
}
