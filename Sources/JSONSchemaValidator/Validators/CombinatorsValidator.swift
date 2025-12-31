import Foundation

/// Validates combinator constraints (allOf, anyOf, oneOf, not) for JSON Schema.
enum CombinatorsValidator {
    /// Validate a value against combinator constraints.
    static func validate(
        _ value: Any?,
        schema: [String: Any],
        path: String,
        validator: JSONSchemaValidator,
        errors: inout [ValidationError]
    ) {
        // allOf - value must match ALL schemas
        if let allOf = schema["allOf"] as? [[String: Any]] {
            validateAllOf(value, schemas: allOf, path: path, validator: validator, errors: &errors)
        }

        // anyOf - value must match AT LEAST ONE schema
        if let anyOf = schema["anyOf"] as? [[String: Any]] {
            validateAnyOf(value, schemas: anyOf, path: path, validator: validator, errors: &errors)
        }

        // oneOf - value must match EXACTLY ONE schema
        if let oneOf = schema["oneOf"] as? [[String: Any]] {
            validateOneOf(value, schemas: oneOf, path: path, validator: validator, errors: &errors)
        }

        // not - value must NOT match the schema
        if let notSchema = schema["not"] as? [String: Any] {
            validateNot(value, schema: notSchema, path: path, validator: validator, errors: &errors)
        }

        // if/then/else conditional validation
        if let ifSchema = schema["if"] as? [String: Any] {
            validateConditional(value, ifSchema: ifSchema, thenSchema: schema["then"] as? [String: Any], elseSchema: schema["else"] as? [String: Any], path: path, validator: validator, errors: &errors)
        }
    }

    /// Validate allOf - all schemas must match.
    private static func validateAllOf(
        _ value: Any?,
        schemas: [[String: Any]],
        path: String,
        validator: JSONSchemaValidator,
        errors: inout [ValidationError]
    ) {
        var allErrors: [ValidationError] = []

        for subSchema in schemas {
            var subErrors: [ValidationError] = []
            validator.validateValue(value, schema: subSchema, path: path, errors: &subErrors)
            allErrors.append(contentsOf: subErrors)
        }

        if !allErrors.isEmpty {
            errors.append(.allOfFailed(errors: allErrors, path: path))
        }
    }

    /// Validate anyOf - at least one schema must match.
    private static func validateAnyOf(
        _ value: Any?,
        schemas: [[String: Any]],
        path: String,
        validator: JSONSchemaValidator,
        errors: inout [ValidationError]
    ) {
        for subSchema in schemas {
            var subErrors: [ValidationError] = []
            validator.validateValue(value, schema: subSchema, path: path, errors: &subErrors)
            if subErrors.isEmpty {
                return // Found a matching schema
            }
        }

        // No schema matched
        errors.append(.anyOfFailed(path: path))
    }

    /// Validate oneOf - exactly one schema must match.
    private static func validateOneOf(
        _ value: Any?,
        schemas: [[String: Any]],
        path: String,
        validator: JSONSchemaValidator,
        errors: inout [ValidationError]
    ) {
        var matchCount = 0

        for subSchema in schemas {
            var subErrors: [ValidationError] = []
            validator.validateValue(value, schema: subSchema, path: path, errors: &subErrors)
            if subErrors.isEmpty {
                matchCount += 1
            }
        }

        if matchCount != 1 {
            errors.append(.oneOfFailed(matchCount: matchCount, path: path))
        }
    }

    /// Validate not - schema must NOT match.
    private static func validateNot(
        _ value: Any?,
        schema: [String: Any],
        path: String,
        validator: JSONSchemaValidator,
        errors: inout [ValidationError]
    ) {
        var subErrors: [ValidationError] = []
        validator.validateValue(value, schema: schema, path: path, errors: &subErrors)

        if subErrors.isEmpty {
            // Schema matched when it shouldn't have
            errors.append(.notFailed(path: path))
        }
    }

    /// Validate if/then/else conditional.
    private static func validateConditional(
        _ value: Any?,
        ifSchema: [String: Any],
        thenSchema: [String: Any]?,
        elseSchema: [String: Any]?,
        path: String,
        validator: JSONSchemaValidator,
        errors: inout [ValidationError]
    ) {
        var ifErrors: [ValidationError] = []
        validator.validateValue(value, schema: ifSchema, path: path, errors: &ifErrors)

        if ifErrors.isEmpty {
            // If condition matched, apply then schema
            if let thenSchema = thenSchema {
                validator.validateValue(value, schema: thenSchema, path: path, errors: &errors)
            }
        } else {
            // If condition didn't match, apply else schema
            if let elseSchema = elseSchema {
                validator.validateValue(value, schema: elseSchema, path: path, errors: &errors)
            }
        }
    }
}
