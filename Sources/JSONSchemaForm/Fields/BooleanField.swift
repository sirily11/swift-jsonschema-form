import JSONSchema
import SwiftUI

/// Implements a boolean field that can render as checkbox, radio, or select based on uiSchema
struct BooleanField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: Binding<FormData>
    var required: Bool
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
            if case .boolean(let value) = formData.wrappedValue {
                switch widget {
                case "radio":
                    RadioWidget(
                        id: id,
                        label: fieldTitle,
                        value: Binding(
                            get: { value },
                            set: { formData.wrappedValue = .boolean($0) }
                        ),
                        required: required
                    )
                case "select":
                    SelectWidget(
                        id: id,
                        label: fieldTitle,
                        value: Binding(
                            get: { value },
                            set: { formData.wrappedValue = .boolean($0) }
                        ),
                        required: required
                    )
                default:
                    CheckboxWidget(
                        id: id,
                        label: fieldTitle,
                        value: Binding(
                            get: { value },
                            set: { formData.wrappedValue = .boolean($0) }
                        ),
                        required: required
                    )
                }
            } else {
                InvalidValueType(
                    valueType: formData.wrappedValue,
                    expectedType: FormData.boolean(false)
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
    var value: Binding<Bool>
    var required: Bool

    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
                    .font(.headline)
                    .padding(.bottom, 4)
            }

            VStack(alignment: .leading) {
                Button {
                    value.wrappedValue = true
                } label: {
                    HStack {
                        Image(systemName: value.wrappedValue == true ? "circle.fill" : "circle")
                        Text("True")
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    value.wrappedValue = false
                } label: {
                    HStack {
                        Image(systemName: value.wrappedValue == false ? "circle.fill" : "circle")
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
    var value: Binding<Bool>
    var required: Bool

    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
                    .font(.headline)
                    .padding(.bottom, 4)
            }

            Picker(
                selection: value
            ) {
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
    var value: Binding<Bool>
    var required: Bool

    var body: some View {
        Toggle(
            isOn: value
        ) {
            Text(label)
                .font(.headline)
        }
    }
}
