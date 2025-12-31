import Foundation

/// Swift 6 typed throws error enum for JSON Schema validation.
/// Enables exhaustive error handling at compile time.
public enum ValidationError: Error, Sendable, Equatable {
    // MARK: - Type Errors

    /// Value type doesn't match expected schema type
    case typeMismatch(expected: String, actual: String, path: String)

    /// Schema itself is invalid or malformed
    case invalidSchema(message: String)

    // MARK: - String Constraint Errors

    /// String is shorter than minLength
    case stringTooShort(minLength: Int, actualLength: Int, path: String)

    /// String is longer than maxLength
    case stringTooLong(maxLength: Int, actualLength: Int, path: String)

    /// String doesn't match the required pattern
    case patternMismatch(pattern: String, path: String)

    /// String doesn't match the required format (email, uri, etc.)
    case formatMismatch(format: String, value: String, path: String)

    // MARK: - Number Constraint Errors

    /// Number is less than minimum
    case numberTooSmall(minimum: Double, actual: Double, exclusive: Bool, path: String)

    /// Number is greater than maximum
    case numberTooLarge(maximum: Double, actual: Double, exclusive: Bool, path: String)

    /// Number is not a multiple of the specified value
    case notMultipleOf(multipleOf: Double, actual: Double, path: String)

    // MARK: - Object Constraint Errors

    /// Required property is missing
    case requiredPropertyMissing(property: String, path: String)

    /// Additional property not allowed when additionalProperties is false
    case additionalPropertyNotAllowed(property: String, path: String)

    /// Object has fewer properties than minProperties
    case tooFewProperties(minProperties: Int, actual: Int, path: String)

    /// Object has more properties than maxProperties
    case tooManyProperties(maxProperties: Int, actual: Int, path: String)

    // MARK: - Array Constraint Errors

    /// Array has fewer items than minItems
    case tooFewItems(minItems: Int, actual: Int, path: String)

    /// Array has more items than maxItems
    case tooManyItems(maxItems: Int, actual: Int, path: String)

    /// Array contains duplicate items when uniqueItems is true
    case duplicateItems(path: String)

    // MARK: - Enum/Const Errors

    /// Value is not one of the allowed enum values
    case notInEnum(allowedValues: [String], path: String)

    /// Value doesn't match the const value
    case constMismatch(expected: String, actual: String, path: String)

    // MARK: - Combinator Errors

    /// allOf validation failed - not all schemas matched
    case allOfFailed(errors: [ValidationError], path: String)

    /// anyOf validation failed - no schemas matched
    case anyOfFailed(path: String)

    /// oneOf validation failed - either zero or more than one schema matched
    case oneOfFailed(matchCount: Int, path: String)

    /// not validation failed - the schema matched when it shouldn't have
    case notFailed(path: String)
}

// MARK: - CustomStringConvertible

extension ValidationError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .typeMismatch(let expected, let actual, let path):
            return "\(pathPrefix(path))Expected type '\(expected)' but got '\(actual)'"

        case .invalidSchema(let message):
            return "Invalid schema: \(message)"

        case .stringTooShort(let minLength, let actualLength, let path):
            return "\(pathPrefix(path))String length \(actualLength) is less than minimum \(minLength)"

        case .stringTooLong(let maxLength, let actualLength, let path):
            return "\(pathPrefix(path))String length \(actualLength) is greater than maximum \(maxLength)"

        case .patternMismatch(let pattern, let path):
            return "\(pathPrefix(path))String does not match pattern '\(pattern)'"

        case .formatMismatch(let format, _, let path):
            return "\(pathPrefix(path))String does not match format '\(format)'"

        case .numberTooSmall(let minimum, let actual, let exclusive, let path):
            let op = exclusive ? ">" : ">="
            return "\(pathPrefix(path))Value \(actual) must be \(op) \(minimum)"

        case .numberTooLarge(let maximum, let actual, let exclusive, let path):
            let op = exclusive ? "<" : "<="
            return "\(pathPrefix(path))Value \(actual) must be \(op) \(maximum)"

        case .notMultipleOf(let multipleOf, let actual, let path):
            return "\(pathPrefix(path))Value \(actual) is not a multiple of \(multipleOf)"

        case .requiredPropertyMissing(let property, let path):
            return "\(pathPrefix(path))Missing required property '\(property)'"

        case .additionalPropertyNotAllowed(let property, let path):
            return "\(pathPrefix(path))Additional property '\(property)' is not allowed"

        case .tooFewProperties(let minProperties, let actual, let path):
            return "\(pathPrefix(path))Object has \(actual) properties but minimum is \(minProperties)"

        case .tooManyProperties(let maxProperties, let actual, let path):
            return "\(pathPrefix(path))Object has \(actual) properties but maximum is \(maxProperties)"

        case .tooFewItems(let minItems, let actual, let path):
            return "\(pathPrefix(path))Array has \(actual) items but minimum is \(minItems)"

        case .tooManyItems(let maxItems, let actual, let path):
            return "\(pathPrefix(path))Array has \(actual) items but maximum is \(maxItems)"

        case .duplicateItems(let path):
            return "\(pathPrefix(path))Array contains duplicate items"

        case .notInEnum(let allowedValues, let path):
            return "\(pathPrefix(path))Value must be one of: \(allowedValues.joined(separator: ", "))"

        case .constMismatch(let expected, let actual, let path):
            return "\(pathPrefix(path))Value must be '\(expected)' but got '\(actual)'"

        case .allOfFailed(let errors, let path):
            return "\(pathPrefix(path))Failed allOf validation with \(errors.count) error(s)"

        case .anyOfFailed(let path):
            return "\(pathPrefix(path))Value does not match any schema in anyOf"

        case .oneOfFailed(let matchCount, let path):
            if matchCount == 0 {
                return "\(pathPrefix(path))Value does not match any schema in oneOf"
            } else {
                return "\(pathPrefix(path))Value matches \(matchCount) schemas in oneOf but must match exactly one"
            }

        case .notFailed(let path):
            return "\(pathPrefix(path))Value should not match the schema in 'not'"
        }
    }

    private func pathPrefix(_ path: String) -> String {
        path.isEmpty ? "" : "\(path): "
    }
}

// MARK: - Array Extension for Typed Throws

extension Array: @retroactive Error where Element == ValidationError {}
