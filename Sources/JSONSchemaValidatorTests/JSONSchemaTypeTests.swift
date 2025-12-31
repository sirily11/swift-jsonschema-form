import Foundation
import Testing
import JSONSchema
@testable import JSONSchemaValidator

@Suite("JSONSchema Type Tests")
struct JSONSchemaTypeTests {
    // MARK: - Basic Type Tests

    @Test("Valid string with JSONSchema type")
    func validStringWithJSONSchemaType() throws {
        let schema = JSONSchema.string()
        try JSONSchemaValidator.validate("hello", schema: schema)
    }

    @Test("Invalid string type with JSONSchema type")
    func invalidStringTypeWithJSONSchemaType() throws {
        let schema = JSONSchema.string()
        do {
            try JSONSchemaValidator.validate(123, schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .typeMismatch(let expected, _, _) = errors[0] {
                #expect(expected == "string")
            }
        }
    }

    @Test("Valid number with JSONSchema type")
    func validNumberWithJSONSchemaType() throws {
        let schema = JSONSchema.number()
        try JSONSchemaValidator.validate(42.5, schema: schema)
    }

    @Test("Valid integer with JSONSchema type")
    func validIntegerWithJSONSchemaType() throws {
        let schema = JSONSchema.integer()
        try JSONSchemaValidator.validate(42, schema: schema)
    }

    @Test("Valid boolean with JSONSchema type")
    func validBooleanWithJSONSchemaType() throws {
        let schema = JSONSchema.boolean()
        try JSONSchemaValidator.validate(true, schema: schema)
    }

    @Test("Valid null with JSONSchema type")
    func validNullWithJSONSchemaType() throws {
        let schema = JSONSchema.null()
        try JSONSchemaValidator.validate(nil, schema: schema)
    }

    // MARK: - String Constraints Tests

    @Test("Valid string with minLength constraint")
    func validStringWithMinLength() throws {
        let schema = JSONSchema.string(minLength: 3)
        try JSONSchemaValidator.validate("hello", schema: schema)
    }

    @Test("Invalid string with minLength constraint")
    func invalidStringWithMinLength() throws {
        let schema = JSONSchema.string(minLength: 5)
        do {
            try JSONSchemaValidator.validate("hi", schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .stringTooShort(let minLength, let actualLength, _) = errors[0] {
                #expect(minLength == 5)
                #expect(actualLength == 2)
            }
        }
    }

    @Test("Valid string with maxLength constraint")
    func validStringWithMaxLength() throws {
        let schema = JSONSchema.string(maxLength: 10)
        try JSONSchemaValidator.validate("hello", schema: schema)
    }

    @Test("Invalid string with maxLength constraint")
    func invalidStringWithMaxLength() throws {
        let schema = JSONSchema.string(maxLength: 3)
        do {
            try JSONSchemaValidator.validate("hello", schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .stringTooLong(let maxLength, let actualLength, _) = errors[0] {
                #expect(maxLength == 3)
                #expect(actualLength == 5)
            }
        }
    }

    @Test("Valid string with pattern constraint")
    func validStringWithPattern() throws {
        let schema = JSONSchema.string(pattern: "^[a-z]+$")
        try JSONSchemaValidator.validate("hello", schema: schema)
    }

    @Test("Invalid string with pattern constraint")
    func invalidStringWithPattern() throws {
        let schema = JSONSchema.string(pattern: "^[a-z]+$")
        do {
            try JSONSchemaValidator.validate("Hello123", schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .patternMismatch(let pattern, _) = errors[0] {
                #expect(pattern == "^[a-z]+$")
            }
        }
    }

    @Test("Valid string with format constraint")
    func validStringWithFormat() throws {
        let schema = JSONSchema.string(format: "email")
        try JSONSchemaValidator.validate("test@example.com", schema: schema)
    }

    @Test("Invalid string with format constraint")
    func invalidStringWithFormat() throws {
        let schema = JSONSchema.string(format: "email")
        do {
            try JSONSchemaValidator.validate("not-an-email", schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .formatMismatch(let format, _, _) = errors[0] {
                #expect(format == "email")
            }
        }
    }

    // MARK: - Number Constraints Tests

    @Test("Valid number with minimum constraint")
    func validNumberWithMinimum() throws {
        let schema = JSONSchema.number(minimum: 0)
        try JSONSchemaValidator.validate(5.0, schema: schema)
    }

    @Test("Invalid number with minimum constraint")
    func invalidNumberWithMinimum() throws {
        let schema = JSONSchema.number(minimum: 10)
        do {
            try JSONSchemaValidator.validate(5.0, schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .numberTooSmall(let minimum, let actual, _, _) = errors[0] {
                #expect(minimum == 10)
                #expect(actual == 5.0)
            }
        }
    }

    @Test("Valid number with maximum constraint")
    func validNumberWithMaximum() throws {
        let schema = JSONSchema.number(maximum: 100)
        try JSONSchemaValidator.validate(50.0, schema: schema)
    }

    @Test("Invalid number with maximum constraint")
    func invalidNumberWithMaximum() throws {
        let schema = JSONSchema.number(maximum: 10)
        do {
            try JSONSchemaValidator.validate(50.0, schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .numberTooLarge(let maximum, let actual, _, _) = errors[0] {
                #expect(maximum == 10)
                #expect(actual == 50.0)
            }
        }
    }

    @Test("Valid number with exclusiveMinimum constraint")
    func validNumberWithExclusiveMinimum() throws {
        let schema = JSONSchema.number(exclusiveMinimum: 5)
        try JSONSchemaValidator.validate(6.0, schema: schema)
    }

    @Test("Invalid number with exclusiveMinimum constraint - equal to minimum")
    func invalidNumberWithExclusiveMinimumEqual() throws {
        let schema = JSONSchema.number(exclusiveMinimum: 5)
        do {
            try JSONSchemaValidator.validate(5.0, schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
        }
    }

    @Test("Valid number with exclusiveMaximum constraint")
    func validNumberWithExclusiveMaximum() throws {
        let schema = JSONSchema.number(exclusiveMaximum: 10)
        try JSONSchemaValidator.validate(9.0, schema: schema)
    }

    @Test("Invalid number with exclusiveMaximum constraint - equal to maximum")
    func invalidNumberWithExclusiveMaximumEqual() throws {
        let schema = JSONSchema.number(exclusiveMaximum: 10)
        do {
            try JSONSchemaValidator.validate(10.0, schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
        }
    }

    @Test("Valid number with multipleOf constraint")
    func validNumberWithMultipleOf() throws {
        let schema = JSONSchema.number(multipleOf: 5)
        try JSONSchemaValidator.validate(15.0, schema: schema)
    }

    @Test("Invalid number with multipleOf constraint")
    func invalidNumberWithMultipleOf() throws {
        let schema = JSONSchema.number(multipleOf: 5)
        do {
            try JSONSchemaValidator.validate(7.0, schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .notMultipleOf(let multipleOf, let actual, _) = errors[0] {
                #expect(multipleOf == 5)
                #expect(actual == 7.0)
            }
        }
    }

    // MARK: - Integer Constraints Tests

    @Test("Valid integer with minimum constraint")
    func validIntegerWithMinimum() throws {
        let schema = JSONSchema.integer(minimum: 0)
        try JSONSchemaValidator.validate(5, schema: schema)
    }

    @Test("Invalid integer with minimum constraint")
    func invalidIntegerWithMinimum() throws {
        let schema = JSONSchema.integer(minimum: 10)
        do {
            try JSONSchemaValidator.validate(5, schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
        }
    }

    // MARK: - Object Tests

    @Test("Valid object with JSONSchema type")
    func validObjectWithJSONSchemaType() throws {
        let schema = JSONSchema.object(
            properties: [
                "name": JSONSchema.string(),
                "age": JSONSchema.integer()
            ],
            required: ["name"]
        )
        try JSONSchemaValidator.validate([
            "name": "John",
            "age": 30
        ], schema: schema)
    }

    @Test("Invalid object - missing required property")
    func invalidObjectMissingRequired() throws {
        let schema = JSONSchema.object(
            properties: [
                "name": JSONSchema.string(),
                "age": JSONSchema.integer()
            ],
            required: ["name", "age"]
        )
        do {
            try JSONSchemaValidator.validate([
                "name": "John"
            ], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .requiredPropertyMissing(let property, _) = errors[0] {
                #expect(property == "age")
            }
        }
    }

    @Test("Invalid object - wrong property type")
    func invalidObjectWrongPropertyType() throws {
        let schema = JSONSchema.object(
            properties: [
                "name": JSONSchema.string(),
                "age": JSONSchema.integer()
            ]
        )
        do {
            try JSONSchemaValidator.validate([
                "name": "John",
                "age": "thirty"  // Should be integer
            ], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .typeMismatch(let expected, _, let path) = errors[0] {
                #expect(expected == "integer")
                #expect(path == "age")
            }
        }
    }

    @Test("Valid object with minProperties constraint")
    func validObjectWithMinProperties() throws {
        let schema = JSONSchema.object(minProperties: 2)
        try JSONSchemaValidator.validate([
            "a": 1,
            "b": 2
        ], schema: schema)
    }

    @Test("Invalid object with minProperties constraint")
    func invalidObjectWithMinProperties() throws {
        let schema = JSONSchema.object(minProperties: 3)
        do {
            try JSONSchemaValidator.validate([
                "a": 1,
                "b": 2
            ], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .tooFewProperties(let minProperties, let actual, _) = errors[0] {
                #expect(minProperties == 3)
                #expect(actual == 2)
            }
        }
    }

    @Test("Valid object with maxProperties constraint")
    func validObjectWithMaxProperties() throws {
        let schema = JSONSchema.object(maxProperties: 3)
        try JSONSchemaValidator.validate([
            "a": 1,
            "b": 2
        ], schema: schema)
    }

    @Test("Invalid object with maxProperties constraint")
    func invalidObjectWithMaxProperties() throws {
        let schema = JSONSchema.object(maxProperties: 1)
        do {
            try JSONSchemaValidator.validate([
                "a": 1,
                "b": 2
            ], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .tooManyProperties(let maxProperties, let actual, _) = errors[0] {
                #expect(maxProperties == 1)
                #expect(actual == 2)
            }
        }
    }

    @Test("Valid object with additionalProperties false")
    func validObjectWithAdditionalPropertiesFalse() throws {
        let schema = JSONSchema.object(
            properties: [
                "name": JSONSchema.string()
            ],
            additionalProperties: .boolean(false)
        )
        try JSONSchemaValidator.validate([
            "name": "John"
        ], schema: schema)
    }

    @Test("Invalid object with additionalProperties false")
    func invalidObjectWithAdditionalPropertiesFalse() throws {
        let schema = JSONSchema.object(
            properties: [
                "name": JSONSchema.string()
            ],
            additionalProperties: .boolean(false)
        )
        do {
            try JSONSchemaValidator.validate([
                "name": "John",
                "extra": "not allowed"
            ], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .additionalPropertyNotAllowed(let property, _) = errors[0] {
                #expect(property == "extra")
            }
        }
    }

    // MARK: - Array Tests

    @Test("Valid array with JSONSchema type")
    func validArrayWithJSONSchemaType() throws {
        let schema = JSONSchema.array(items: JSONSchema.string())
        try JSONSchemaValidator.validate(["a", "b", "c"], schema: schema)
    }

    @Test("Invalid array - wrong item type")
    func invalidArrayWrongItemType() throws {
        let schema = JSONSchema.array(items: JSONSchema.string())
        do {
            try JSONSchemaValidator.validate(["a", 1, "c"], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .typeMismatch(let expected, _, let path) = errors[0] {
                #expect(expected == "string")
                #expect(path == "[1]")
            }
        }
    }

    @Test("Valid array with minItems constraint")
    func validArrayWithMinItems() throws {
        let schema = JSONSchema.array(minItems: 2)
        try JSONSchemaValidator.validate([1, 2, 3], schema: schema)
    }

    @Test("Invalid array with minItems constraint")
    func invalidArrayWithMinItems() throws {
        let schema = JSONSchema.array(minItems: 3)
        do {
            try JSONSchemaValidator.validate([1, 2], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .tooFewItems(let minItems, let actual, _) = errors[0] {
                #expect(minItems == 3)
                #expect(actual == 2)
            }
        }
    }

    @Test("Valid array with maxItems constraint")
    func validArrayWithMaxItems() throws {
        let schema = JSONSchema.array(maxItems: 5)
        try JSONSchemaValidator.validate([1, 2, 3], schema: schema)
    }

    @Test("Invalid array with maxItems constraint")
    func invalidArrayWithMaxItems() throws {
        let schema = JSONSchema.array(maxItems: 2)
        do {
            try JSONSchemaValidator.validate([1, 2, 3], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .tooManyItems(let maxItems, let actual, _) = errors[0] {
                #expect(maxItems == 2)
                #expect(actual == 3)
            }
        }
    }

    @Test("Valid array with uniqueItems constraint")
    func validArrayWithUniqueItems() throws {
        let schema = JSONSchema.array(uniqueItems: true)
        try JSONSchemaValidator.validate([1, 2, 3], schema: schema)
    }

    @Test("Invalid array with uniqueItems constraint")
    func invalidArrayWithUniqueItems() throws {
        let schema = JSONSchema.array(uniqueItems: true)
        do {
            try JSONSchemaValidator.validate([1, 2, 2], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .duplicateItems(_) = errors[0] {
                // Expected
            } else {
                Issue.record("Expected duplicateItems error")
            }
        }
    }

    // MARK: - Enum Tests

    @Test("Valid enum with JSONSchema type")
    func validEnumWithJSONSchemaType() throws {
        let schema = JSONSchema.enum(values: [
            .string("red"),
            .string("green"),
            .string("blue")
        ])
        try JSONSchemaValidator.validate("red", schema: schema)
    }

    @Test("Invalid enum value")
    func invalidEnumValue() throws {
        let schema = JSONSchema.enum(values: [
            .string("red"),
            .string("green"),
            .string("blue")
        ])
        do {
            try JSONSchemaValidator.validate("yellow", schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .notInEnum(_, _) = errors[0] {
                // Expected
            } else {
                Issue.record("Expected notInEnum error")
            }
        }
    }

    @Test("Valid enum with mixed types")
    func validEnumWithMixedTypes() throws {
        let schema = JSONSchema.enum(values: [
            .string("auto"),
            .integer(0),
            .integer(1)
        ])
        try JSONSchemaValidator.validate("auto", schema: schema)
        try JSONSchemaValidator.validate(0, schema: schema)
        try JSONSchemaValidator.validate(1, schema: schema)
    }

    // MARK: - Combined Schema Tests (oneOf, anyOf, allOf)

    @Test("Valid oneOf with JSONSchema type")
    func validOneOfWithJSONSchemaType() throws {
        let schema = JSONSchema.oneOf(schemas: [
            JSONSchema.string(),
            JSONSchema.integer()
        ])
        try JSONSchemaValidator.validate("hello", schema: schema)
        try JSONSchemaValidator.validate(42, schema: schema)
    }

    @Test("Invalid oneOf - no match")
    func invalidOneOfNoMatch() throws {
        let schema = JSONSchema.oneOf(schemas: [
            JSONSchema.string(minLength: 5),
            JSONSchema.integer(minimum: 10)
        ])
        do {
            try JSONSchemaValidator.validate(5, schema: schema)  // Integer but below minimum
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .oneOfFailed(let matchCount, _) = errors[0] {
                #expect(matchCount == 0)
            }
        }
    }

    @Test("Valid anyOf with JSONSchema type")
    func validAnyOfWithJSONSchemaType() throws {
        let schema = JSONSchema.anyOf(schemas: [
            JSONSchema.string(),
            JSONSchema.integer()
        ])
        try JSONSchemaValidator.validate("hello", schema: schema)
    }

    @Test("Invalid anyOf - no match")
    func invalidAnyOfNoMatch() throws {
        let schema = JSONSchema.anyOf(schemas: [
            JSONSchema.string(),
            JSONSchema.integer()
        ])
        do {
            try JSONSchemaValidator.validate(true, schema: schema)  // Boolean doesn't match
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .anyOfFailed(_) = errors[0] {
                // Expected
            } else {
                Issue.record("Expected anyOfFailed error")
            }
        }
    }

    @Test("Valid allOf with JSONSchema type")
    func validAllOfWithJSONSchemaType() throws {
        let schema = JSONSchema.allOf(schemas: [
            JSONSchema.string(),
            JSONSchema.string(minLength: 3)
        ])
        try JSONSchemaValidator.validate("hello", schema: schema)
    }

    @Test("Invalid allOf - one schema fails")
    func invalidAllOfOneSchemaFails() throws {
        let schema = JSONSchema.allOf(schemas: [
            JSONSchema.string(),
            JSONSchema.string(minLength: 10)
        ])
        do {
            try JSONSchemaValidator.validate("hi", schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count >= 1)
        }
    }

    // MARK: - Complex Nested Schema Tests

    @Test("Complex nested object schema")
    func complexNestedObjectSchema() throws {
        let addressSchema = JSONSchema.object(
            properties: [
                "street": JSONSchema.string(),
                "city": JSONSchema.string(),
                "zipCode": JSONSchema.string(pattern: "^[0-9]{5}$")
            ],
            required: ["street", "city"]
        )

        let userSchema = JSONSchema.object(
            properties: [
                "name": JSONSchema.string(minLength: 1),
                "age": JSONSchema.integer(minimum: 0, maximum: 150),
                "email": JSONSchema.string(format: "email"),
                "address": addressSchema,
                "tags": JSONSchema.array(items: JSONSchema.string(), uniqueItems: true)
            ],
            required: ["name", "email"]
        )

        try JSONSchemaValidator.validate([
            "name": "John Doe",
            "age": 30,
            "email": "john@example.com",
            "address": [
                "street": "123 Main St",
                "city": "New York",
                "zipCode": "10001"
            ],
            "tags": ["developer", "swift"]
        ], schema: userSchema)
    }

    @Test("Complex nested object schema - invalid")
    func complexNestedObjectSchemaInvalid() throws {
        let userSchema = JSONSchema.object(
            properties: [
                "name": JSONSchema.string(minLength: 1),
                "age": JSONSchema.integer(minimum: 0, maximum: 150),
                "email": JSONSchema.string(format: "email")
            ],
            required: ["name", "email"]
        )

        do {
            try JSONSchemaValidator.validate([
                "name": "",  // Too short
                "age": 200,  // Too large
                "email": "not-an-email"  // Invalid format
            ], schema: userSchema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count >= 2)  // Multiple errors
        }
    }

    // MARK: - Static vs Instance Method Tests

    @Test("Static validate method with JSONSchema")
    func staticValidateMethodWithJSONSchema() throws {
        let schema = JSONSchema.string()
        try JSONSchemaValidator.validate("hello", schema: schema)
    }

    @Test("Instance validate method with JSONSchema")
    func instanceValidateMethodWithJSONSchema() throws {
        let validator = JSONSchemaValidator()
        let schema = JSONSchema.string()
        try validator.validate("hello", schema: schema)
    }

    @Test("Shared instance validate method with JSONSchema")
    func sharedInstanceValidateMethodWithJSONSchema() throws {
        let schema = JSONSchema.string()
        try JSONSchemaValidator.shared.validate("hello", schema: schema)
    }

    // MARK: - Edge Cases for Basic Types

    @Test("Empty string is valid string")
    func emptyStringIsValid() throws {
        let schema = JSONSchema.string()
        try JSONSchemaValidator.validate("", schema: schema)
    }

    @Test("Boolean false is not null")
    func booleanFalseIsNotNull() throws {
        let schema = JSONSchema.boolean()
        try JSONSchemaValidator.validate(false, schema: schema)
    }

    @Test("Boolean false fails null schema")
    func booleanFalseFailsNullSchema() throws {
        let schema = JSONSchema.null()
        do {
            try JSONSchemaValidator.validate(false, schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .typeMismatch(let expected, let actual, _) = errors[0] {
                #expect(expected == "null")
                #expect(actual == "boolean")
            }
        }
    }

    @Test("Zero is valid number")
    func zeroIsValidNumber() throws {
        let schema = JSONSchema.number()
        try JSONSchemaValidator.validate(0, schema: schema)
        try JSONSchemaValidator.validate(0.0, schema: schema)
    }

    @Test("Negative number is valid")
    func negativeNumberIsValid() throws {
        let schema = JSONSchema.number()
        try JSONSchemaValidator.validate(-42.5, schema: schema)
    }

    @Test("Negative integer is valid")
    func negativeIntegerIsValid() throws {
        let schema = JSONSchema.integer()
        try JSONSchemaValidator.validate(-100, schema: schema)
    }

    @Test("Nil data fails non-null schema")
    func nilDataFailsNonNullSchema() throws {
        let schema = JSONSchema.string()
        do {
            try JSONSchemaValidator.validate(nil, schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .typeMismatch(let expected, let actual, _) = errors[0] {
                #expect(expected == "string")
                #expect(actual == "null")
            }
        }
    }

    // MARK: - Array Features - prefixItems (Tuple Validation)

    @Test("Valid array with prefixItems")
    func validArrayWithPrefixItems() throws {
        let schema = JSONSchema.array(
            prefixItems: [JSONSchema.string(), JSONSchema.integer()]
        )
        try JSONSchemaValidator.validate(["hello", 42], schema: schema)
    }

    @Test("Invalid array with prefixItems - wrong type")
    func invalidArrayWithPrefixItemsWrongType() throws {
        let schema = JSONSchema.array(
            prefixItems: [JSONSchema.string(), JSONSchema.integer()]
        )
        do {
            try JSONSchemaValidator.validate(["hello", "world"], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .typeMismatch(let expected, _, let path) = errors[0] {
                #expect(expected == "integer")
                #expect(path == "[1]")
            }
        }
    }

    @Test("Array shorter than prefixItems is valid")
    func arrayShorterThanPrefixItemsIsValid() throws {
        let schema = JSONSchema.array(
            prefixItems: [JSONSchema.string(), JSONSchema.integer(), JSONSchema.boolean()]
        )
        try JSONSchemaValidator.validate(["hello"], schema: schema)
    }

    @Test("Nested array validation")
    func nestedArrayValidation() throws {
        let schema = JSONSchema.array(
            items: JSONSchema.array(items: JSONSchema.string())
        )
        try JSONSchemaValidator.validate([["a", "b"], ["c", "d"]], schema: schema)
    }

    @Test("Invalid nested array - wrong inner item type")
    func invalidNestedArrayWrongInnerItemType() throws {
        let schema = JSONSchema.array(
            items: JSONSchema.array(items: JSONSchema.string())
        )
        do {
            try JSONSchemaValidator.validate([["a", 1], ["c", "d"]], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .typeMismatch(let expected, _, let path) = errors[0] {
                #expect(expected == "string")
                #expect(path == "[0][1]")
            }
        }
    }

    @Test("Empty array is valid")
    func emptyArrayIsValid() throws {
        let schema = JSONSchema.array(items: JSONSchema.string())
        try JSONSchemaValidator.validate([] as [Any], schema: schema)
    }

    // MARK: - Object Features - patternProperties

    @Test("Valid object with patternProperties")
    func validObjectWithPatternProperties() throws {
        let schema = JSONSchema.object(
            patternProperties: ["^x-": JSONSchema.string()]
        )
        try JSONSchemaValidator.validate(["x-custom": "value"], schema: schema)
    }

    @Test("Invalid object with patternProperties")
    func invalidObjectWithPatternProperties() throws {
        let schema = JSONSchema.object(
            patternProperties: ["^x-": JSONSchema.string()]
        )
        do {
            try JSONSchemaValidator.validate(["x-custom": 123], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .typeMismatch(let expected, _, let path) = errors[0] {
                #expect(expected == "string")
                #expect(path == "x-custom")
            }
        }
    }

    @Test("Empty object is valid")
    func emptyObjectIsValid() throws {
        let schema = JSONSchema.object()
        try JSONSchemaValidator.validate([:] as [String: Any], schema: schema)
    }

    @Test("Object with null property value")
    func objectWithNullPropertyValue() throws {
        let schema = JSONSchema.object(
            properties: ["name": JSONSchema.null()]
        )
        try JSONSchemaValidator.validate(["name": NSNull()], schema: schema)
    }

    // MARK: - Enum Edge Cases

    @Test("Enum with null value")
    func enumWithNullValue() throws {
        let schema = JSONSchema.enum(values: [
            .string("active"),
            .null
        ])
        try JSONSchemaValidator.validate(nil, schema: schema)
        try JSONSchemaValidator.validate("active", schema: schema)
    }

    @Test("Enum with boolean values")
    func enumWithBooleanValues() throws {
        let schema = JSONSchema.enum(values: [
            .boolean(true),
            .boolean(false)
        ])
        try JSONSchemaValidator.validate(true, schema: schema)
        try JSONSchemaValidator.validate(false, schema: schema)
    }

    @Test("Invalid enum with boolean - wrong value type")
    func invalidEnumWithBooleanWrongValueType() throws {
        let schema = JSONSchema.enum(values: [
            .boolean(true),
            .boolean(false)
        ])
        do {
            try JSONSchemaValidator.validate("true", schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .notInEnum(_, _) = errors[0] {
                // Expected
            } else {
                Issue.record("Expected notInEnum error")
            }
        }
    }

    @Test("Enum with number values")
    func enumWithNumberValues() throws {
        let schema = JSONSchema.enum(values: [
            .number(1.5),
            .number(2.5)
        ])
        try JSONSchemaValidator.validate(1.5, schema: schema)
        try JSONSchemaValidator.validate(2.5, schema: schema)
    }

    // MARK: - Combined Schema Edge Cases

    @Test("Invalid oneOf - multiple matches")
    func invalidOneOfMultipleMatches() throws {
        let schema = JSONSchema.oneOf(schemas: [
            JSONSchema.string(),
            JSONSchema.string(minLength: 1)
        ])
        do {
            try JSONSchemaValidator.validate("hello", schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .oneOfFailed(let matchCount, _) = errors[0] {
                #expect(matchCount == 2)
            }
        }
    }

    @Test("Nested combinators - oneOf containing allOf")
    func nestedCombinatorsOneOfContainingAllOf() throws {
        let schema = JSONSchema.oneOf(schemas: [
            JSONSchema.allOf(schemas: [
                JSONSchema.string(),
                JSONSchema.string(minLength: 5)
            ]),
            JSONSchema.integer()
        ])
        try JSONSchemaValidator.validate("hello", schema: schema)
        try JSONSchemaValidator.validate(42, schema: schema)
    }

    @Test("allOf with object merge")
    func allOfWithObjectMerge() throws {
        let schema = JSONSchema.allOf(schemas: [
            JSONSchema.object(required: ["a"]),
            JSONSchema.object(required: ["b"])
        ])
        try JSONSchemaValidator.validate(["a": 1, "b": 2], schema: schema)
    }

    @Test("allOf with object merge - missing required from second schema")
    func allOfWithObjectMergeMissingRequired() throws {
        let schema = JSONSchema.allOf(schemas: [
            JSONSchema.object(required: ["a"]),
            JSONSchema.object(required: ["b"])
        ])
        do {
            try JSONSchemaValidator.validate(["a": 1], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count >= 1)
        }
    }

    // MARK: - Deep Error Path Verification

    @Test("Deep nested error path - object > array > object")
    func deepNestedErrorPath() throws {
        let userSchema = JSONSchema.object(
            properties: ["email": JSONSchema.string()]
        )
        let schema = JSONSchema.object(
            properties: [
                "users": JSONSchema.array(items: userSchema)
            ]
        )
        do {
            try JSONSchemaValidator.validate([
                "users": [
                    ["email": 123]
                ]
            ], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .typeMismatch(let expected, _, let path) = errors[0] {
                #expect(expected == "string")
                #expect(path == "users[0]/email")
            }
        }
    }

    @Test("Multiple nested errors")
    func multipleNestedErrors() throws {
        let schema = JSONSchema.object(
            properties: [
                "name": JSONSchema.string(minLength: 1),
                "age": JSONSchema.integer(minimum: 0),
                "email": JSONSchema.string(format: "email")
            ],
            required: ["name", "age", "email"]
        )
        do {
            try JSONSchemaValidator.validate([
                "name": "",
                "age": -5,
                "email": "not-an-email"
            ], schema: schema)
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            // Should have multiple validation errors
            #expect(errors.count >= 2)
        }
    }
}
