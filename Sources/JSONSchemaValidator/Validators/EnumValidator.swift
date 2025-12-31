import Foundation

/// Validates enum and const constraints for JSON Schema.
enum EnumValidator {
    /// Validate a value against an enum constraint.
    static func validateEnum(
        _ value: Any?,
        allowedValues: [Any],
        path: String,
        errors: inout [ValidationError]
    ) {
        let valueMatches = allowedValues.contains { areEqual($0, value) }

        if !valueMatches {
            let allowedStrings = allowedValues.map { stringValue($0) }
            errors.append(.notInEnum(allowedValues: allowedStrings, path: path))
        }
    }

    /// Validate a value against a const constraint.
    static func validateConst(
        _ value: Any?,
        expected: Any,
        path: String,
        errors: inout [ValidationError]
    ) {
        if !areEqual(expected, value) {
            errors.append(.constMismatch(expected: stringValue(expected), actual: stringValue(value), path: path))
        }
    }

    /// Check if two values are equal for JSON Schema purposes.
    private static func areEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        // Handle nil/null
        if lhs == nil || lhs is NSNull {
            return rhs == nil || rhs is NSNull
        }
        if rhs == nil || rhs is NSNull {
            return false
        }

        // String comparison
        if let lhsString = lhs as? String, let rhsString = rhs as? String {
            return lhsString == rhsString
        }

        // Boolean comparison (must be before number to avoid Bool being treated as number)
        if let lhsBool = lhs as? Bool, let rhsBool = rhs as? Bool {
            return lhsBool == rhsBool
        }

        // Number comparison
        if let lhsNum = extractDouble(lhs), let rhsNum = extractDouble(rhs) {
            // Handle potential Bool-as-NSNumber issues
            if lhs is Bool || rhs is Bool {
                return false
            }
            return lhsNum == rhsNum
        }

        // Array comparison
        if let lhsArray = lhs as? [Any], let rhsArray = rhs as? [Any] {
            guard lhsArray.count == rhsArray.count else { return false }
            for (lhsItem, rhsItem) in zip(lhsArray, rhsArray) {
                if !areEqual(lhsItem, rhsItem) {
                    return false
                }
            }
            return true
        }

        // Object comparison
        if let lhsDict = lhs as? [String: Any], let rhsDict = rhs as? [String: Any] {
            guard lhsDict.count == rhsDict.count else { return false }
            for (key, lhsValue) in lhsDict {
                guard let rhsValue = rhsDict[key], areEqual(lhsValue, rhsValue) else {
                    return false
                }
            }
            return true
        }

        return false
    }

    /// Extract a Double from a value.
    private static func extractDouble(_ value: Any?) -> Double? {
        if value is Bool {
            return nil
        }
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

    /// Get a string representation of a value.
    private static func stringValue(_ value: Any?) -> String {
        if value == nil || value is NSNull {
            return "null"
        }
        if let string = value as? String {
            return "\"\(string)\""
        }
        if let bool = value as? Bool {
            return bool ? "true" : "false"
        }
        if let array = value as? [Any] {
            let items = array.map { stringValue($0) }
            return "[\(items.joined(separator: ", "))]"
        }
        if let dict = value as? [String: Any] {
            let pairs = dict.map { "\"\($0.key)\": \(stringValue($0.value))" }
            return "{\(pairs.joined(separator: ", "))}"
        }
        return String(describing: value!)
    }
}
