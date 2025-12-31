import Testing
@testable import JSONSchemaValidator

@Suite("String Validator Tests")
struct StringValidatorTests {
    // MARK: - minLength Tests

    @Test("Valid string with minLength")
    func validStringWithMinLength() throws {
        try JSONSchemaValidator.validate("hello", schema: [
            "type": "string",
            "minLength": 3
        ])
    }

    @Test("Valid string exactly at minLength")
    func validStringExactlyAtMinLength() throws {
        try JSONSchemaValidator.validate("abc", schema: [
            "type": "string",
            "minLength": 3
        ])
    }

    @Test("Invalid string shorter than minLength")
    func invalidStringTooShort() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("ab", schema: [
                "type": "string",
                "minLength": 3
            ])
        }
    }

    // MARK: - maxLength Tests

    @Test("Valid string with maxLength")
    func validStringWithMaxLength() throws {
        try JSONSchemaValidator.validate("hi", schema: [
            "type": "string",
            "maxLength": 5
        ])
    }

    @Test("Valid string exactly at maxLength")
    func validStringExactlyAtMaxLength() throws {
        try JSONSchemaValidator.validate("hello", schema: [
            "type": "string",
            "maxLength": 5
        ])
    }

    @Test("Invalid string longer than maxLength")
    func invalidStringTooLong() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("hello world", schema: [
                "type": "string",
                "maxLength": 5
            ])
        }
    }

    // MARK: - pattern Tests

    @Test("Valid string matching pattern")
    func validStringMatchingPattern() throws {
        try JSONSchemaValidator.validate("abc123", schema: [
            "type": "string",
            "pattern": "^[a-z]+[0-9]+$"
        ])
    }

    @Test("Invalid string not matching pattern")
    func invalidStringNotMatchingPattern() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("123abc", schema: [
                "type": "string",
                "pattern": "^[a-z]+[0-9]+$"
            ])
        }
    }

    @Test("Valid string with email pattern")
    func validStringWithEmailPattern() throws {
        try JSONSchemaValidator.validate("test@example.com", schema: [
            "type": "string",
            "pattern": "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        ])
    }

    // MARK: - format Tests

    @Test("Valid email format")
    func validEmailFormat() throws {
        try JSONSchemaValidator.validate("user@example.com", schema: [
            "type": "string",
            "format": "email"
        ])
    }

    @Test("Invalid email format")
    func invalidEmailFormat() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("not-an-email", schema: [
                "type": "string",
                "format": "email"
            ])
        }
    }

    @Test("Valid URI format")
    func validURIFormat() throws {
        try JSONSchemaValidator.validate("https://example.com/path", schema: [
            "type": "string",
            "format": "uri"
        ])
    }

    @Test("Invalid URI format")
    func invalidURIFormat() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("not a uri", schema: [
                "type": "string",
                "format": "uri"
            ])
        }
    }

    // MARK: - Combined Constraints Tests

    @Test("Valid string with multiple constraints")
    func validStringWithMultipleConstraints() throws {
        try JSONSchemaValidator.validate("hello", schema: [
            "type": "string",
            "minLength": 3,
            "maxLength": 10,
            "pattern": "^[a-z]+$"
        ])
    }

    @Test("Invalid string failing minLength with multiple constraints")
    func invalidStringFailingMinLength() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("ab", schema: [
                "type": "string",
                "minLength": 3,
                "maxLength": 10,
                "pattern": "^[a-z]+$"
            ])
        }
    }
}
