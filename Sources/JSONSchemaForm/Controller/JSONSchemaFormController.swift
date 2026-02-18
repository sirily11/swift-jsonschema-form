import Foundation
import JSONSchema
import JSONSchemaValidator
import SwiftUI

// MARK: - JSONSchemaFormController

/// A controller for managing JSONSchemaForm state, validation, and submission.
///
/// The controller centralizes all form logic and can be used for programmatic
/// form interaction including validation and submission. It uses Swift 5.9+
/// `@Observable` macro for reactive state management.
///
/// ## Overview
///
/// `JSONSchemaFormController` provides:
/// - Centralized form state management
/// - Synchronous validation with `validate()`
/// - Asynchronous submission with `submit()`
/// - Live validation support (validates as user types)
/// - Field-level error mapping for per-field error display
/// - Callbacks for validation errors and successful submission
///
/// ## Usage
///
/// ### Basic Usage (Auto-created Controller)
///
/// When you don't need programmatic control, the form creates its own internal controller:
///
/// ```swift
/// JSONSchemaForm(
///     schema: schema,
///     formData: $formData,
///     liveValidate: true
/// )
/// ```
///
/// ### Programmatic Control
///
/// For programmatic form control, create and pass your own controller:
///
/// ```swift
/// let controller = JSONSchemaFormController()
///
/// // Setup validation error callback
/// controller.onValidationError = { errors in
///     print("Validation failed with \(errors.count) errors")
///     for error in errors {
///         print("  - \(error.description)")
///     }
/// }
///
/// // Setup success callback
/// controller.onSubmitSuccess = { formData in
///     print("Form submitted successfully!")
/// }
///
/// var body: some View {
///     VStack {
///         JSONSchemaForm(
///             schema: schema,
///             formData: $formData,
///             liveValidate: true,
///             controller: controller
///         )
///
///         Button("Submit Programmatically") {
///             Task {
///                 do {
///                     let success = try await controller.submit()
///                     if success {
///                         // Handle success - navigate, show alert, etc.
///                     }
///                 } catch {
///                     // Handle unexpected errors
///                 }
///             }
///         }
///         .disabled(controller.isSubmitting)
///     }
/// }
/// ```
///
/// ## Validation
///
/// The controller validates form data against the JSON Schema using `JSONSchemaValidator`.
/// Validation can occur:
/// - On demand via `validate()`
/// - On form submission via `submit()`
/// - Automatically on data changes when `liveValidate` is enabled
///
/// ## Error Handling
///
/// Validation errors are available through:
/// - `errors`: Array of `ValidationError` from JSONSchemaValidator
/// - `fieldErrors`: Dictionary mapping field IDs to error messages
/// - `onValidationError`: Callback triggered when validation fails
///
/// Field errors are mapped from JSON Schema paths (e.g., `.address.street`)
/// to form field IDs (e.g., `root_address_street`) for display purposes.
@Observable
@MainActor
public final class JSONSchemaFormController: Sendable {
    // MARK: - Observable State

    /// Current validation errors from the last validation run.
    ///
    /// This array contains all validation errors returned by `JSONSchemaValidator`.
    /// Each error provides detailed information about what validation rule was violated.
    public private(set) var errors: [ValidationError] = []

    /// Whether the form is currently valid.
    ///
    /// This is `true` when `errors` is empty, and `false` otherwise.
    /// Updated after each call to `validate()` or `submit()`.
    public private(set) var isValid: Bool = true

    /// Whether a submission is currently in progress.
    ///
    /// Use this to disable submit buttons or show loading indicators.
    public private(set) var isSubmitting: Bool = false

    /// Field-level errors mapped by field ID.
    ///
    /// Keys are field IDs in the format `root_propertyName` or `root_parent_child`
    /// for nested properties. Values are arrays of error messages for that field.
    ///
    /// Example:
    /// ```swift
    /// // For a schema with properties "name" and "address.street"
    /// fieldErrors["root_name"] // ["String length 2 is less than minimum 3"]
    /// fieldErrors["root_address_street"] // ["Missing required property"]
    /// ```
    public private(set) var fieldErrors: [String: [String]] = [:]

