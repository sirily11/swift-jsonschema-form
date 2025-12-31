import Testing
@testable import JSONSchemaValidator

@Suite("Number Validator Tests")
struct NumberValidatorTests {
    // MARK: - minimum Tests

    @Test("Valid number at minimum")
    func validNumberAtMinimum() throws {
        try JSONSchemaValidator.validate(5, schema: [
            "type": "number",
            "minimum": 5
        ])
    }

    @Test("Valid number above minimum")
    func validNumberAboveMinimum() throws {
        try JSONSchemaValidator.validate(10, schema: [
            "type": "number",
            "minimum": 5
        ])
    }

    @Test("Invalid number below minimum")
    func invalidNumberBelowMinimum() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(3, schema: [
                "type": "number",
                "minimum": 5
            ])
        }
    }

    // MARK: - exclusiveMinimum Tests

    @Test("Valid number above exclusiveMinimum")
    func validNumberAboveExclusiveMinimum() throws {
        try JSONSchemaValidator.validate(6, schema: [
            "type": "number",
            "exclusiveMinimum": 5
        ])
    }

    @Test("Invalid number at exclusiveMinimum")
    func invalidNumberAtExclusiveMinimum() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(5, schema: [
                "type": "number",
                "exclusiveMinimum": 5
            ])
        }
    }

    // MARK: - maximum Tests

    @Test("Valid number at maximum")
    func validNumberAtMaximum() throws {
        try JSONSchemaValidator.validate(100, schema: [
            "type": "number",
            "maximum": 100
        ])
    }

    @Test("Valid number below maximum")
    func validNumberBelowMaximum() throws {
        try JSONSchemaValidator.validate(50, schema: [
            "type": "number",
            "maximum": 100
        ])
    }

    @Test("Invalid number above maximum")
    func invalidNumberAboveMaximum() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(101, schema: [
                "type": "number",
                "maximum": 100
            ])
        }
    }

    // MARK: - exclusiveMaximum Tests

    @Test("Valid number below exclusiveMaximum")
    func validNumberBelowExclusiveMaximum() throws {
        try JSONSchemaValidator.validate(99, schema: [
            "type": "number",
            "exclusiveMaximum": 100
        ])
    }

    @Test("Invalid number at exclusiveMaximum")
    func invalidNumberAtExclusiveMaximum() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(100, schema: [
                "type": "number",
                "exclusiveMaximum": 100
            ])
        }
    }

    // MARK: - multipleOf Tests

    @Test("Valid number multiple of value")
    func validNumberMultipleOf() throws {
        try JSONSchemaValidator.validate(10, schema: [
            "type": "number",
            "multipleOf": 5
        ])
    }

    @Test("Valid number multiple of decimal")
    func validNumberMultipleOfDecimal() throws {
        try JSONSchemaValidator.validate(2.5, schema: [
            "type": "number",
            "multipleOf": 0.5
        ])
    }

    @Test("Invalid number not multiple of value")
    func invalidNumberNotMultipleOf() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(7, schema: [
                "type": "number",
                "multipleOf": 5
            ])
        }
    }

    // MARK: - Integer Type Tests

    @Test("Valid integer")
    func validInteger() throws {
        try JSONSchemaValidator.validate(42, schema: [
            "type": "integer",
            "minimum": 0,
            "maximum": 100
        ])
    }

    @Test("Invalid decimal for integer type")
    func invalidDecimalForInteger() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(42.5, schema: [
                "type": "integer"
            ])
        }
    }

    // MARK: - Combined Constraints Tests

    @Test("Valid number with range constraints")
    func validNumberWithRangeConstraints() throws {
        try JSONSchemaValidator.validate(50, schema: [
            "type": "number",
            "minimum": 0,
            "maximum": 100,
            "multipleOf": 10
        ])
    }

    @Test("Invalid number outside range")
    func invalidNumberOutsideRange() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(-10, schema: [
                "type": "number",
                "minimum": 0,
                "maximum": 100
            ])
        }
    }
}
