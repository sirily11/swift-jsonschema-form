import Foundation

/// Validates string constraints for JSON Schema.
enum StringValidator {
    /// Validate a string value against schema constraints.
    static func validate(
        _ value: String,
        schema: [String: Any],
        path: String,
        errors: inout [ValidationError]
    ) {
        // minLength
        if let minLength = schema["minLength"] as? Int {
            if value.count < minLength {
                errors.append(.stringTooShort(minLength: minLength, actualLength: value.count, path: path))
            }
        }

        // maxLength
        if let maxLength = schema["maxLength"] as? Int {
            if value.count > maxLength {
                errors.append(.stringTooLong(maxLength: maxLength, actualLength: value.count, path: path))
            }
        }

        // pattern
        if let pattern = schema["pattern"] as? String {
            if !matchesPattern(value, pattern: pattern) {
                errors.append(.patternMismatch(pattern: pattern, path: path))
            }
        }

        // format
        if let format = schema["format"] as? String {
            if !FormatValidator.validate(value, format: format) {
                errors.append(.formatMismatch(format: format, value: value, path: path))
            }
        }
    }

    /// Check if a string matches a regex pattern.
    private static func matchesPattern(_ value: String, pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: value.utf16.count)
            return regex.firstMatch(in: value, options: [], range: range) != nil
        } catch {
            // Invalid regex pattern - treat as no match
            return false
        }
    }
}
