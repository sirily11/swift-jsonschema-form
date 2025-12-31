import Testing
@testable import JSONSchemaValidator

@Suite("Combinators Validator Tests")
struct CombinatorsValidatorTests {
    // MARK: - allOf Tests

    @Test("Valid allOf - all schemas match")
    func validAllOfAllSchemasMatch() throws {
        try JSONSchemaValidator.validate([
            "name": "John",
            "age": 30
        ], schema: [
            "allOf": [
                [
                    "type": "object",
                    "properties": ["name": ["type": "string"]],
                    "required": ["name"]
                ],
                [
                    "type": "object",
                    "properties": ["age": ["type": "integer"]],
                    "required": ["age"]
                ]
            ]
        ])
    }

    @Test("Invalid allOf - not all schemas match")
    func invalidAllOfNotAllSchemasMatch() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "name": "John"
            ] as [String: Any], schema: [
                "allOf": [
                    [
                        "type": "object",
                        "properties": ["name": ["type": "string"]],
                        "required": ["name"]
                    ],
                    [
                        "type": "object",
                        "properties": ["age": ["type": "integer"]],
                        "required": ["age"]
                    ]
                ]
            ])
        }
    }

    // MARK: - anyOf Tests

    @Test("Valid anyOf - first schema matches")
    func validAnyOfFirstSchemaMatches() throws {
        try JSONSchemaValidator.validate("hello", schema: [
            "anyOf": [
                ["type": "string"],
                ["type": "number"]
            ]
        ])
    }

    @Test("Valid anyOf - second schema matches")
    func validAnyOfSecondSchemaMatches() throws {
        try JSONSchemaValidator.validate(42, schema: [
            "anyOf": [
                ["type": "string"],
                ["type": "number"]
            ]
        ])
    }

    @Test("Invalid anyOf - no schema matches")
    func invalidAnyOfNoSchemaMatches() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(true, schema: [
                "anyOf": [
                    ["type": "string"],
                    ["type": "number"]
                ]
            ])
        }
    }

    @Test("Valid anyOf with constraints")
    func validAnyOfWithConstraints() throws {
        try JSONSchemaValidator.validate("hello", schema: [
            "anyOf": [
                ["type": "string", "minLength": 5],
                ["type": "number", "minimum": 0]
            ]
        ])
    }

    // MARK: - oneOf Tests

    @Test("Valid oneOf - exactly one matches")
    func validOneOfExactlyOneMatches() throws {
        try JSONSchemaValidator.validate(5, schema: [
            "oneOf": [
                ["type": "integer", "minimum": 0, "maximum": 10],
                ["type": "integer", "minimum": 20, "maximum": 30]
            ]
        ])
    }

    @Test("Invalid oneOf - none match")
    func invalidOneOfNoneMatch() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(15, schema: [
                "oneOf": [
                    ["type": "integer", "minimum": 0, "maximum": 10],
                    ["type": "integer", "minimum": 20, "maximum": 30]
                ]
            ])
        }
    }

    @Test("Invalid oneOf - multiple match")
    func invalidOneOfMultipleMatch() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(5, schema: [
                "oneOf": [
                    ["type": "integer"],
                    ["type": "number"]
                ]
            ])
        }
    }

    // MARK: - not Tests

    @Test("Valid not - schema does not match")
    func validNotSchemaDoesNotMatch() throws {
        try JSONSchemaValidator.validate("hello", schema: [
            "not": ["type": "number"]
        ])
    }

    @Test("Invalid not - schema matches")
    func invalidNotSchemaMatches() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(42, schema: [
                "not": ["type": "number"]
            ])
        }
    }

    @Test("Valid not with enum")
    func validNotWithEnum() throws {
        try JSONSchemaValidator.validate("yellow", schema: [
            "type": "string",
            "not": ["enum": ["red", "green", "blue"]]
        ])
    }

    // MARK: - if/then/else Tests

    @Test("Valid if/then - condition matches, then applies")
    func validIfThenConditionMatches() throws {
        try JSONSchemaValidator.validate([
            "type": "business",
            "taxId": "123456789"
        ], schema: [
            "type": "object",
            "if": [
                "properties": ["type": ["const": "business"]]
            ],
            "then": [
                "required": ["taxId"]
            ]
        ])
    }

    @Test("Valid if/else - condition doesn't match, else applies")
    func validIfElseConditionDoesntMatch() throws {
        try JSONSchemaValidator.validate([
            "type": "personal",
            "name": "John"
        ], schema: [
            "type": "object",
            "if": [
                "properties": ["type": ["const": "business"]]
            ],
            "then": [
                "required": ["taxId"]
            ],
            "else": [
                "required": ["name"]
            ]
        ])
    }

    @Test("Invalid if/then - condition matches, then fails")
    func invalidIfThenConditionMatchesThenFails() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "type": "business"
            ] as [String: Any], schema: [
                "type": "object",
                "if": [
                    "properties": ["type": ["const": "business"]]
                ],
                "then": [
                    "required": ["taxId"]
                ]
            ])
        }
    }

    // MARK: - Nested Combinators Tests

    @Test("Valid nested combinators")
    func validNestedCombinators() throws {
        try JSONSchemaValidator.validate(5, schema: [
            "allOf": [
                ["type": "integer"],
                [
                    "anyOf": [
                        ["minimum": 0],
                        ["maximum": -10]
                    ]
                ]
            ]
        ])
    }
}
