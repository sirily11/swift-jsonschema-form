import Foundation
import Testing
@testable import JSONSchemaValidator

@Suite("Type Validator Tests")
struct TypeValidatorTests {
    // MARK: - String Type Tests

    @Test("Valid string type")
    func validStringType() throws {
        try JSONSchemaValidator.validate("hello", schema: ["type": "string"])
    }

    @Test("Invalid string type with number")
    func invalidStringTypeWithNumber() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(42, schema: ["type": "string"])
        }
    }

    @Test("Invalid string type with boolean")
    func invalidStringTypeWithBoolean() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(true, schema: ["type": "string"])
        }
    }

    // MARK: - Number Type Tests

    @Test("Valid number type with integer")
    func validNumberTypeWithInteger() throws {
        try JSONSchemaValidator.validate(42, schema: ["type": "number"])
    }

    @Test("Valid number type with double")
    func validNumberTypeWithDouble() throws {
        try JSONSchemaValidator.validate(42.5, schema: ["type": "number"])
    }

    @Test("Invalid number type with string")
    func invalidNumberTypeWithString() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("42", schema: ["type": "number"])
        }
    }

    // MARK: - Integer Type Tests

    @Test("Valid integer type")
    func validIntegerType() throws {
        try JSONSchemaValidator.validate(42, schema: ["type": "integer"])
    }

    @Test("Valid integer type with double that is whole number")
    func validIntegerTypeWithWholeDouble() throws {
        try JSONSchemaValidator.validate(42.0, schema: ["type": "integer"])
    }

    @Test("Invalid integer type with decimal")
    func invalidIntegerTypeWithDecimal() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(42.5, schema: ["type": "integer"])
        }
    }

    // MARK: - Boolean Type Tests

    @Test("Valid boolean type true")
    func validBooleanTypeTrue() throws {
        try JSONSchemaValidator.validate(true, schema: ["type": "boolean"])
    }

    @Test("Valid boolean type false")
    func validBooleanTypeFalse() throws {
        try JSONSchemaValidator.validate(false, schema: ["type": "boolean"])
    }

    @Test("Invalid boolean type with number")
    func invalidBooleanTypeWithNumber() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(1, schema: ["type": "boolean"])
        }
    }

    // MARK: - Null Type Tests

    @Test("Valid null type with nil")
    func validNullTypeWithNil() throws {
        try JSONSchemaValidator.validate(nil, schema: ["type": "null"])
    }

    @Test("Valid null type with NSNull")
    func validNullTypeWithNSNull() throws {
        try JSONSchemaValidator.validate(NSNull(), schema: ["type": "null"])
    }

    @Test("Invalid null type with value")
    func invalidNullTypeWithValue() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("null", schema: ["type": "null"])
        }
    }

    // MARK: - Object Type Tests

    @Test("Valid object type")
    func validObjectType() throws {
        try JSONSchemaValidator.validate(["key": "value"], schema: ["type": "object"])
    }

    @Test("Valid empty object type")
    func validEmptyObjectType() throws {
        let emptyDict: [String: Any] = [:]
        try JSONSchemaValidator.validate(emptyDict, schema: ["type": "object"])
    }

    @Test("Invalid object type with array")
    func invalidObjectTypeWithArray() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([1, 2, 3], schema: ["type": "object"])
        }
    }

    // MARK: - Array Type Tests

    @Test("Valid array type")
    func validArrayType() throws {
        try JSONSchemaValidator.validate([1, 2, 3], schema: ["type": "array"])
    }

    @Test("Valid empty array type")
    func validEmptyArrayType() throws {
        let emptyArray: [Any] = []
        try JSONSchemaValidator.validate(emptyArray, schema: ["type": "array"])
    }

    @Test("Invalid array type with object")
    func invalidArrayTypeWithObject() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(["key": "value"], schema: ["type": "array"])
        }
    }

    // MARK: - Type Array Tests

    @Test("Valid type array - string or null with string")
    func validTypeArrayStringOrNullWithString() throws {
        try JSONSchemaValidator.validate("hello", schema: ["type": ["string", "null"]])
    }

    @Test("Valid type array - string or null with null")
    func validTypeArrayStringOrNullWithNull() throws {
        try JSONSchemaValidator.validate(nil, schema: ["type": ["string", "null"]])
    }

    @Test("Invalid type array - string or null with number")
    func invalidTypeArrayStringOrNullWithNumber() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(42, schema: ["type": ["string", "null"]])
        }
    }
}
