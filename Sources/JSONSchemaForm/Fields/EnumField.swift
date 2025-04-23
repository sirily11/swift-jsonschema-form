import JSONSchema
import SwiftUI

/// Implements an enum field that renders a Picker for selecting among enumerated values
struct EnumField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: Any?
    var required: Bool
    var onChange: (Any?) -> Void
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
    
    // Function to find the selected index
    private func selectedValue() -> Any? {
        guard let formData = formData else {
            return nil
        }
        
        for value in enumValues {
            if let formStr = formData as? String,
               let valueStr = value.value as? String
            {
                if formStr == valueStr {
                    return value.value
                }
            } else if let formBool = formData as? Bool,
                      let valueBool = value.value as? Bool
            {
                if formBool == valueBool {
                    return value.value
                }
            } else if let formNum = formData as? Double,
                      let valueNum = value.value as? Double
            {
                if formNum == valueNum {
                    return value.value
                }
            } else if let formInt = formData as? Int,
                      let valueInt = value.value as? Int
            {
                if formInt == valueInt {
                    return value.value
                }
            }
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
                    values: enumValues,
                    selectedValue: selectedValue(),
                    required: required,
                    onChange: onChange,
                    isDisabled: isDisabled
                )
            case "select":
                SelectWidget(
                    id: id,
                    label: fieldTitle,
                    values: enumValues,
                    selectedValue: selectedValue(),
                    required: required,
                    onChange: onChange,
                    isDisabled: isDisabled
                )
            default:
                // Default to picker
                PickerWidget(
                    id: id,
                    propertyName: propertyName,
                    schema: schema,
                    label: fieldTitle,
                    values: enumValues,
                    selectedValue: selectedValue(),
                    required: required,
                    onChange: onChange,
                    isDisabled: isDisabled
                )
            }
        }
    }
}

// MARK: - Helper structs and widgets

/// Represents an enum value with its display name
struct EnumValue: Identifiable, Hashable {
    let id = UUID()
    let value: Any
    let displayName: String
    
    init(value: Any, displayName: String) {
        self.value = value
        self.displayName = displayName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(displayName)
        // Note: we can't hash 'value' directly as it's Any
    }
    
    static func == (lhs: EnumValue, rhs: EnumValue) -> Bool {
        return lhs.id == rhs.id
    }
}


private struct PickerWidget: Field {
    var id: String
    var propertyName: String?
    var schema: JSONSchema
    var label: String
    var values: [EnumValue]
    var selectedValue: Any?
    var required: Bool
    var onChange: (Any?) -> Void
    var isDisabled: (Any) -> Bool
    
    @State private var selectedOption: EnumValue?

    init(id: String, propertyName: String?, schema: JSONSchema, label: String, values: [EnumValue], selectedValue: Any?, required: Bool, onChange: @escaping (Any?) -> Void, isDisabled: @escaping (Any) -> Bool) {
        self.id = id
        self.propertyName = propertyName
        self.schema = schema
        self.label = label
        self.values = values
        self.selectedValue = selectedValue
        self.required = required
        self.onChange = onChange
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        if values.isEmpty {
            Text("No options available")
                .foregroundColor(.gray)
                .italic()
        } else {
            VStack(alignment: .leading) {
                Picker(selection: Binding<EnumValue>(
                    get: {
                        if let option = selectedOption {
                            // Ensure the selected option exists in values array
                            if values.contains(where: { $0.id == option.id }) {
                                return option
                            }
                        }
                        
                        // Find the option that matches the selected value
                        if let selectedValue = selectedValue {
                            for value in values {
                                if compareValues(selectedValue, value.value) {
                                    return value
                                }
                            }
                        }
                        
                        // Default to first option if there's no match
                        return values.first ?? EnumValue(value: "", displayName: "")
                    },
                    set: { newValue in
                        if values.contains(where: { $0.id == newValue.id }) {
                            selectedOption = newValue
                            onChange(newValue.value)
                        }
                    }
                )) {
                    ForEach(values) { option in
                        Text(option.displayName)
                            .tag(option)
                            .disabled(isDisabled(option.value))
                    }
                } label: {
                    Text(fieldTitle)
                }
                .pickerStyle(.menu)
            }
            .onAppear {
                // Initialize selectedOption based on formData
                if let selectedValue = selectedValue {
                    for value in values {
                        if compareValues(selectedValue, value.value) {
                            selectedOption = value
                            break
                        }
                    }
                }
            }
        }
    }
    
    // Helper function to compare values of Any type
    private func compareValues(_ value1: Any?, _ value2: Any?) -> Bool {
        guard let value1 = value1, let value2 = value2 else {
            return value1 == nil && value2 == nil
        }
        
        if let str1 = value1 as? String, let str2 = value2 as? String {
            return str1 == str2
        } else if let bool1 = value1 as? Bool, let bool2 = value2 as? Bool {
            return bool1 == bool2
        } else if let num1 = value1 as? Double, let num2 = value2 as? Double {
            return num1 == num2
        } else if let int1 = value1 as? Int, let int2 = value2 as? Int {
            return int1 == int2
        }
        return false
    }
}


