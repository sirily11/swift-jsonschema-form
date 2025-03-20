import Foundation
import JSONSchema

/// The type for error produced by RJSF schema validation
public struct RJSFValidationError {
    /// Name of the error, for example, "required" or "minLength"
    public var name: String?

    /// Message, for example, "is a required property" or "should NOT be shorter than 3 characters"
    public var message: String?

    /// An object with the error params returned by ajv
    /// (see doc: https://github.com/ajv-validator/ajv/tree/6a671057ea6aae690b5967ee26a0ddf8452c6297#error-parameters
    /// for more info)
    public var params: Any?

    /// A string in Javascript property accessor notation to the data path of the field with the error. For example,
    /// `.name` or `['first-name']`
    public var property: String?

    /// JSON pointer to the schema of the keyword that failed validation. For example, `#/fields/firstName/required`.
    /// (Note: this may sometimes be wrong due to a bug in ajv: https://github.com/ajv-validator/ajv/issues/512)
    public var schemaPath: String?

    /// Full error name, for example ".name is a required property"
    public var stack: String

    public init(
        name: String? = nil,
        message: String? = nil,
        params: Any? = nil,
        property: String? = nil,
        schemaPath: String? = nil,
        stack: String
    ) {
        self.name = name
        self.message = message
        self.params = params
        self.property = property
        self.schemaPath = schemaPath
        self.stack = stack
    }
}

/// The protocol that describes the validation functions that are provided by a Validator implementation used by the
/// schema utilities.
protocol ValidatorType<T, S, F> {
    associatedtype T
    associatedtype S: JSONSchema
    associatedtype F

    /// This function processes the `formData` with an optional user contributed `customValidate` function, which receives
    /// the form data and a `errorHandler` function that will be used to add custom validation errors for each field. Also
    /// supports a `transformErrors` function that will take the raw AJV validation errors, prior to custom validation and
    /// transform them in what ever way it chooses.
    ///
    /// - Parameters:
    ///   - formData: The form data to validate
    ///   - schema: The schema against which to validate the form data
    ///   - customValidate: An optional function that is used to perform custom validation
    ///   - transformErrors: An optional function that is used to transform errors after AJV validation
    ///   - uiSchema: An optional uiSchema that is passed to `transformErrors` and `customValidate`
    /// - Returns: The validation data result
    func validateFormData(
        formData: T?,
        schema: S,
        customValidate: CustomValidator<T, S, F>?,
        transformErrors: ErrorTransformer<T, S, F>?,
        uiSchema: UISchema<T, S, F>?
    ) -> ValidationData<T>

    /// Converts an `errorSchema` into a list of `RJSFValidationErrors`
    ///
    /// - Parameters:
    ///   - errorSchema: The `ErrorSchema` instance to convert
    ///   - fieldPath: The current field path, defaults to [] if not specified
    /// - Returns: A list of validation errors
    @available(*, deprecated, message: "Use the toErrorList() function provided by utils instead.")
    func toErrorList(
        errorSchema: ErrorSchema<T>?,
        fieldPath: [String]?
    ) -> [RJSFValidationError]

    /// Validates data against a schema, returning true if the data is valid, or
    /// false otherwise. If the schema is invalid, then this function will return
    /// false.
    ///
    /// - Parameters:
    ///   - schema: The schema against which to validate the form data
    ///   - formData: The form data to validate
    ///   - rootSchema: The root schema used to provide $ref resolutions
    /// - Returns: True if the data is valid, false otherwise
    func isValid(
        schema: S,
        formData: T?,
        rootSchema: S
    ) -> Bool

    /// Runs the pure validation of the `schema` and `formData` without any of the RJSF functionality. Provided for use
    /// by the playground. Returns the `errors` from the validation
    ///
    /// - Parameters:
    ///   - schema: The schema against which to validate the form data
    ///   - formData: The form data to validate
    /// - Returns: A result containing any validation errors
    func rawValidation<Result>(
        schema: S,
        formData: T?
    ) -> ValidationResult<Result>

    /// An optional function that can be used to reset validator implementation. Useful for clear schemas in the AJV
    /// instance for tests.
    func reset()
}

/// A struct representing the result of a raw validation
struct ValidationResult<Result> {
    /// The validation errors, if any
    var errors: [Result]?

    /// The validation error, if any
    var validationError: Error?
}

public protocol FormValidation {
    associatedtype T
    /// The list of errors for the field
    var errors: [String]? { get set }

    /// Adds a new error message to the list of errors
    func addError(_ message: String)
}

/// A `CustomValidator` function takes in a `formData`, `errors` and `uiSchema` objects and returns the given `errors`
/// object back, while potentially adding additional messages to the `errors`
public typealias CustomValidator<T, S: JSONSchema, F> = (
    _ formData: T?,
    _ errors: any FormValidation,
    _ uiSchema: UISchema<T, S, F>?
) -> any FormValidation

/// Type representing an error transformer function
typealias ErrorTransformer<T, S: JSONSchema, F> = (
    [RJSFValidationError],
    S,
    UISchema<T, S, F>?
) -> [RJSFValidationError]

public struct ValidationData<T> {
    var errorSchema: ErrorSchema<T>
}
