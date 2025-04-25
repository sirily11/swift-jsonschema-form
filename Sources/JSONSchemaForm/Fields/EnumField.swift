import JSONSchema
import SwiftUI

/// Implements an enum field that renders a Picker for selecting among enumerated values
struct EnumField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: Binding<FormData>
    @State private var value: EnumValue = .emptyEnum
    var required: Bool
    var propertyName: String?

    // Extract the widget type from uiSchema if present
    private var widget: String? {
        if let uiSchema = uiSchema,
            let widgetType = uiSchema["ui:widget"] as? String
        {
            return widgetType
        }
        return nil
    }

    // Extract disabled options from uiSchema if present
    private var disabledOptions: [Any]? {
        if let uiSchema = uiSchema,
            let disabled = uiSchema["ui:enumDisabled"] as? [Any]
        {
            return disabled
        }
        return nil
    }

    // Get enum values from schema
    private var enumValues: [EnumValue] {
        if let enumSchema = schema.enumSchema {
            return createEnumValues(values: enumSchema.values)
        }
        return []
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
    }

    // Helper to convert JSONSchema.Value to EnumValue with custom labels
    private func createEnumValues(values: [JSONSchema.EnumSchema.Value]) -> [EnumValue] {
        return values.enumerated().map { _, value in
            let stringValue: String
            let rawValue: Any

            switch value {
            case .string(let str):
                stringValue = str
                rawValue = str
            case .number(let num):
                stringValue = "\(num)"
                rawValue = num
            case .integer(let int):
                stringValue = "\(int)"
                rawValue = int
            case .boolean(let bool):
                stringValue = bool ? "Yes" : "No"
                rawValue = bool
            case .null:
                stringValue = "Null"
                rawValue = Any?.none as Any
            }

            return EnumValue(value: rawValue, displayName: stringValue)
        }
    }

    // Function to check if an option should be disabled
    private func isDisabled(_ value: Any) -> Bool {
        guard let disabledOptions = disabledOptions else {
            return false
        }

        return disabledOptions.contains { disabledValue in
            if let disabledStr = disabledValue as? String,
                let valueStr = value as? String
            {
                return disabledStr == valueStr
            } else if let disabledBool = disabledValue as? Bool,
                let valueBool = value as? Bool
            {
                return disabledBool == valueBool
            } else if let disabledNum = disabledValue as? Double,
                let valueNum = value as? Double
            {
                return disabledNum == valueNum
            } else if let disabledInt = disabledValue as? Int,
                let valueInt = value as? Int
            {
                return disabledInt == valueInt
            }
            return false
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            switch widget {
            case "radio":
                RadioWidget(
                    id: id,
                    label: fieldTitle,
                    options: enumValues,
                    selection: $value,
                    required: required,
                    isDisabled: isDisabled
                )
            default:
                // Default to picker
                PickerWidget(
                    id: id,
                    propertyName: propertyName,
                    schema: schema,
                    label: fieldTitle,
                    options: enumValues,
                    selection: $value,
                    required: required,
                    isDisabled: isDisabled
                )
            }
        }
        .id("\(id)_enum_field")
        .onChange(of: value) { _, newValue in
            self.formData.wrappedValue = .fromValueType(value: newValue.value)
        }
    }
}

// MARK: - Helper structs and widgets

/// Represents an enum value with its display name
private struct PickerWidget: Field {
    var id: String
    var propertyName: String?
    var schema: JSONSchema
    var label: String
    var options: [EnumValue]
    var selection: Binding<EnumValue>
    var required: Bool
    var isDisabled: (Any) -> Bool

    var body: some View {
        if options.isEmpty {
            Text("No options available")
                .foregroundColor(.gray)
                .italic()
        } else {
            VStack(alignment: .leading) {
                Picker(
                    selection: selection
                ) {
                    Text("")
                        .tag(EnumValue.emptyEnum)

                    ForEach(options) { option in
                        Text(option.displayName)
                            .tag(option)
                            .disabled(isDisabled(option.value))
                    }
                } label: {
                    Text(fieldTitle)
                }
                .pickerStyle(.menu)
            }
        }
    }
}

private struct RadioWidget: View {
    var id: String
    var label: String
    var options: [EnumValue]
    var selection: Binding<EnumValue>
    var required: Bool
    var isDisabled: (Any) -> Bool

    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
                    .font(.headline)
                    .padding(.bottom, 4)
            }

            if options.isEmpty {
                Text("No options available")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(options) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        HStack {
                            Image(systemName: isSelected(option.value) ? "circle.fill" : "circle")
                            Text(option.displayName)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isDisabled(option.value))
                    .opacity(isDisabled(option.value) ? 0.5 : 1.0)
                }
            }
        }
    }

    // Helper function to check if a value is selected
    private func isSelected(_ value: Any) -> Bool {
        let selectedValue = selection.wrappedValue
        if let selectedStr = selectedValue as? String,
            let valueStr = value as? String
        {
            return selectedStr == valueStr
        } else if let selectedBool = selectedValue as? Bool,
            let valueBool = value as? Bool
        {
            return selectedBool == valueBool
        } else if let selectedNum = selectedValue as? Double,
            let valueNum = value as? Double
        {
            return selectedNum == valueNum
        } else if let selectedInt = selectedValue as? Int,
            let valueInt = value as? Int
        {
            return selectedInt == valueInt
        }

        return false
    }
}
