// The Swift Programming Language
// https://docs.swift.org/swift-book

import JSONSchema
import SwiftUI

/// A struct representing the state of a JSON Schema form
struct FormState {
    /// The JSON schema object for the form
    var schema: JSONSchema
    
    /// The uiSchema for the form
    var uiSchema: [String: Any]?
    
    /// The current data for the form
    var formData: Any?
    
    /// Flag indicating whether the form is in edit mode
    var edit: Bool
    
    /// The current list of errors for the form
    var errors: [ValidationError]
    
    /// The current errors, in ErrorSchema format, for the form
    var errorSchema: [String: Any]
}


public enum FormData: Equatable {
    case object(properties: [String: FormData])
    case array(items: [FormData])
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null


    public static func == (lhs: FormData, rhs: FormData) -> Bool {
        switch (lhs, rhs) {
        case (.object(let lhsProperties), .object(let rhsProperties)):
            return NSDictionary(dictionary: lhsProperties).isEqual(to: rhsProperties)
        case (.array(let lhsItems), .array(let rhsItems)):
            return NSArray(array: lhsItems).isEqual(to: rhsItems)
        case (.string(let lhsString), .string(let rhsString)):
            return lhsString == rhsString
        case (.number(let lhsNumber), .number(let rhsNumber)):
            return lhsNumber == rhsNumber
        case (.boolean(let lhsBoolean), .boolean(let rhsBoolean)):
            return lhsBoolean == rhsBoolean
            
        default:
            return false
        }
    }
    
}

/// A SwiftUI form component that renders a form from a JSON schema
public struct JSONSchemaForm: View {
    /// The schema defining the form structure
    let schema: JSONSchema
    
    /// Optional UI schema for customizing the form appearance
    var uiSchema: [String: Any]?
    
    /// Initial form data
    var formData: Binding<FormData>
    /// Callback when form is submitted
    var onSubmit: ((Any?) -> Void)?
    
    /// Callback when form validation has errors
    var onError: (([ValidationError]) -> Void)?
    
    /// Form context for passing data to fields
    var formContext: [String: Any]?
    
    /// Whether to validate the form as the user types
    var liveValidate: Bool = false
    
    /// Whether to show the error list
    var showErrorList: Bool = true
    
    /// Custom error transformer
    var transformErrors: (([ValidationError]) -> [ValidationError])?
    
    /// Whether the form is disabled
    var disabled: Bool = false
    
    /// Whether the form is read-only
    var readonly: Bool = false
    
    /// Additional custom validation function
    var customValidate: ((Any?, inout [String: Any]) -> Void)?
    
    /// String prefix for field IDs
    var idPrefix: String = "root"
    
    /// String separator for field IDs
    var idSeparator: String = "_"
    
    /// @State to track the current form state
    @State private var state: FormState
    
    /// Initializes a new JSONSchemaForm
    public init(
        schema: JSONSchema,
        uiSchema: [String: Any]? = nil,
        formData: Binding<FormData>,
        onSubmit: ((Any?) -> Void)? = nil,
        onError: (([ValidationError]) -> Void)? = nil,
        formContext: [String: Any]? = nil,
        liveValidate: Bool = false,
        showErrorList: Bool = true,
        transformErrors: (([ValidationError]) -> [ValidationError])? = nil,
        disabled: Bool = false,
        readonly: Bool = false,
        customValidate: ((Any?, inout [String: Any]) -> Void)? = nil,
        idPrefix: String = "root",
        idSeparator: String = "_"
    ) {
        self.schema = schema
        self.uiSchema = uiSchema
        self.formData = formData
        self.onSubmit = onSubmit
        self.onError = onError
        self.formContext = formContext
        self.liveValidate = liveValidate
        self.showErrorList = showErrorList
        self.transformErrors = transformErrors
        self.disabled = disabled
        self.readonly = readonly
        self.customValidate = customValidate
        self.idPrefix = idPrefix
        self.idSeparator = idSeparator
        
        // Create initial state with the same schema reference
        let initialErrors: [ValidationError] = []
        let initialErrorSchema: [String: Any] = [:]
        
        // Initialize state property
        self._state = State(initialValue: FormState(
            schema: schema,
            uiSchema: uiSchema,
            formData: formData,
            edit: formData != nil,
            errors: initialErrors,
            errorSchema: initialErrorSchema
        ))
        
        // After initialization, update state with validation if needed
        if liveValidate && formData != nil {
            let validationResult = validateFormData(
                formData: formData,
                schema: schema,
                customValidate: customValidate
            )
            
            // Update just the error properties, keeping the same schema reference
            var validatedState = self._state.wrappedValue
            validatedState.errors = validationResult.errors
            validatedState.errorSchema = validationResult.errorSchema
            self._state = State(initialValue: validatedState)
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showErrorList && !state.errors.isEmpty {
                errorList
            }
            
            Form {
                SchemaField(
                    schema: schema,
                    uiSchema: uiSchema,
                    id: idPrefix,
                    formData: formData,
                    required: false,
                    onChange: handleChange
                )
                
                submitButton
            }
        }
    }
    
    /// Renders the error list
    private var errorList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Errors")
                .font(.headline)
                .foregroundColor(.red)
            
            ForEach(state.errors.indices, id: \.self) { index in
                Text(state.errors[index].message)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    /// Renders the submit button
    private var submitButton: some View {
        Button("Submit") {
            handleSubmit()
        }
        .disabled(disabled || !state.errors.isEmpty)
    }
    
    /// Handles changes to form data
    private func handleChange(_ newData: Any?) {
        var formData = newData
        
        // Validate the form data if needed
        let validationResult: ValidationResult
        if liveValidate {
            validationResult = validateFormData(
                formData: formData,
                schema: schema,
                customValidate: customValidate
            )
        } else {
            validationResult = ValidationResult(errors: [], errorSchema: [:])
        }
        
        // Create new state with the updated data but keep using the original schema
        // to preserve field order
        let newState = FormState(
            schema: self.schema, // Use the original schema instead of a copy
            uiSchema: uiSchema,
            formData: formData,
            edit: formData != nil,
            errors: validationResult.errors,
            errorSchema: validationResult.errorSchema
        )
        
        // Update state and call onChange callback
        state = newState
    }
    
    /// Handles form submission
    private func handleSubmit() {
        // Validate the form data
        let validationResult = validateFormData(
            formData: state.formData,
            schema: schema,
            customValidate: customValidate
        )
        
        var errors = validationResult.errors
        
        // Apply custom error transformation if provided
        if let transformErrors = transformErrors {
            errors = transformErrors(errors)
        }
        
        // If there are validation errors, update state and call onError
        if !errors.isEmpty {
            // Update only the errors and errorSchema in state, keeping the original schema
            var updatedState = state
            updatedState.errors = errors
            updatedState.errorSchema = validationResult.errorSchema
            state = updatedState
            
            onError?(errors)
            return
        }
        
        // If validation passes, call onSubmit
        onSubmit?(state.formData)
    }
}