import Foundation

/// Validates number and integer constraints for JSON Schema.
enum NumberValidator {
    /// Validate a numeric value against schema constraints.
    static func validate(
        _ value: Double,
        schema: [String: Any],
        isInteger: Bool,
        path: String,
        errors: inout [ValidationError]
    ) {
        // For integer type, verify it's actually an integer
        if isInteger && value.truncatingRemainder(dividingBy: 1) != 0 {
            errors.append(.typeMismatch(expected: "integer", actual: "number", path: path))
            return
        }

        // minimum (inclusive)
        if let minimum = extractDouble(schema["minimum"]) {
            if value < minimum {
                errors.append(.numberTooSmall(minimum: minimum, actual: value, exclusive: false, path: path))
            }
        }

        // exclusiveMinimum
        if let exclusiveMinimum = extractDouble(schema["exclusiveMinimum"]) {
            if value <= exclusiveMinimum {
                errors.append(.numberTooSmall(minimum: exclusiveMinimum, actual: value, exclusive: true, path: path))
            }
        }

        // maximum (inclusive)
        if let maximum = extractDouble(schema["maximum"]) {
            if value > maximum {
                errors.append(.numberTooLarge(maximum: maximum, actual: value, exclusive: false, path: path))
            }
        }

        // exclusiveMaximum
        if let exclusiveMaximum = extractDouble(schema["exclusiveMaximum"]) {
            if value >= exclusiveMaximum {
                errors.append(.numberTooLarge(maximum: exclusiveMaximum, actual: value, exclusive: true, path: path))
            }
        }

        // multipleOf
        if let multipleOf = extractDouble(schema["multipleOf"]), multipleOf != 0 {
            let remainder = value.truncatingRemainder(dividingBy: multipleOf)
            // Use epsilon comparison for floating point
            if abs(remainder) > Double.ulpOfOne && abs(remainder - multipleOf) > Double.ulpOfOne {
                errors.append(.notMultipleOf(multipleOf: multipleOf, actual: value, path: path))
            }
        }
    }

    /// Extract a Double from a schema value.
    private static func extractDouble(_ value: Any?) -> Double? {
        if let int = value as? Int {
            return Double(int)
        }
        if let double = value as? Double {
            return double
        }
        if let nsNumber = value as? NSNumber {
            return nsNumber.doubleValue
        }
        return nil
    }
}
