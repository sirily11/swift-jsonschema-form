import Foundation
import JSONSchema

/// Main JSON Schema validator class.
/// Validates data against JSON Schema dictionaries or JSONSchema objects using Swift 6 typed throws.
public struct JSONSchemaValidator: JSONSchemaValidating, Sendable {
    /// Shared instance for convenience
    public static let shared = JSONSchemaValidator()

    public init() {}

    // MARK: - Public API

    /// Validate data against a JSON Schema dictionary.
    ///
    /// - Parameters:
    ///   - data: The data to validate (dictionary, array, or primitive value)
    ///   - schema: The JSON Schema as a dictionary
    /// - Throws: Array of `ValidationError` if validation fails
    public func validate(_ data: Any?, schema: [String: Any]) throws([ValidationError]) {
        var errors: [ValidationError] = []
        validateValue(data, schema: schema, path: "", errors: &errors)

        if !errors.isEmpty {
            throw errors
        }
    }

    /// Static convenience method for validation.
    ///
    /// - Parameters:
    ///   - data: The data to validate
    ///   - schema: The JSON Schema as a dictionary
    /// - Throws: Array of `ValidationError` if validation fails
    public static func validate(_ data: Any?, schema: [String: Any]) throws([ValidationError]) {
        try shared.validate(data, schema: schema)
    }

    /// Validate data against a JSONSchema object from swift-json-schema.
    ///
    /// - Parameters:
    ///   - data: The data to validate (dictionary, array, or primitive value)
    ///   - schema: The JSONSchema object
    /// - Throws: Array of `ValidationError` if validation fails
    public func validate(_ data: Any?, schema: JSONSchema) throws([ValidationError]) {
        let schemaDict = convertToDict(schema)
        try validate(data, schema: schemaDict)
    }

    /// Static convenience method for JSONSchema validation.
    ///
    /// - Parameters:
    ///   - data: The data to validate
    ///   - schema: The JSONSchema object
    /// - Throws: Array of `ValidationError` if validation fails
    public static func validate(_ data: Any?, schema: JSONSchema) throws([ValidationError]) {
        try shared.validate(data, schema: schema)
    }

    // MARK: - Internal Validation

    internal func validateValue(
        _ value: Any?,
        schema: [String: Any],
        path: String,
        errors: inout [ValidationError]
    ) {
        // Handle boolean schemas
        if let boolSchema = schema["$schema"] as? Bool {
            if !boolSchema && value != nil {
                errors.append(.invalidSchema(message: "Schema is false, all values are invalid"))
            }
            return
        }

        // Check for combinators first (allOf, anyOf, oneOf, not, if/then/else)
        if schema["allOf"] != nil || schema["anyOf"] != nil || schema["oneOf"] != nil ||
           schema["not"] != nil || schema["if"] != nil {
            CombinatorsValidator.validate(value, schema: schema, path: path, validator: self, errors: &errors)
        }

        // Check enum constraint
        if let enumValues = schema["enum"] as? [Any] {
            EnumValidator.validateEnum(value, allowedValues: enumValues, path: path, errors: &errors)
        }

        // Check const constraint
        if let constValue = schema["const"] {
            EnumValidator.validateConst(value, expected: constValue, path: path, errors: &errors)
        }

        // Type-specific validation
        if let type = schema["type"] {
            validateType(value, type: type, schema: schema, path: path, errors: &errors)
        } else {
            // No explicit type - infer from schema keywords and validate
            // This handles cases like if/then/else conditions without explicit type
            if schema["properties"] != nil || schema["required"] != nil ||
               schema["additionalProperties"] != nil || schema["minProperties"] != nil ||
               schema["maxProperties"] != nil || schema["patternProperties"] != nil {
                // Has object-related keywords
                if let objectValue = value as? [String: Any] {
                    ObjectValidator.validate(objectValue, schema: schema, path: path, validator: self, errors: &errors)
                }
            }

            if schema["items"] != nil || schema["prefixItems"] != nil ||
               schema["minItems"] != nil || schema["maxItems"] != nil ||
               schema["uniqueItems"] != nil || schema["contains"] != nil {
                // Has array-related keywords
                if let arrayValue = value as? [Any] {
                    ArrayValidator.validate(arrayValue, schema: schema, path: path, validator: self, errors: &errors)
                }
            }

            // String constraints without explicit type
            if let stringValue = value as? String {
                if schema["minLength"] != nil || schema["maxLength"] != nil ||
                   schema["pattern"] != nil || schema["format"] != nil {
                    StringValidator.validate(stringValue, schema: schema, path: path, errors: &errors)
                }
            }

            // Number constraints without explicit type
            if let number = TypeValidator.extractNumber(value) {
                if schema["minimum"] != nil || schema["maximum"] != nil ||
                   schema["exclusiveMinimum"] != nil || schema["exclusiveMaximum"] != nil ||
                   schema["multipleOf"] != nil {
                    NumberValidator.validate(number, schema: schema, isInteger: false, path: path, errors: &errors)
                }
            }
        }
    }

