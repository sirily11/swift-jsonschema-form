typealias FieldError = String
/// The type that describes the list of errors for a field
public struct FieldErrors {
    /** The list of errors for the field */
    var __errors: [FieldError]?
}

/// Type describing a recursive structure of `FieldErrors`s for an object with a non-empty set of keys
public struct ErrorSchema<T> {
    /** The list of errors for the field */
    var __errors: [FieldError]?

    /** The set of errors for fields in the recursive object structure */
    private var _nestedErrors: [String: Any] = [:]

    // Subscript to get/set nested error schemas
    subscript<U>(key: KeyPath<T, U>) -> ErrorSchema<U>? {
        get {
            let keyString = _convertKeyPathToString(key)
            return _nestedErrors[keyString] as? ErrorSchema<U>
        }
        set {
            let keyString = _convertKeyPathToString(key)
            if let newValue = newValue {
                _nestedErrors[keyString] = newValue
            } else {
                _nestedErrors.removeValue(forKey: keyString)
            }
        }
    }

    // Helper function to convert KeyPath to String
    private func _convertKeyPathToString<U>(_ keyPath: KeyPath<T, U>) -> String {
        // In actual implementation, you would need a way to convert KeyPath to String
        // This is a simplified version just to show the concept
        return "\(keyPath)"
    }
}
