import SwiftUI
import JSONSchema

/// Validation result containing errors and error schema
struct ValidationResult {
    var errors: [ValidationError]
    var errorSchema: [String: Any]
}

/// Validates form data against a JSON schema
func validateFormData(
    formData: Any?,
    schema: JSONSchema,
    customValidate: ((_ formData: Any?, _ errorSchema: inout [String: Any]) -> Void)? = nil
) -> ValidationResult {
    // Basic structure for errors
    var errors: [ValidationError] = []
    var errorSchema: [String: Any] = [:]
    
    // Perform JSON Schema validation
    switch schema.type {
    case .string:
        validateString(value: formData, context: schema.stringSchema!, errors: &errors, errorSchema: &errorSchema)
        
    case .number:
        validateNumber(value: formData, context: schema.numberSchema!, errors: &errors, errorSchema: &errorSchema)
        
    case .integer:
        validateInteger(value: formData, context: schema.integerSchema!, errors: &errors, errorSchema: &errorSchema)
        
    case .boolean:
        validateBoolean(value: formData, errors: &errors, errorSchema: &errorSchema)
        
    case .object:
        validateObject(value: formData, context: schema.objectSchema!, errors: &errors, errorSchema: &errorSchema)
        
    case .array:
        validateArray(value: formData, context: schema.arraySchema!, errors: &errors, errorSchema: &errorSchema)
        
    default:
        // For unsupported schemas - we might report an error in a complex implementation
        break
    }
    
    // Apply custom validation if provided
    if let customValidate = customValidate {
        customValidate(formData, &errorSchema)
        
        // Convert any errors added by custom validation to ValidationError objects
        if let customErrors = errorSchema["__errors"] as? [String] {
            for message in customErrors {
                errors.append(ValidationError(
                    name: "custom",
                    message: message,
                    stack: message,
                    property: ""
                ))
            }
        }
    }
    
    return ValidationResult(errors: errors, errorSchema: errorSchema)
}

// MARK: - Type-specific validation functions