    private func validateType(
        _ value: Any?,
        type: Any,
        schema: [String: Any],
        path: String,
        errors: inout [ValidationError]
    ) {
        // Handle type arrays (e.g., ["string", "null"])
        if let typeArray = type as? [String] {
            var matchedAny = false
            for singleType in typeArray {
                if TypeValidator.checkType(value, expectedType: singleType) {
                    matchedAny = true
                    validateForType(value, type: singleType, schema: schema, path: path, errors: &errors)
                    break
                }
            }
            if !matchedAny {
                let actualType = TypeValidator.getActualType(value)
                errors.append(.typeMismatch(expected: typeArray.joined(separator: " or "), actual: actualType, path: path))
            }
            return
        }

        // Handle single type
        guard let typeString = type as? String else {
            errors.append(.invalidSchema(message: "Invalid type value in schema"))
            return
        }

        // Check type match
        if !TypeValidator.checkType(value, expectedType: typeString) {
            let actualType = TypeValidator.getActualType(value)
            errors.append(.typeMismatch(expected: typeString, actual: actualType, path: path))
            return
        }

        // Validate type-specific constraints
        validateForType(value, type: typeString, schema: schema, path: path, errors: &errors)
    }

    private func validateForType(
        _ value: Any?,
        type: String,
        schema: [String: Any],
        path: String,
        errors: inout [ValidationError]
    ) {
        switch type {
        case "string":
            if let stringValue = value as? String {
                StringValidator.validate(stringValue, schema: schema, path: path, errors: &errors)
            }

        case "number", "integer":
            if let number = TypeValidator.extractNumber(value) {
                NumberValidator.validate(number, schema: schema, isInteger: type == "integer", path: path, errors: &errors)
            }

        case "object":
            if let objectValue = value as? [String: Any] {
                ObjectValidator.validate(objectValue, schema: schema, path: path, validator: self, errors: &errors)
            }

        case "array":
            if let arrayValue = value as? [Any] {
                ArrayValidator.validate(arrayValue, schema: schema, path: path, validator: self, errors: &errors)
            }

        case "boolean", "null":
            // No additional constraints for boolean and null
            break

        default:
            break
        }
    }

    // MARK: - JSONSchema Conversion

