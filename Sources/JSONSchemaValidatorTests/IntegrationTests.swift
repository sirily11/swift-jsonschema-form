import Foundation
import Testing
@testable import JSONSchemaValidator

@Suite("Integration Tests")
struct IntegrationTests {
    // MARK: - Complex Schema Tests

    @Test("Valid complex user schema")
    func validComplexUserSchema() throws {
        try JSONSchemaValidator.validate([
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com",
            "age": 30,
            "address": [
                "street": "123 Main St",
                "city": "New York",
                "zipCode": "10001"
            ],
            "tags": ["developer", "swift"]
        ], schema: [
            "type": "object",
            "properties": [
                "id": ["type": "integer", "minimum": 1],
                "name": ["type": "string", "minLength": 1],
                "email": ["type": "string", "format": "email"],
                "age": ["type": "integer", "minimum": 0, "maximum": 150],
                "address": [
                    "type": "object",
                    "properties": [
                        "street": ["type": "string"],
                        "city": ["type": "string"],
                        "zipCode": ["type": "string", "pattern": "^[0-9]{5}$"]
                    ],
                    "required": ["street", "city"]
                ],
                "tags": [
                    "type": "array",
                    "items": ["type": "string"],
                    "uniqueItems": true
                ]
            ],
            "required": ["id", "name", "email"]
        ])
    }

    @Test("Invalid complex schema - multiple errors")
    func invalidComplexSchemaMultipleErrors() throws {
        do {
            try JSONSchemaValidator.validate([
                "id": -1,  // Invalid: below minimum
                "name": "",  // Invalid: below minLength
                "email": "not-an-email",  // Invalid: not email format
                "age": 200  // Invalid: above maximum
            ], schema: [
                "type": "object",
                "properties": [
                    "id": ["type": "integer", "minimum": 1],
                    "name": ["type": "string", "minLength": 1],
                    "email": ["type": "string", "format": "email"],
                    "age": ["type": "integer", "minimum": 0, "maximum": 150]
                ],
                "required": ["id", "name", "email"]
            ])
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count >= 3)
        }
    }

    // MARK: - API Style Tests (like kylef)

    @Test("kylef-style API usage")
    func kylefStyleAPIUsage() throws {
        try JSONSchemaValidator.validate(["name": "Eggs", "price": 34.99], schema: [
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "price": ["type": "number"]
            ],
            "required": ["name"]
        ])
    }

    @Test("Static validate method")
    func staticValidateMethod() throws {
        try JSONSchemaValidator.validate("hello", schema: ["type": "string"])
    }

    @Test("Instance validate method")
    func instanceValidateMethod() throws {
        let validator = JSONSchemaValidator()
        try validator.validate("hello", schema: ["type": "string"])
    }

    @Test("Shared instance validate method")
    func sharedInstanceValidateMethod() throws {
        try JSONSchemaValidator.shared.validate("hello", schema: ["type": "string"])
    }

    // MARK: - Error Path Tests

    @Test("Error path for nested property")
    func errorPathForNestedProperty() throws {
        do {
            try JSONSchemaValidator.validate([
                "user": [
                    "name": 123  // Should be string
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "user": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string"]
                        ]
                    ]
                ]
            ])
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .typeMismatch(_, _, let path) = errors[0] {
                #expect(path == "user/name")
            } else {
                Issue.record("Expected typeMismatch error")
            }
        }
    }

    @Test("Error path for array item")
    func errorPathForArrayItem() throws {
        do {
            try JSONSchemaValidator.validate([
                "items": ["valid", 123, "also valid"]
            ], schema: [
                "type": "object",
                "properties": [
                    "items": [
                        "type": "array",
                        "items": ["type": "string"]
                    ]
                ]
            ])
            Issue.record("Expected validation to throw")
        } catch let errors as [ValidationError] {
            #expect(errors.count == 1)
            if case .typeMismatch(_, _, let path) = errors[0] {
                #expect(path == "items[1]")
            } else {
                Issue.record("Expected typeMismatch error")
            }
        }
    }

    // MARK: - Edge Cases

    @Test("Empty schema allows any value")
    func emptySchemaAllowsAnyValue() throws {
        let emptySchema: [String: Any] = [:]
        try JSONSchemaValidator.validate("anything", schema: emptySchema)
        try JSONSchemaValidator.validate(123, schema: emptySchema)
        try JSONSchemaValidator.validate(true, schema: emptySchema)
        try JSONSchemaValidator.validate(["key": "value"], schema: emptySchema)
    }

    @Test("Null value validation")
    func nullValueValidation() throws {
        try JSONSchemaValidator.validate(nil, schema: ["type": "null"])
    }

    @Test("Optional nullable field")
    func optionalNullableField() throws {
        try JSONSchemaValidator.validate([
            "name": "John",
            "nickname": NSNull()
        ], schema: [
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "nickname": ["type": ["string", "null"]]
            ]
        ])
    }

    // MARK: - Real-world Schema Examples

    @Test("Product schema validation")
    func productSchemaValidation() throws {
        try JSONSchemaValidator.validate([
            "name": "Widget",
            "price": 29.99,
            "quantity": 100,
            "categories": ["electronics", "gadgets"],
            "inStock": true
        ], schema: [
            "type": "object",
            "properties": [
                "name": ["type": "string", "minLength": 1, "maxLength": 100],
                "price": ["type": "number", "minimum": 0],
                "quantity": ["type": "integer", "minimum": 0],
                "categories": [
                    "type": "array",
                    "items": ["type": "string"],
                    "minItems": 1
                ],
                "inStock": ["type": "boolean"]
            ],
            "required": ["name", "price"]
        ])
    }

    @Test("Config schema with defaults")
    func configSchemaWithDefaults() throws {
        try JSONSchemaValidator.validate([
            "host": "localhost",
            "port": 8080,
            "ssl": false,
            "timeout": 30
        ], schema: [
            "type": "object",
            "properties": [
                "host": ["type": "string", "format": "hostname"],
                "port": ["type": "integer", "minimum": 1, "maximum": 65535],
                "ssl": ["type": "boolean"],
                "timeout": ["type": "integer", "minimum": 1, "maximum": 300]
            ],
            "required": ["host", "port"]
        ])
    }
}
