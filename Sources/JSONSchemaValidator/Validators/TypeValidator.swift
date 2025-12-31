import Foundation

/// Validates type constraints for JSON Schema.
enum TypeValidator {
    /// Check if a value matches the expected JSON Schema type.
    static func checkType(_ value: Any?, expectedType: String) -> Bool {
        switch expectedType {
        case "string":
            return value is String

        case "number":
            return isNumber(value)

        case "integer":
            return isInteger(value)

        case "boolean":
            return value is Bool

        case "object":
            return value is [String: Any]

        case "array":
            return value is [Any]

        case "null":
            return value == nil || value is NSNull

        default:
            return false
        }
    }

    /// Get the actual JSON Schema type name for a value.
    static func getActualType(_ value: Any?) -> String {
        if value == nil || value is NSNull {
            return "null"
        }

        switch value {
        case is String:
            return "string"
        case is Bool:
            // Note: In Swift, Bool must be checked before number types
            // because Bool can be bridged to NSNumber
            return "boolean"
        case is Int, is Double, is Float, is NSNumber:
            if isInteger(value) {
                return "integer"
            }
            return "number"
        case is [String: Any]:
            return "object"
        case is [Any]:
            return "array"
        default:
            return "unknown"
        }
    }

    /// Check if a value is a number (integer or floating point).
    static func isNumber(_ value: Any?) -> Bool {
        if value is Bool {
            return false // Bools should not be treated as numbers
        }
        return value is Int || value is Double || value is Float || value is NSNumber
    }

    /// Check if a value is an integer.
    static func isInteger(_ value: Any?) -> Bool {
        if value is Bool {
            return false
        }

        if value is Int {
            return true
        }

        if let double = value as? Double {
            return double.truncatingRemainder(dividingBy: 1) == 0
        }

        if let float = value as? Float {
            return Float(Int(float)) == float
        }

        if let nsNumber = value as? NSNumber {
            let doubleValue = nsNumber.doubleValue
            return doubleValue.truncatingRemainder(dividingBy: 1) == 0
        }

        return false
    }

    /// Extract a Double from a numeric value.
    static func extractNumber(_ value: Any?) -> Double? {
        if value is Bool {
            return nil
        }

        if let int = value as? Int {
            return Double(int)
        }

        if let double = value as? Double {
            return double
        }

        if let float = value as? Float {
            return Double(float)
        }

        if let nsNumber = value as? NSNumber {
            return nsNumber.doubleValue
        }

        return nil
    }
}
