import Foundation

/// Validates object constraints for JSON Schema.
enum ObjectValidator {
    /// Validate an object value against schema constraints.
    static func validate(
        _ value: [String: Any],
        schema: [String: Any],
        path: String,
        validator: JSONSchemaValidator,
        errors: inout [ValidationError]
    ) {
        // required
        if let required = schema["required"] as? [String] {
            for property in required {
                if value[property] == nil {
                    errors.append(.requiredPropertyMissing(property: property, path: path))
                }
            }
        }

        // properties - validate each defined property
        let definedProperties = schema["properties"] as? [String: Any] ?? [:]

        for (propName, propSchema) in definedProperties {
            if let propValue = value[propName], let propSchemaDict = propSchema as? [String: Any] {
                let propPath = path.isEmpty ? propName : "\(path)/\(propName)"
                validator.validateValue(propValue, schema: propSchemaDict, path: propPath, errors: &errors)
            }
        }

        // additionalProperties
        if let additionalProps = schema["additionalProperties"] {
            let definedKeys = Set(definedProperties.keys)
            let patternKeys = getPatternPropertyKeys(schema: schema, objectKeys: Array(value.keys))
            let extraKeys = Set(value.keys).subtracting(definedKeys).subtracting(patternKeys)

            if let additionalAllowed = additionalProps as? Bool {
                if !additionalAllowed {
                    for key in extraKeys {
                        errors.append(.additionalPropertyNotAllowed(property: key, path: path))
                    }
                }
            } else if let additionalSchema = additionalProps as? [String: Any] {
                for key in extraKeys {
                    if let propValue = value[key] {
                        let propPath = path.isEmpty ? key : "\(path)/\(key)"
                        validator.validateValue(propValue, schema: additionalSchema, path: propPath, errors: &errors)
                    }
                }
            }
        }

        // patternProperties
        if let patternProperties = schema["patternProperties"] as? [String: Any] {
            for (pattern, patternSchema) in patternProperties {
                guard let patternSchemaDict = patternSchema as? [String: Any] else { continue }

                for (key, propValue) in value {
                    if matchesPattern(key, pattern: pattern) {
                        let propPath = path.isEmpty ? key : "\(path)/\(key)"
                        validator.validateValue(propValue, schema: patternSchemaDict, path: propPath, errors: &errors)
                    }
                }
            }
        }

        // minProperties
        if let minProperties = schema["minProperties"] as? Int {
            if value.count < minProperties {
                errors.append(.tooFewProperties(minProperties: minProperties, actual: value.count, path: path))
            }
        }

        // maxProperties
        if let maxProperties = schema["maxProperties"] as? Int {
            if value.count > maxProperties {
                errors.append(.tooManyProperties(maxProperties: maxProperties, actual: value.count, path: path))
            }
        }
    }

    /// Get keys that match pattern properties.
    private static func getPatternPropertyKeys(schema: [String: Any], objectKeys: [String]) -> Set<String> {
        guard let patternProperties = schema["patternProperties"] as? [String: Any] else {
            return []
        }

        var matchedKeys = Set<String>()
        for pattern in patternProperties.keys {
            for key in objectKeys {
                if matchesPattern(key, pattern: pattern) {
                    matchedKeys.insert(key)
                }
            }
        }
        return matchedKeys
    }

    /// Check if a string matches a regex pattern.
    private static func matchesPattern(_ value: String, pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: value.utf16.count)
            return regex.firstMatch(in: value, options: [], range: range) != nil
        } catch {
            return false
        }
    }
}
