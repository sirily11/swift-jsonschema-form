import Foundation

/// Represents a conditional schema with if/then/else structure
public struct ConditionalSchema {
    public let condition: [String: Any]
    public let thenSchema: [String: Any]?
    public let elseSchema: [String: Any]?

    public init(condition: [String: Any], thenSchema: [String: Any]?, elseSchema: [String: Any]?) {
        self.condition = condition
        self.thenSchema = thenSchema
        self.elseSchema = elseSchema
    }
}

// Mark as Sendable using @unchecked since we know the underlying data is safe
extension ConditionalSchema: @unchecked Sendable {}

/// Evaluates JSON Schema conditions against form data
public enum ConditionEvaluator {

    /// Evaluates a condition against form data
    /// Supports conditions like: {"properties": {"animal": {"const": "Cat"}}}
    public static func evaluate(condition: [String: Any], formData: FormData) -> Bool {
        // Handle "properties" condition
        if let properties = condition["properties"] as? [String: Any] {
            return evaluatePropertiesCondition(properties: properties, formData: formData)
        }

        // Handle "required" condition - check if required fields exist
        if let required = condition["required"] as? [String] {
            return evaluateRequiredCondition(required: required, formData: formData)
        }

        // If no recognizable condition, return true (no constraint)
        return true
    }

    /// Evaluates a properties condition
    /// Example: {"animal": {"const": "Cat"}} checks if formData.animal == "Cat"
    private static func evaluatePropertiesCondition(
        properties: [String: Any],
        formData: FormData
    ) -> Bool {
        guard case .object(let formProperties) = formData else {
            return false
        }

        for (propertyName, constraint) in properties {
            guard let constraintDict = constraint as? [String: Any] else {
                continue
            }

            let propertyValue = formProperties[propertyName]

            // Handle "const" constraint
            if let constValue = constraintDict["const"] {
                if !matchesConst(propertyValue: propertyValue, constValue: constValue) {
                    return false
                }
            }

            // Handle "enum" constraint
            if let enumValues = constraintDict["enum"] as? [Any] {
                if !matchesEnum(propertyValue: propertyValue, enumValues: enumValues) {
                    return false
                }
            }

            // Handle nested "properties" (for nested object conditions)
            if let nestedProperties = constraintDict["properties"] as? [String: Any],
               let nestedFormData = propertyValue {
                if !evaluatePropertiesCondition(properties: nestedProperties, formData: nestedFormData) {
                    return false
                }
            }
        }

        return true
    }

    /// Evaluates a required condition - checks if all required fields have non-null values
    private static func evaluateRequiredCondition(required: [String], formData: FormData) -> Bool {
        guard case .object(let properties) = formData else {
            return false
        }

        for fieldName in required {
            guard let value = properties[fieldName] else {
                return false
            }
            if case .null = value {
                return false
            }
        }

        return true
    }

    /// Checks if a property value matches a const value
    private static func matchesConst(propertyValue: FormData?, constValue: Any) -> Bool {
        guard let propertyValue = propertyValue else {
            return false
        }

        switch propertyValue {
        case .string(let str):
            return (constValue as? String) == str
        case .number(let num):
            if let constNum = constValue as? Double {
                return constNum == num
            }
            if let constInt = constValue as? Int {
                return Double(constInt) == num
            }
            return false
        case .boolean(let bool):
            return (constValue as? Bool) == bool
        case .null:
            return constValue is NSNull
        default:
            return false
        }
    }

    /// Checks if a property value matches one of the enum values
    private static func matchesEnum(propertyValue: FormData?, enumValues: [Any]) -> Bool {
        guard let propertyValue = propertyValue else {
            return false
        }

        for enumValue in enumValues {
            if matchesConst(propertyValue: propertyValue, constValue: enumValue) {
                return true
            }
        }

        return false
    }

    /// Get applicable schemas based on current form data
    /// For each conditional, returns the "then" schema if condition matches,
    /// or the "else" schema if condition doesn't match
    public static func getApplicableSchemas(
        conditionals: [ConditionalSchema],
        formData: FormData
    ) -> [[String: Any]] {
        var applicableSchemas: [[String: Any]] = []

        for conditional in conditionals {
            let conditionMatches = evaluate(condition: conditional.condition, formData: formData)

            if conditionMatches {
                if let thenSchema = conditional.thenSchema {
                    applicableSchemas.append(thenSchema)
                }
            } else {
                if let elseSchema = conditional.elseSchema {
                    applicableSchemas.append(elseSchema)
                }
            }
        }

        return applicableSchemas
    }

    /// Get property names from applicable schemas
    /// Used to determine which conditional fields should be visible
    public static func getApplicablePropertyNames(
        conditionals: [ConditionalSchema],
        formData: FormData
    ) -> Set<String> {
        let schemas = getApplicableSchemas(conditionals: conditionals, formData: formData)
        var propertyNames: Set<String> = []

        for schema in schemas {
            if let properties = schema["properties"] as? [String: Any] {
                propertyNames.formUnion(properties.keys)
            }
        }

        return propertyNames
    }

    /// Get required fields from applicable schemas
    public static func getApplicableRequired(
        conditionals: [ConditionalSchema],
        formData: FormData
    ) -> [String] {
        let schemas = getApplicableSchemas(conditionals: conditionals, formData: formData)
        var requiredFields: Set<String> = []

        for schema in schemas {
            if let required = schema["required"] as? [String] {
                requiredFields.formUnion(required)
            }
        }

        return Array(requiredFields)
    }
}
