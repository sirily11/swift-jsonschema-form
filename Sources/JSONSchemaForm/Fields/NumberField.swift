import JSONSchema
import SwiftUI

/// Implements a number field that can render as text input, range, radio buttons, etc. based on uiSchema
struct NumberField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: Binding<FormData>
    var required: Bool
    var onChange: (Double?) -> Void
    var propertyName: String?

    private var widget: String? {
        if let uiSchema = uiSchema,
            let widgetType = uiSchema["ui:widget"] as? String
        {
            return widgetType
        }
        return nil
    }

    // Extract min, max, step from schema if available
    private var range: (min: Double?, max: Double?, step: Double?) {
        return (nil, nil, nil)
    }

    // Check if the number schema has enum values
    private var enumValues: [Double]? {
        return nil
    }

    var body: some View {
        VStack(alignment: .leading) {
            if case .number(let value) = formData.wrappedValue {
                if let enumValues = enumValues, widget == "radio" {
                    // If we have enum values and radio widget, render radio buttons
                    RadioEnumWidget(
                        id: id,
                        label: fieldTitle,
                        value: value,
                        options: enumValues,
                        required: required,
                        onChange: onChange
                    )
                } else {
                    switch widget {
                    case "updown":
                        UpDownWidget(
                            id: id,
                            label: fieldTitle,
                            value: value,
                            range: range,
                            required: required,
                            onChange: onChange
                        )
                    case "range":
                        RangeWidget(
                            id: id,
                            label: fieldTitle,
                            value: value,
                            range: range,
                            required: required,
                            onChange: onChange
                        )
                    default:
                        NumberTextWidget(
                            id: id,
                            label: fieldTitle,
                            value: value,
                            range: range,
                            required: required,
                            onChange: onChange
                        )
                    }
                }
            } else {
                InvalidValueType(
                    valueType: "\(type(of: formData.wrappedValue))", expectedType: "string")
            }
        }
    }
}

// MARK: - Widget Implementations

/// A standard number text input widget
private struct NumberTextWidget: View {
    var id: String
    var label: String
    var value: Double?
    var range: (min: Double?, max: Double?, step: Double?)
    var required: Bool
    var onChange: (Double?) -> Void

    @State private var stringValue: String

    init(
        id: String, label: String, value: Double?,
        range: (min: Double?, max: Double?, step: Double?), required: Bool,
        onChange: @escaping (Double?) -> Void
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.range = range
        self.required = required
        self.onChange = onChange

        // Initialize string value from number
        self._stringValue = State(initialValue: value != nil ? "\(value!)" : "")
    }

    var body: some View {
        TextField(
            label, text: $stringValue,
            onCommit: {
                // Convert string to number on commit
                if let newValue = Double(stringValue) {
                    // Apply constraints if they exist
                    var constrainedValue = newValue
                    if let min = range.min, constrainedValue < min {
                        constrainedValue = min
                        stringValue = "\(min)"
                    }
                    if let max = range.max, constrainedValue > max {
                        constrainedValue = max
                        stringValue = "\(max)"
                    }
                    onChange(constrainedValue)
                } else if stringValue.isEmpty {
                    onChange(nil)
                }
            }
        )
        .id(id)
    }
}

/// An updown (stepper) widget for numbers
private struct UpDownWidget: View {
    var id: String
    var label: String
    var value: Double?
    var range: (min: Double?, max: Double?, step: Double?)
    var required: Bool
    var onChange: (Double?) -> Void

    private var step: Double {
        return range.step ?? 1.0
    }

    private var bindingValue: Binding<Double> {
        Binding(
            get: { self.value ?? 0.0 },
            set: { onChange($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
                    .font(.headline)
                    .padding(.bottom, 4)
            }

            HStack {
                // Text field showing the current value
                TextField("", value: bindingValue, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                // Stepper to increment/decrement
                Stepper("", value: bindingValue, step: step)
                    .labelsHidden()
            }
            .id(id)
        }
    }
}

/// A slider widget for number ranges
private struct RangeWidget: View {
    var id: String
    var label: String
    var value: Double
    var range: (min: Double?, max: Double?, step: Double?)
    var required: Bool
    var onChange: (Double?) -> Void

    private var minValue: Double {
        return range.min ?? 0.0
    }

    private var maxValue: Double {
        return range.max ?? 100.0
    }

    private var bindingValue: Binding<Double> {
        Binding(
            get: { self.value ?? minValue },
            set: { onChange($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
                    .font(.headline)
                    .padding(.bottom, 4)
            }

            HStack {
                // Slider for the range
                Slider(value: bindingValue, in: minValue...maxValue, step: range.step ?? 1.0)

                // Text showing the current value
                Text("\(Int(bindingValue.wrappedValue))")
                    .frame(width: 40, alignment: .trailing)
                    .foregroundColor(.gray)
            }
            .id(id)
        }
    }
}

/// A radio button group for enum values
private struct RadioEnumWidget: View {
    var id: String
    var label: String
    var value: Double?
    var options: [Double]
    var required: Bool
    var onChange: (Double?) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
                    .font(.headline)
                    .padding(.bottom, 4)
            }

            ForEach(options, id: \.self) { option in
                Button {
                    onChange(option)
                } label: {
                    HStack {
                        Image(systemName: value == option ? "circle.fill" : "circle")
                        Text("\(option)")
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .id(id)
    }
}
