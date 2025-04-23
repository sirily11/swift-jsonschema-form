import XCTest
import JSONSchema
@testable import JSONSchemaForm

final class JSONSchemaFormTests: XCTestCase {
    func testBasicJSONSchemaForm() {
        // Create a simple schema for testing
        let schema: JSONSchema = .object(
            properties: [
                "name": .string(minLength: 3),
                "age": .integer(minimum: 18),
                "email": .string(format: "email")
            ],
            required: ["name", "age"]
        )
        
        // Create sample form data
        let formData: [String: Any] = [
            "name": "John Doe",
            "age": 25,
            "email": "john@example.com"
        ]
        
        // Test validation with valid data
        let validResult = validateFormData(formData: formData, schema: schema)
        XCTAssertTrue(validResult.errors.isEmpty, "Valid data should not produce validation errors")
        
        // Test validation with invalid data
        var invalidData: [String: Any] = [
            "name": "Jo", // Too short (min 3)
            "age": 16,    // Too young (min 18)
            "email": "not-an-email" // Invalid email format
        ]
        
        let invalidResult = validateFormData(formData: invalidData, schema: schema)
        XCTAssertFalse(invalidResult.errors.isEmpty, "Invalid data should produce validation errors")
        XCTAssertGreaterThanOrEqual(invalidResult.errors.count, 3, "Should have at least 3 validation errors")
        
        // Test missing required field
        invalidData = [
            "email": "valid@example.com" // Missing required name and age
        ]
        
        let missingFieldResult = validateFormData(formData: invalidData, schema: schema)
        XCTAssertFalse(missingFieldResult.errors.isEmpty, "Missing required fields should produce validation errors")
        
        // Test custom validation
        let customValidate: (Any?, inout [String: Any]) -> Void = { formData, errorSchema in
            guard let data = formData as? [String: Any],
                  let age = data["age"] as? Int,
                  let name = data["name"] as? String else {
                return
            }
            
            // Custom validation: name must contain a space
            if !name.contains(" ") {
                if errorSchema["name"] == nil {
                    errorSchema["name"] = ["__errors": ["Name must contain a space"]]
                } else if var nameErrors = errorSchema["name"] as? [String: Any] {
                    if nameErrors["__errors"] == nil {
                        nameErrors["__errors"] = ["Name must contain a space"]
                    } else if var errors = nameErrors["__errors"] as? [String] {
                        errors.append("Name must contain a space")
                        nameErrors["__errors"] = errors
                    }
                    errorSchema["name"] = nameErrors
                }
            }
            
            // Custom validation: age must be even
            if age % 2 != 0 {
                if errorSchema["age"] == nil {
                    errorSchema["age"] = ["__errors": ["Age must be even"]]
                } else if var ageErrors = errorSchema["age"] as? [String: Any] {
                    if ageErrors["__errors"] == nil {
                        ageErrors["__errors"] = ["Age must be even"]
                    } else if var errors = ageErrors["__errors"] as? [String] {
                        errors.append("Age must be even")
                        ageErrors["__errors"] = errors
                    }
                    errorSchema["age"] = ageErrors
                }
            }
        }
        
        // Valid data but fails custom validation (age is odd)
        let customInvalidData: [String: Any] = [
            "name": "John Doe",
            "age": 25, // Odd number
            "email": "john@example.com"
        ]
        
        let customValidationResult = validateFormData(
            formData: customInvalidData,
            schema: schema,
            customValidate: customValidate
        )
        
        XCTAssertFalse(customValidationResult.errors.isEmpty, "Custom validation should produce errors")
        
        // Test with another invalid case for custom validation
        let customInvalidData2: [String: Any] = [
            "name": "JohnDoe", // No space
            "age": 26, // Even number
            "email": "john@example.com"
        ]
        
        let customValidationResult2 = validateFormData(
            formData: customInvalidData2,
            schema: schema,
            customValidate: customValidate
        )
        
        XCTAssertFalse(customValidationResult2.errors.isEmpty, "Custom validation should produce errors")
    }
}
