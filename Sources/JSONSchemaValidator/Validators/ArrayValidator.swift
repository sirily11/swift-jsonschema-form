import Foundation

/// Validates array constraints for JSON Schema.
enum ArrayValidator {
    /// Validate an array value against schema constraints.
    static func validate(
        _ value: [Any],
        schema: [String: Any],
        path: String,
        validator: JSONSchemaValidator,
        errors: inout [ValidationError]
    ) {
        // minItems
        if let minItems = schema["minItems"] as? Int {
            if value.count < minItems {
                errors.append(.tooFewItems(minItems: minItems, actual: value.count, path: path))
            }
        }

        // maxItems
        if let maxItems = schema["maxItems"] as? Int {
            if value.count > maxItems {
                errors.append(.tooManyItems(maxItems: maxItems, actual: value.count, path: path))
            }
        }

        // uniqueItems
        if let uniqueItems = schema["uniqueItems"] as? Bool, uniqueItems {
            if hasDuplicates(value) {
                errors.append(.duplicateItems(path: path))
            }
        }

        // prefixItems (JSON Schema draft 2020-12) or tuple validation
        if let prefixItems = schema["prefixItems"] as? [[String: Any]] {
            for (index, itemSchema) in prefixItems.enumerated() {
                if index < value.count {
                    let itemPath = "\(path)[\(index)]"
                    validator.validateValue(value[index], schema: itemSchema, path: itemPath, errors: &errors)
                }
            }

            // items applies to additional items after prefixItems
            if let itemsSchema = schema["items"] as? [String: Any] {
                for index in prefixItems.count..<value.count {
                    let itemPath = "\(path)[\(index)]"
                    validator.validateValue(value[index], schema: itemsSchema, path: itemPath, errors: &errors)
                }
            } else if let itemsAllowed = schema["items"] as? Bool, !itemsAllowed {
                // items: false means no additional items allowed
                if value.count > prefixItems.count {
                    errors.append(.tooManyItems(maxItems: prefixItems.count, actual: value.count, path: path))
                }
            }
        } else if let itemsSchema = schema["items"] as? [String: Any] {
            // items - validate each item against the items schema (when no prefixItems)
            for (index, item) in value.enumerated() {
                let itemPath = "\(path)[\(index)]"
                validator.validateValue(item, schema: itemsSchema, path: itemPath, errors: &errors)
            }
        }

        // contains - at least one item must match
        if let containsSchema = schema["contains"] as? [String: Any] {
            var matchCount = 0
            for item in value {
                var itemErrors: [ValidationError] = []
                validator.validateValue(item, schema: containsSchema, path: "", errors: &itemErrors)
                if itemErrors.isEmpty {
                    matchCount += 1
                }
            }

            // minContains (default 1)
            let minContains = schema["minContains"] as? Int ?? 1
            if matchCount < minContains {
                errors.append(.tooFewItems(minItems: minContains, actual: matchCount, path: path))
            }

            // maxContains
            if let maxContains = schema["maxContains"] as? Int {
                if matchCount > maxContains {
                    errors.append(.tooManyItems(maxItems: maxContains, actual: matchCount, path: path))
                }
            }
        }
    }

    /// Check if an array has duplicate items.
    private static func hasDuplicates(_ array: [Any]) -> Bool {
        var seen = Set<String>()
        for item in array {
            let key = stringRepresentation(item)
            if seen.contains(key) {
                return true
            }
            seen.insert(key)
        }
        return false
    }

    /// Get a string representation of a value for comparison.
    private static func stringRepresentation(_ value: Any) -> String {
        if let dict = value as? [String: Any] {
            // Sort keys for consistent comparison
            let sortedPairs = dict.sorted { $0.key < $1.key }
            let pairs = sortedPairs.map { "\($0.key):\(stringRepresentation($0.value))" }
            return "{\(pairs.joined(separator: ","))}"
        }
        if let array = value as? [Any] {
            let items = array.map { stringRepresentation($0) }
            return "[\(items.joined(separator: ","))]"
        }
        if value is NSNull {
            return "null"
        }
        return String(describing: value)
    }
}
