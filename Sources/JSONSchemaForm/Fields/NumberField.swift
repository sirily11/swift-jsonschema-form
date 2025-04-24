import JSONSchema
import SwiftUI

/// Implements a number field that can render as text input, range, radio buttons, etc. based on uiSchema
struct NumberField: Field {
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
                        value: Binding(
                            get: { value },
                            set: { formData.wrappedValue = .number($0) }
                        ),
                        options: enumValues,
                        required: required
                    )
                } else {
                    switch widget {
                    case "updown":
                        UpDownWidget(
                            id: id,
                            label: fieldTitle,
                            value: Binding(
                                get: { value },
                                set: { formData.wrappedValue = .number($0) }
                            ),
                            range: range,
                            required: required
                        )
                    case "range":
                        RangeWidget(
                            id: id,
                            label: fieldTitle,
                            value: Binding(
                                get: { value },
                                set: { formData.wrappedValue = .number($0) }
                            ),
                            range: range,
                            required: required
                        )
                    default:
                        NumberTextWidget(
                            id: id,
                            label: fieldTitle,
                            value: Binding(
                                get: { value },
                                set: { formData.wrappedValue = .number($0) }
                            ),
                            range: range,
                            required: required
                        )
                    }
                }
            } else {
                InvalidValueType(
                    valueType: formData.wrappedValue,
                    expectedType: FormData.number(0)
                )
            }
        }
    }
}

// MARK: - Widget Implementations

/// A standard number text input widget
private struct NumberTextWidget: View {
    var id: String
    var label: String
    var value: Binding<Double>
    var range: (min: Double?, max: Double?, step: Double?)
    var required: Bool

    @State private var stringValue: String

    init(
        id: String, label: String, value: Binding<Double>,
        range: (min: Double?, max: Double?, step: Double?), required: Bool
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.range = range
        self.required = required

        // Initialize string value from number
        self._stringValue = State(initialValue: "\(value.wrappedValue)")
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
    var value: Binding<Double>
    var range: (min: Double?, max: Double?, step: Double?)
    var required: Bool

    private var step: Double {
        return range.step ?? 1.0
    }

    private var bindingValue: Binding<Double> {
        Binding(
            get: { self.value.wrappedValue },
            set: { value.wrappedValue = $0 }
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
    var value: Binding<Double>
    var range: (min: Double?, max: Double?, step: Double?)
    var required: Bool

    private var minValue: Double {
        return range.min ?? 0.0
    }

    private var maxValue: Double {
        return range.max ?? 100.0
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
                Slider(value: value, in: minValue...maxValue, step: range.step ?? 1.0)

                // Text showing the current value
                Text("\(Int(value.wrappedValue))")
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
    var value: Binding<Double>
    var options: [Double]
    var required: Bool

    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
                    .font(.headline)
                    .padding(.bottom, 4)
            }

            ForEach(options, id: \.self) { option in
                Button {
                    value.wrappedValue = option
                } label: {
                    HStack {
                        Image(systemName: value.wrappedValue == option ? "circle.fill" : "circle")
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