    // MARK: - Callbacks

    /// Called when validation produces errors.
    ///
    /// This callback is triggered whenever `validate()` or `submit()` finds
    /// validation errors. It receives the full array of `ValidationError` objects.
    ///
    /// Example:
    /// ```swift
    /// controller.onValidationError = { errors in
    ///     print("Found \(errors.count) validation errors")
    /// }
    /// ```
    public var onValidationError: (([ValidationError]) -> Void)?

    /// Called after successful form submission.
    ///
    /// This callback is triggered when `submit()` completes successfully
    /// (i.e., validation passes). It receives the current form data.
    ///
    /// Example:
    /// ```swift
    /// controller.onSubmitSuccess = { formData in
    ///     // Save to database, navigate away, etc.
    /// }
    /// ```
    public var onSubmitSuccess: ((FormData) -> Void)?

    // MARK: - Internal Configuration

    /// The JSON Schema used for validation.
    internal var schema: JSONSchema?

    /// Binding to the form data being edited.
    internal var formDataBinding: Binding<FormData>?

    /// Whether to validate automatically when form data changes.
    internal var liveValidate: Bool = false

    /// Custom validation function for additional validation rules.
    internal var customValidate: ((Any?, inout [String: Any]) -> Void)?

    /// Error transformation function for customizing error display.
    internal var transformErrors: (([ValidationError]) -> [ValidationError])?

    // MARK: - Initialization

    /// Creates a new form controller.
    ///
    /// The controller starts unconfigured. It will be configured automatically
    /// when passed to a `JSONSchemaForm`, or you can call `configure()` manually.
    public init() {}

    // MARK: - Internal Configuration

    /// Configures the controller with form settings.
    ///
    /// This is called automatically by `JSONSchemaForm` when the form appears.
    /// You typically don't need to call this directly.
    ///
    /// - Parameters:
    ///   - schema: The JSON Schema for validation
    ///   - formData: Binding to the form data
    ///   - liveValidate: Whether to validate on data changes
    ///   - customValidate: Optional custom validation function
    ///   - transformErrors: Optional error transformation function
    internal func configure(
        schema: JSONSchema,
        formData: Binding<FormData>,
        liveValidate: Bool,
        customValidate: ((Any?, inout [String: Any]) -> Void)?,
        transformErrors: (([ValidationError]) -> [ValidationError])?
    ) {
        self.schema = schema
        self.formDataBinding = formData
        self.liveValidate = liveValidate
        self.customValidate = customValidate
        self.transformErrors = transformErrors

        // Apply schema defaults to formData so that required fields
        // with default values are populated before any validation runs.
        formData.wrappedValue = formData.wrappedValue.applyingDefaults(schema: schema)
    }

    // MARK: - Public API

    /// Validates the current form data against the schema.
    ///
    /// This method validates the form data using `JSONSchemaValidator` and updates
    /// the controller's error state (`errors`, `fieldErrors`, `isValid`).
    ///
    /// If validation fails and `onValidationError` is set, the callback is triggered.
    ///
    /// - Returns: `true` if validation passed, `false` otherwise.
    ///
    /// Example:
    /// ```swift
    /// if controller.validate() {
    ///     print("Form is valid!")
    /// } else {
    ///     print("Found \(controller.errors.count) errors")
    /// }
    /// ```
    @discardableResult
    public func validate() -> Bool {
        guard let schema = schema,
              let formData = formDataBinding?.wrappedValue
        else {
            return true
        }

        let data = formData.toDictionary()

        do {
            try JSONSchemaValidator.validate(data, schema: schema)
            errors = []
            fieldErrors = [:]
            isValid = true
            return true
        } catch let validationErrors as [ValidationError] {
            var processedErrors = validationErrors
            if let transform = transformErrors {
                processedErrors = transform(processedErrors)
            }

            errors = processedErrors
            fieldErrors = mapErrorsToFields(processedErrors)
            isValid = false
            onValidationError?(processedErrors)
            return false
        } catch {
            // Unexpected error type - should not happen with JSONSchemaValidator
            errors = []
            fieldErrors = [:]
            isValid = true
            return true
        }
    }