    /// Convert a JSONSchema object to a dictionary for validation.
    private func convertToDict(_ schema: JSONSchema) -> [String: Any] {
        var dict: [String: Any] = [:]

        // Add type
        switch schema.type {
        case .array:
            dict["type"] = "array"
        case .boolean:
            dict["type"] = "boolean"
        case .enum:
            // Enum doesn't have explicit type
            break
        case .integer:
            dict["type"] = "integer"
        case .null:
            dict["type"] = "null"
        case .number:
            dict["type"] = "number"
        case .object:
            dict["type"] = "object"
        case .string:
            dict["type"] = "string"
        case .oneOf, .anyOf, .allOf:
            // Combined schemas don't have explicit type
            break
        }

        // String schema
        if let stringSchema = schema.stringSchema {
            if let minLength = stringSchema.minLength {
                dict["minLength"] = minLength
            }
            if let maxLength = stringSchema.maxLength {
                dict["maxLength"] = maxLength
            }
            if let pattern = stringSchema.pattern {
                dict["pattern"] = pattern
            }
            if let format = stringSchema.format {
                dict["format"] = format
            }
        }

        // Number schema
        if let numberSchema = schema.numberSchema {
            if let minimum = numberSchema.minimum {
                dict["minimum"] = minimum
            }
            if let maximum = numberSchema.maximum {
                dict["maximum"] = maximum
            }
            if let exclusiveMinimum = numberSchema.exclusiveMinimum {
                dict["exclusiveMinimum"] = exclusiveMinimum
            }
            if let exclusiveMaximum = numberSchema.exclusiveMaximum {
                dict["exclusiveMaximum"] = exclusiveMaximum
            }
            if let multipleOf = numberSchema.multipleOf {
                dict["multipleOf"] = multipleOf
            }
        }

        // Integer schema (uses same constraints as number)
        if let integerSchema = schema.integerSchema {
            if let minimum = integerSchema.minimum {
                dict["minimum"] = minimum
            }
            if let maximum = integerSchema.maximum {
                dict["maximum"] = maximum
            }
            if let exclusiveMinimum = integerSchema.exclusiveMinimum {
                dict["exclusiveMinimum"] = exclusiveMinimum
            }
            if let exclusiveMaximum = integerSchema.exclusiveMaximum {
                dict["exclusiveMaximum"] = exclusiveMaximum
            }
            if let multipleOf = integerSchema.multipleOf {
                dict["multipleOf"] = multipleOf
            }
        }

        // Object schema
        if let objectSchema = schema.objectSchema {
            if let properties = objectSchema.properties {
                var propertiesDict: [String: Any] = [:]
                for (key, value) in properties {
                    propertiesDict[key] = convertToDict(value)
                }
                dict["properties"] = propertiesDict
            }
            if let required = objectSchema.required {
                dict["required"] = required
            }
            if let minProperties = objectSchema.minProperties {
                dict["minProperties"] = minProperties
            }
            if let maxProperties = objectSchema.maxProperties {
                dict["maxProperties"] = maxProperties
            }
            if let additionalProperties = objectSchema.additionalProperties {
                switch additionalProperties {
                case .boolean(let value):
                    dict["additionalProperties"] = value
                case .schema(let additionalSchema):
                    dict["additionalProperties"] = convertToDict(additionalSchema)
                }
            }
            if let patternProperties = objectSchema.patternProperties {
                var patternDict: [String: Any] = [:]
                for (pattern, patternSchema) in patternProperties {
                    patternDict[pattern] = convertToDict(patternSchema)
                }
                dict["patternProperties"] = patternDict
            }
        }

        // Array schema
        if let arraySchema = schema.arraySchema {
            if let items = arraySchema.items {
                dict["items"] = convertToDict(items)
            }
            if let prefixItems = arraySchema.prefixItems {
                dict["prefixItems"] = prefixItems.map { convertToDict($0) }
            }
            if let minItems = arraySchema.minItems {
                dict["minItems"] = minItems
            }
            if let maxItems = arraySchema.maxItems {
                dict["maxItems"] = maxItems
            }
            if let uniqueItems = arraySchema.uniqueItems {
                dict["uniqueItems"] = uniqueItems
            }
        }

        // Enum schema
        if let enumSchema = schema.enumSchema {
            var enumValues: [Any] = []
            for value in enumSchema.values {
                switch value {
                case .string(let s):
                    enumValues.append(s)
                case .number(let n):
                    enumValues.append(n)
                case .integer(let i):
                    enumValues.append(i)
                case .boolean(let b):
                    enumValues.append(b)
                case .null:
                    enumValues.append(NSNull())
                }
            }
            dict["enum"] = enumValues
        }

        // Combined schema (oneOf, anyOf, allOf)
        if let combinedSchema = schema.combinedSchema {
            if let oneOf = combinedSchema.oneOf {
                dict["oneOf"] = oneOf.map { convertToDict($0) }
            }
            if let anyOf = combinedSchema.anyOf {
                dict["anyOf"] = anyOf.map { convertToDict($0) }
            }
            if let allOf = combinedSchema.allOf {
                dict["allOf"] = allOf.map { convertToDict($0) }
            }
        }

        return dict
    }
}
