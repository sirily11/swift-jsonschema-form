import Foundation
import Testing
@testable import JSONSchemaValidator

@Suite("Enum Validator Tests")
struct EnumValidatorTests {
    // MARK: - String Enum Tests

    @Test("Valid string enum value")
    func validStringEnumValue() throws {
        try JSONSchemaValidator.validate("red", schema: [
            "enum": ["red", "green", "blue"]
        ])
    }

    @Test("Valid string enum - all values")
    func validStringEnumAllValues() throws {
        for color in ["red", "green", "blue"] {
            try JSONSchemaValidator.validate(color, schema: [
                "enum": ["red", "green", "blue"]
            ])
        }
    }

    @Test("Invalid string enum value")
    func invalidStringEnumValue() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("yellow", schema: [
                "enum": ["red", "green", "blue"]
            ])
        }
    }

    // MARK: - Number Enum Tests

    @Test("Valid number enum value")
    func validNumberEnumValue() throws {
        try JSONSchemaValidator.validate(1, schema: [
            "enum": [1, 2, 3]
        ])
    }

    @Test("Invalid number enum value")
    func invalidNumberEnumValue() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(4, schema: [
                "enum": [1, 2, 3]
            ])
        }
    }

    // MARK: - Mixed Type Enum Tests

    @Test("Valid mixed type enum - string")
    func validMixedTypeEnumString() throws {
        try JSONSchemaValidator.validate("yes", schema: [
            "enum": ["yes", "no", 1, 0, true, false]
        ])
    }

    @Test("Valid mixed type enum - number")
    func validMixedTypeEnumNumber() throws {
        try JSONSchemaValidator.validate(1, schema: [
            "enum": ["yes", "no", 1, 0, true, false]
        ])
    }

    @Test("Valid mixed type enum - boolean")
    func validMixedTypeEnumBoolean() throws {
        try JSONSchemaValidator.validate(true, schema: [
            "enum": ["yes", "no", 1, 0, true, false]
        ])
    }

    // MARK: - Null Enum Tests

    @Test("Valid null in enum")
    func validNullInEnum() throws {
        try JSONSchemaValidator.validate(nil, schema: [
            "enum": ["value", NSNull()]
        ])
    }

    // MARK: - const Tests

    @Test("Valid const string value")
    func validConstStringValue() throws {
        try JSONSchemaValidator.validate("fixed", schema: [
            "const": "fixed"
        ])
    }

    @Test("Invalid const string value")
    func invalidConstStringValue() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("other", schema: [
                "const": "fixed"
            ])
        }
    }

    @Test("Valid const number value")
    func validConstNumberValue() throws {
        try JSONSchemaValidator.validate(42, schema: [
            "const": 42
        ])
    }

    @Test("Invalid const number value")
    func invalidConstNumberValue() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(43, schema: [
                "const": 42
            ])
        }
    }

    @Test("Valid const boolean value")
    func validConstBooleanValue() throws {
        try JSONSchemaValidator.validate(true, schema: [
            "const": true
        ])
    }

    @Test("Invalid const boolean value")
    func invalidConstBooleanValue() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(false, schema: [
                "const": true
            ])
        }
    }

    // MARK: - Enum with Type Tests

    @Test("Valid enum with type constraint")
    func validEnumWithTypeConstraint() throws {
        try JSONSchemaValidator.validate("active", schema: [
            "type": "string",
            "enum": ["active", "inactive", "pending"]
        ])
    }

    @Test("Invalid enum value with type constraint")
    func invalidEnumValueWithTypeConstraint() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("unknown", schema: [
                "type": "string",
                "enum": ["active", "inactive", "pending"]
            ])
        }
    }
}