    /// Submits the form after validation.
    ///
    /// This method validates the form data and, if validation passes, triggers
    /// the `onSubmitSuccess` callback with the current form data.
    ///
    /// - Returns: `true` if submission was successful (validation passed),
    ///   `false` if validation failed.
    ///
    /// - Throws: Re-throws any errors from the submission process.
    ///
    /// Example:
    /// ```swift
    /// Task {
    ///     do {
    ///         let success = try await controller.submit()
    ///         if success {
    ///             // Navigate to success screen
    ///         } else {
    ///             // Show validation errors (already in controller.errors)
    ///         }
    ///     } catch {
    ///         // Handle unexpected errors
    ///     }
    /// }
    /// ```
    public func submit() async throws -> Bool {
        guard !isSubmitting else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        // Validate
        let valid = validate()

        if valid, let formData = formDataBinding?.wrappedValue {
            onSubmitSuccess?(formData)
        }

        return valid
    }

    /// Clears all validation errors.
    ///
    /// This resets `errors` and `fieldErrors` to empty, and sets `isValid` to `true`.
    /// Use this when you want to clear error state without re-validating.
    ///
    /// Example:
    /// ```swift
    /// controller.clearErrors()
    /// // Form now shows no errors
    /// ```
    public func clearErrors() {
        errors = []
        fieldErrors = [:]
        isValid = true
    }

    /// Gets errors for a specific field path.
    ///
    /// - Parameter path: The field ID (e.g., `root_name` or `root_address_street`)
    /// - Returns: Array of error messages for the field, or empty array if none.
    ///
    /// Example:
    /// ```swift
    /// let nameErrors = controller.errorsForField("root_name")
    /// if !nameErrors.isEmpty {
    ///     print("Name field has errors: \(nameErrors)")
    /// }
    /// ```
    public func errorsForField(_ path: String) -> [String] {
        return fieldErrors[path] ?? []
    }

    // MARK: - Internal Methods

    /// Called by the form when data changes.
    ///
    /// If `liveValidate` is enabled, this triggers validation.
    internal func handleFormDataChange() {
        if liveValidate {
            validate()
        }
    }

    // MARK: - Private Helpers

    /// Maps validation errors to field IDs for field-level display.
    private func mapErrorsToFields(_ errors: [ValidationError]) -> [String: [String]] {
        var mapping: [String: [String]] = [:]

        for error in errors {
            let path = extractPath(from: error)
            let fieldPath = convertToFieldId(path)
            let message = error.description

            if mapping[fieldPath] != nil {
                mapping[fieldPath]?.append(message)
            } else {
                mapping[fieldPath] = [message]
            }
        }

        return mapping
    }

    /// Extracts the JSON path from a validation error.
    private func extractPath(from error: ValidationError) -> String {
        switch error {
        case .typeMismatch(_, _, let path),
            .stringTooShort(_, _, let path),
            .stringTooLong(_, _, let path),
            .patternMismatch(_, let path),
            .formatMismatch(_, _, let path),
            .numberTooSmall(_, _, _, let path),
            .numberTooLarge(_, _, _, let path),
            .notMultipleOf(_, _, let path),
            .additionalPropertyNotAllowed(_, let path),
            .tooFewProperties(_, _, let path),
            .tooManyProperties(_, _, let path),
            .tooFewItems(_, _, let path),
            .tooManyItems(_, _, let path),
            .duplicateItems(let path),
            .notInEnum(_, let path),
            .constMismatch(_, _, let path),
            .allOfFailed(_, let path),
            .anyOfFailed(let path),
            .oneOfFailed(_, let path),
            .notFailed(let path):
            return path
        case .requiredPropertyMissing(let property, let path):
            // Include property name in the path so error maps to the correct field
            return path.isEmpty ? property : "\(path)/\(property)"
        case .invalidSchema:
            return ""
        }
    }

    /// Converts a JSON path to a form field ID.
    ///
    /// Transforms paths like `address/street` to field IDs like `root_address_street`.
    private func convertToFieldId(_ jsonPath: String) -> String {
        guard !jsonPath.isEmpty else { return "root" }

        let cleaned = jsonPath
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        return "root_\(cleaned)"
    }
}