/// Validates a string value against schema constraints
private func validateString(
    value: Any?,
    context: JSONSchema.StringSchema,
    errors: inout [ValidationError],
    errorSchema: inout [String: Any]
) {
    // Nil check for required fields would be handled separately
    guard let stringValue = value as? String else {
        if value != nil {
            addError(
                name: "type",
                message: "should be string",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
        return
    }
    
    // Check minLength
    if let minLength = context.minLength, stringValue.count < minLength {
        addError(
            name: "minLength",
            message: "should NOT be shorter than \(minLength) characters",
            errors: &errors,
            errorSchema: &errorSchema
        )
    }
    
    // Check maxLength
    if let maxLength = context.maxLength, stringValue.count > maxLength {
        addError(
            name: "maxLength",
            message: "should NOT be longer than \(maxLength) characters",
            errors: &errors,
            errorSchema: &errorSchema
        )
    }
    
    // Check pattern
    if let pattern = context.pattern {
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: stringValue.utf16.count)
        
        if regex?.firstMatch(in: stringValue, options: [], range: range) == nil {
            addError(
                name: "pattern",
                message: "should match pattern \"\(pattern)\"",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
    }
    
    // Check format (email, uri, etc.) - simplified example for email
    if let format = context.format, format == "email" {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: stringValue) {
            addError(
                name: "format",
                message: "should match format \"email\"",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
    }
}

/// Validates a number value against schema constraints
private func validateNumber(
    value: Any?,
    context: JSONSchema.NumberSchema,
    errors: inout [ValidationError],
    errorSchema: inout [String: Any]
) {
    // Nil check for required fields would be handled separately
    guard let numValue = value as? Double else {
        if value != nil {
            addError(
                name: "type",
                message: "should be number",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
        return
    }
    
    // Check minimum
    if let minimum = context.minimum {
        if let exclusiveMinimum = context.exclusiveMinimum, numValue <= minimum {
            addError(
                name: "exclusiveMinimum",
                message: "should be > \(minimum)",
                errors: &errors,
                errorSchema: &errorSchema
            )
        } else if context.exclusiveMinimum != nil && numValue < minimum {
            addError(
                name: "minimum",
                message: "should be >= \(minimum)",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
    }
    
    // Check maximum
    if let maximum = context.maximum {
        if let exclusiveMaximum = context.exclusiveMaximum, numValue >= maximum {
            addError(
                name: "exclusiveMaximum",
                message: "should be < \(maximum)",
                errors: &errors,
                errorSchema: &errorSchema
            )
        } else if context.exclusiveMaximum != nil && numValue > maximum {
            addError(
                name: "maximum",
                message: "should be <= \(maximum)",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
    }
    
    // Check multipleOf
    if let multipleOf = context.multipleOf {
        // Simple check for integral multiples (might not be precise for floating point)
        let remainder = numValue.truncatingRemainder(dividingBy: multipleOf)
        if remainder != 0 && abs(remainder - multipleOf) > Double.ulpOfOne {
            addError(
                name: "multipleOf",
                message: "should be multiple of \(multipleOf)",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
    }
}

/// Validates an integer value against schema constraints
private func validateInteger(
    value: Any?,
    context: JSONSchema.IntegerSchema,
    errors: inout [ValidationError],
    errorSchema: inout [String: Any]
) {
    // Nil check for required fields would be handled separately
    var intValue: Int?
    
    if let int = value as? Int {
        intValue = int
    } else if let double = value as? Double, double.truncatingRemainder(dividingBy: 1) == 0 {
        intValue = Int(double)
    }
    
    guard let intValue = intValue else {
        if value != nil {
            addError(
                name: "type",
                message: "should be integer",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
        return
    }
    
    // Check minimum
    if let minimum = context.minimum {
        if let exclusiveMinimum = context.exclusiveMinimum, intValue <= minimum {
            addError(
                name: "exclusiveMinimum",
                message: "should be > \(minimum)",
                errors: &errors,
                errorSchema: &errorSchema
            )
        } else if context.exclusiveMinimum != nil && intValue < minimum {
            addError(
                name: "minimum",
                message: "should be >= \(minimum)",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
    }
    
    // Check maximum
    if let maximum = context.maximum {
        if let exclusiveMaximum = context.exclusiveMaximum, intValue >= maximum {
            addError(
                name: "exclusiveMaximum",
                message: "should be < \(maximum)",
                errors: &errors,
                errorSchema: &errorSchema
            )
        } else if context.exclusiveMaximum != nil && intValue > maximum {
            addError(
                name: "maximum",
                message: "should be <= \(maximum)",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
    }
    
    // Check multipleOf
    if let multipleOf = context.multipleOf {
        if intValue % multipleOf != 0 {
            addError(
                name: "multipleOf",
                message: "should be multiple of \(multipleOf)",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
    }
}

/// Validates a boolean value
private func validateBoolean(
    value: Any?,
    errors: inout [ValidationError],
    errorSchema: inout [String: Any]
) {
    // Nil check for required fields would be handled separately
    if value != nil && !(value is Bool) {
        addError(
            name: "type",
            message: "should be boolean",
            errors: &errors,
            errorSchema: &errorSchema
        )
    }
}

/// Validates an object value against schema constraints
private func validateObject(
    value: Any?,
    context: JSONSchema.ObjectSchema,
    errors: inout [ValidationError],
    errorSchema: inout [String: Any]
) {
    // Nil check for required fields would be handled separately
    guard let objectValue = value as? [String: Any] else {
        if value != nil {
            addError(
                name: "type",
                message: "should be object",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
        return
    }
    
    // Check required properties
    if let required = context.required {
        for prop in required {
            if objectValue[prop] == nil {
                addError(
                    name: "required",
                    message: "requires property \"\(prop)\"",
                    property: ".\(prop)",
                    errors: &errors,
                    errorSchema: &errorSchema
                )
            }
        }
    }
    
    // Check property dependencies
    if let dependencies = context.dependencies as? [String: [String]] {
        for (dependency, dependentProps) in dependencies {
            if objectValue[dependency] != nil {
                for prop in dependentProps {
                    if objectValue[prop] == nil {
                        addError(
                            name: "dependencies",
                            message: "property \"\(dependency)\" requires property \"\(prop)\"",
                            errors: &errors,
                            errorSchema: &errorSchema
                        )
                    }
                }
            }
        }
    }
    
    // Note: propertyNames, additionalProperties, etc. are not implemented in this example
}

/// Validates an array value against schema constraints
private func validateArray(
    value: Any?,
    context: JSONSchema.ArraySchema,
    errors: inout [ValidationError],
    errorSchema: inout [String: Any]
) {
    // Nil check for required fields would be handled separately
    guard let arrayValue = value as? [Any] else {
        if value != nil {
            addError(
                name: "type",
                message: "should be array",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
        return
    }
    
    // Check minItems
    if let minItems = context.minItems, arrayValue.count < minItems {
        addError(
            name: "minItems",
            message: "should NOT have fewer than \(minItems) items",
            errors: &errors,
            errorSchema: &errorSchema
        )
    }
    
    // Check maxItems
    if let maxItems = context.maxItems, arrayValue.count > maxItems {
        addError(
            name: "maxItems",
            message: "should NOT have more than \(maxItems) items",
            errors: &errors,
            errorSchema: &errorSchema
        )
    }
    
    // Check uniqueItems
    if let uniqueItems = context.uniqueItems, uniqueItems {
        // This is a simplified check; real implementation would need a more robust equality check
        var seenValues = Set<String>()
        var hasDuplicates = false
        
        for item in arrayValue {
            // Convert to string representation for comparison (not ideal but simple)
            let itemString = String(describing: item)
            if seenValues.contains(itemString) {
                hasDuplicates = true
                break
            }
            seenValues.insert(itemString)
        }
        
        if hasDuplicates {
            addError(
                name: "uniqueItems",
                message: "should NOT have duplicate items",
                errors: &errors,
                errorSchema: &errorSchema
            )
        }
    }
    
    // Note: items, contains, etc. are not implemented in this example
}

/// Helper function to add an error to both the errors array and errorSchema
private func addError(
    name: String,
    message: String,
    property: String = "",
    errors: inout [ValidationError],
    errorSchema: inout [String: Any]
) {
    let error = ValidationError(
        name: name,
        message: message,
        stack: message,
        property: property
    )
    
    errors.append(error)
    
    // Update the errorSchema
    var currentErrors = errorSchema["__errors"] as? [String] ?? []
    currentErrors.append(message)
    errorSchema["__errors"] = currentErrors
} 