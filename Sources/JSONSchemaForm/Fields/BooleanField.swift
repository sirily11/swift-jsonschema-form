import JSONSchema
import SwiftUI

/// Implements a boolean field that can render as checkbox, radio, or select based on uiSchema
struct BooleanField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: Binding<FormData>
    @State private var value: Bool
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

    init(
        schema: JSONSchema,
        uiSchema: [String: Any]?,
        id: String,
        formData: Binding<FormData>,
        required: Bool,
        propertyName: String?
    ) {
        self.schema = schema
        self.uiSchema = uiSchema
        self.id = id
        self.formData = formData
        self.required = required
        self.propertyName = propertyName
        if case .boolean(let value) = formData.wrappedValue {
            self.value = value
        } else {
            self.value = false
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            if case .boolean(let value) = formData.wrappedValue {
                switch widget {
                case "radio":
                    RadioWidget(
                        id: id,
                        label: fieldTitle,
                        value: $value,
                        required: required
                    )
                case "select":
                    SelectWidget(
                        id: id,
                        label: fieldTitle,
                        value: $value,
                        required: required
                    )
                default:
                    CheckboxWidget(
                        id: id,
                        label: fieldTitle,
                        value: $value,
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
        .onChange(of: value) { _, newValue in
            print("Boolean field changed to: \(newValue)")
            formData.wrappedValue = .boolean(newValue)
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
            .id(id)
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
        .id(id)
    }
}