private struct RadioWidget: View {
    var id: String
    var label: String
    var values: [EnumValue]
    var selectedValue: Any?
    var required: Bool
    var onChange: (Any?) -> Void
    var isDisabled: (Any) -> Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
                    .font(.headline)
                    .padding(.bottom, 4)
            }
            
            if values.isEmpty {
                Text("No options available")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(values) { option in
                    Button {
                        onChange(option.value)
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
        guard let selectedValue = selectedValue else {
            return false
        }
        
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


private struct SelectWidget: View {
    var id: String
    var label: String
    var values: [EnumValue]
    var selectedValue: Any?
    var required: Bool
    var onChange: (Any?) -> Void
    var isDisabled: (Any) -> Bool
    
    @State private var selectedIndex: Int = 0
    @State private var hasInitialized: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            if !label.isEmpty {
                Text(label)
                    .font(.headline)
                    .padding(.bottom, 4)
            }
            
            if values.isEmpty {
                Text("No options available")
                    .foregroundColor(.gray)
                    .italic()
            } else if values.count <= 5 { // Use segmented control for small number of options
                HStack {
                    if !required {
                        Button("Clear") {
                            // Send nil to clear the selection
                            onChange(nil)
                            hasInitialized = true
                        }
                        .buttonStyle(.borderless)
                        .font(.footnote)
                        .padding(.trailing, 8)
                    }
                    
                    Picker(selection: Binding<Int>(
                        get: {
                            // If we already set an index, use it
                            if hasInitialized {
                                return selectedIndex
                            }
                            
                            // Find the index of the selected value
                            for (index, value) in values.enumerated() {
                                if isValueEqual(selectedValue, value.value) {
                                    return index
                                }
                            }
                            
                            // Default to first option
                            return 0
                        },
                        set: { newValue in
                            // Only update if it's a valid index
                            if newValue >= 0 && newValue < values.count {
                                selectedIndex = newValue
                                hasInitialized = true
                                onChange(values[newValue].value)
                            }
                        }
                    )) {
                        ForEach(values.indices, id: \.self) { index in
                            Text(values[index].displayName)
                                .tag(index)
                                .disabled(isDisabled(values[index].value))
                        }
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.segmented)
                }
            } else {
                VStack(alignment: .leading) {
                    if !required {
                        Button("Clear selection") {
                            // Send nil to clear the selection
                            onChange(nil)
                            hasInitialized = true
                        }
                        .buttonStyle(.borderless)
                        .font(.footnote)
                        .padding(.bottom, 4)
                    }
                    
                    // Fall back to standard picker for many options
                    Picker(selection: Binding<Int>(
                        get: {
                            // If we already set an index, use it
                            if hasInitialized {
                                return selectedIndex
                            }
                            
                            // Find the index of the selected value
                            for (index, value) in values.enumerated() {
                                if isValueEqual(selectedValue, value.value) {
                                    return index
                                }
                            }
                            
                            // Default to first option
                            return 0
                        },
                        set: { newValue in
                            // Only update if it's a valid index
                            if newValue >= 0 && newValue < values.count {
                                selectedIndex = newValue
                                hasInitialized = true
                                onChange(values[newValue].value)
                            }
                        }
                    )) {
                        ForEach(values.indices, id: \.self) { index in
                            Text(values[index].displayName)
                                .tag(index)
                                .disabled(isDisabled(values[index].value))
                        }
                    } label: {
                        EmptyView()
                    }
                }
            }
        }
        .onAppear {
            // Initialize selectedIndex based on formData if values array is not empty
            if let selectedValue = selectedValue, !values.isEmpty {
                for (index, value) in values.enumerated() {
                    if isValueEqual(selectedValue, value.value) {
                        selectedIndex = index
                        hasInitialized = true
                        break
                    }
                }
            }
        }
    }
    
    // Helper function to compare values of Any type
    private func isValueEqual(_ value1: Any?, _ value2: Any?) -> Bool {
        guard let value1 = value1, let value2 = value2 else {
            return value1 == nil && value2 == nil
        }
        
        if let str1 = value1 as? String, let str2 = value2 as? String {
            return str1 == str2
        } else if let bool1 = value1 as? Bool, let bool2 = value2 as? Bool {
            return bool1 == bool2
        } else if let num1 = value1 as? Double, let num2 = value2 as? Double {
            return num1 == num2
        } else if let int1 = value1 as? Int, let int2 = value2 as? Int {
            return int1 == int2
        }
        return false
    }
}
