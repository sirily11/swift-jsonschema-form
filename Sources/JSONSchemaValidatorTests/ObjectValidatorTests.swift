import Testing
@testable import JSONSchemaValidator

@Suite("Object Validator Tests")
struct ObjectValidatorTests {
    // MARK: - required Tests

    @Test("Valid object with all required properties")
    func validObjectWithRequiredProperties() throws {
        try JSONSchemaValidator.validate([
            "name": "John",
            "age": 30
        ], schema: [
            "type": "object",
            "required": ["name", "age"]
        ])
    }

    @Test("Valid object with required and optional properties")
    func validObjectWithOptionalProperties() throws {
        try JSONSchemaValidator.validate([
            "name": "John"
        ], schema: [
            "type": "object",
            "required": ["name"]
        ])
    }

    @Test("Invalid object missing required property")
    func invalidObjectMissingRequired() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "name": "John"
            ] as [String: Any], schema: [
                "type": "object",
                "required": ["name", "age"]
            ])
        }
    }

    // MARK: - properties Tests

    @Test("Valid object with property schemas")
    func validObjectWithPropertySchemas() throws {
        try JSONSchemaValidator.validate([
            "name": "John",
            "age": 30
        ], schema: [
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "age": ["type": "integer"]
            ]
        ])
    }

    @Test("Invalid object with wrong property type")
    func invalidObjectWithWrongPropertyType() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "name": "John",
                "age": "thirty"
            ], schema: [
                "type": "object",
                "properties": [
                    "name": ["type": "string"],
                    "age": ["type": "integer"]
                ]
            ])
        }
    }

    // MARK: - additionalProperties Tests

    @Test("Valid object allowing additional properties")
    func validObjectWithAdditionalProperties() throws {
        try JSONSchemaValidator.validate([
            "name": "John",
            "extra": "value"
        ], schema: [
            "type": "object",
            "properties": [
                "name": ["type": "string"]
            ],
            "additionalProperties": true
        ])
    }

    @Test("Invalid object with disallowed additional properties")
    func invalidObjectWithDisallowedAdditionalProperties() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "name": "John",
                "extra": "value"
            ], schema: [
                "type": "object",
                "properties": [
                    "name": ["type": "string"]
                ],
                "additionalProperties": false
            ])
        }
    }

    @Test("Valid object with typed additional properties")
    func validObjectWithTypedAdditionalProperties() throws {
        try JSONSchemaValidator.validate([
            "name": "John",
            "field1": "value1",
            "field2": "value2"
        ], schema: [
            "type": "object",
            "properties": [
                "name": ["type": "string"]
            ],
            "additionalProperties": ["type": "string"]
        ])
    }

    @Test("Invalid object with wrong type additional properties")
    func invalidObjectWithWrongTypeAdditionalProperties() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "name": "John",
                "field1": 123
            ], schema: [
                "type": "object",
                "properties": [
                    "name": ["type": "string"]
                ],
                "additionalProperties": ["type": "string"]
            ])
        }
    }

    // MARK: - minProperties/maxProperties Tests

    @Test("Valid object with minProperties")
    func validObjectWithMinProperties() throws {
        try JSONSchemaValidator.validate([
            "a": 1,
            "b": 2
        ], schema: [
            "type": "object",
            "minProperties": 2
        ])
    }

    @Test("Invalid object with too few properties")
    func invalidObjectWithTooFewProperties() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "a": 1
            ] as [String: Any], schema: [
                "type": "object",
                "minProperties": 2
            ])
        }
    }

    @Test("Valid object with maxProperties")
    func validObjectWithMaxProperties() throws {
        try JSONSchemaValidator.validate([
            "a": 1,
            "b": 2
        ], schema: [
            "type": "object",
            "maxProperties": 3
        ])
    }

    @Test("Invalid object with too many properties")
    func invalidObjectWithTooManyProperties() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "a": 1,
                "b": 2,
                "c": 3,
                "d": 4
            ], schema: [
                "type": "object",
                "maxProperties": 3
            ])
        }
    }

    // MARK: - Nested Object Tests

    @Test("Valid nested object")
    func validNestedObject() throws {
        try JSONSchemaValidator.validate([
            "user": [
                "name": "John",
                "address": [
                    "city": "NYC",
                    "zip": "10001"
                ]
            ]
        ], schema: [
            "type": "object",
            "properties": [
                "user": [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "address": [
                            "type": "object",
                            "properties": [
                                "city": ["type": "string"],
                                "zip": ["type": "string"]
                            ]
                        ]
                    ]
                ]
            ]
        ])
    }

    @Test("Invalid nested object with wrong type")
    func invalidNestedObjectWithWrongType() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "user": [
                    "name": "John",
                    "address": [
                        "city": "NYC",
                        "zip": 10001  // Should be string
                    ]
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "user": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string"],
                            "address": [
                                "type": "object",
                                "properties": [
                                    "city": ["type": "string"],
                                    "zip": ["type": "string"]
                                ]
                            ]
                        ]
                    ]
                ]
            ])
        }
    }

    // MARK: - Nested Required Properties Tests

    @Test("Invalid nested object missing required property")
    func invalidNestedObjectMissingRequired() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "user": [
                    "name": "John",
                    "address": [
                        "city": "NYC"
                        // missing required "zip"
                    ]
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "user": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string"],
                            "address": [
                                "type": "object",
                                "properties": [
                                    "city": ["type": "string"],
                                    "zip": ["type": "string"]
                                ],
                                "required": ["city", "zip"]
                            ]
                        ]
                    ]
                ]
            ])
        }
    }

    @Test("Invalid nested object with required at multiple levels")
    func invalidNestedObjectWithRequiredAtMultipleLevels() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "user": [
                    // missing required "name"
                    "address": [
                        "city": "NYC"
                        // missing required "zip"
                    ]
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "user": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string"],
                            "address": [
                                "type": "object",
                                "properties": [
                                    "city": ["type": "string"],
                                    "zip": ["type": "string"]
                                ],
                                "required": ["city", "zip"]
                            ]
                        ],
                        "required": ["name", "address"]
                    ]
                ]
            ])
        }
    }

    // MARK: - Nested additionalProperties Tests

    @Test("Invalid nested object with disallowed additional properties")
    func invalidNestedObjectWithDisallowedAdditionalProperties() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "user": [
                    "name": "John",
                    "address": [
                        "city": "NYC",
                        "zip": "10001",
                        "extra": "not allowed"
                    ]
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "user": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string"],
                            "address": [
                                "type": "object",
                                "properties": [
                                    "city": ["type": "string"],
                                    "zip": ["type": "string"]
                                ],
                                "additionalProperties": false
                            ]
                        ]
                    ]
                ]
            ])
        }
    }

    @Test("Valid nested object with typed additional properties")
    func validNestedObjectWithTypedAdditionalProperties() throws {
        try JSONSchemaValidator.validate([
            "user": [
                "name": "John",
                "address": [
                    "city": "NYC",
                    "zip": "10001",
                    "extra1": "string value",
                    "extra2": "another string"
                ]
            ]
        ], schema: [
            "type": "object",
            "properties": [
                "user": [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "address": [
                            "type": "object",
                            "properties": [
                                "city": ["type": "string"],
                                "zip": ["type": "string"]
                            ],
                            "additionalProperties": ["type": "string"]
                        ]
                    ]
                ]
            ]
        ])
    }

    @Test("Invalid nested object with wrong type additional properties")
    func invalidNestedObjectWithWrongTypeAdditionalProperties() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "user": [
                    "name": "John",
                    "address": [
                        "city": "NYC",
                        "zip": "10001",
                        "extra": 123  // Should be string
                    ]
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "user": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string"],
                            "address": [
                                "type": "object",
                                "properties": [
                                    "city": ["type": "string"],
                                    "zip": ["type": "string"]
                                ],
                                "additionalProperties": ["type": "string"]
                            ]
                        ]
                    ]
                ]
            ])
        }
    }

    // MARK: - Nested minProperties/maxProperties Tests

    @Test("Invalid nested object with too few properties")
    func invalidNestedObjectWithTooFewProperties() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "user": [
                    "name": "John",
                    "address": [
                        "city": "NYC"
                        // needs at least 2 properties
                    ]
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "user": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string"],
                            "address": [
                                "type": "object",
                                "minProperties": 2
                            ]
                        ]
                    ]
                ]
            ])
        }
    }

    @Test("Invalid nested object with too many properties")
    func invalidNestedObjectWithTooManyProperties() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "user": [
                    "name": "John",
                    "address": [
                        "city": "NYC",
                        "zip": "10001",
                        "state": "NY",
                        "country": "USA"
                    ]
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "user": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string"],
                            "address": [
                                "type": "object",
                                "maxProperties": 3
                            ]
                        ]
                    ]
                ]
            ])
        }
    }

    // MARK: - Deep Nesting Tests

    @Test("Valid deeply nested object (4+ levels)")
    func validDeeplyNestedObject() throws {
        try JSONSchemaValidator.validate([
            "level1": [
                "level2": [
                    "level3": [
                        "level4": [
                            "value": "deep"
                        ]
                    ]
                ]
            ]
        ], schema: [
            "type": "object",
            "properties": [
                "level1": [
                    "type": "object",
                    "properties": [
                        "level2": [
                            "type": "object",
                            "properties": [
                                "level3": [
                                    "type": "object",
                                    "properties": [
                                        "level4": [
                                            "type": "object",
                                            "properties": [
                                                "value": ["type": "string"]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ])
    }

    @Test("Invalid deeply nested object with error at 4th level")
    func invalidDeeplyNestedObject() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "level1": [
                    "level2": [
                        "level3": [
                            "level4": [
                                "value": 123  // Should be string
                            ]
                        ]
                    ]
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "level1": [
                        "type": "object",
                        "properties": [
                            "level2": [
                                "type": "object",
                                "properties": [
                                    "level3": [
                                        "type": "object",
                                        "properties": [
                                            "level4": [
                                                "type": "object",
                                                "properties": [
                                                    "value": ["type": "string"]
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ])
        }
    }

    // MARK: - Multiple Errors in Nested Objects

    @Test("Multiple validation errors at different nesting levels")
    func multipleErrorsAtDifferentNestingLevels() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "user": [
                    "name": 123,  // Error: should be string
                    "address": [
                        "city": true,  // Error: should be string
                        "zip": 10001   // Error: should be string
                    ]
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "user": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string"],
                            "address": [
                                "type": "object",
                                "properties": [
                                    "city": ["type": "string"],
                                    "zip": ["type": "string"]
                                ]
                            ]
                        ]
                    ]
                ]
            ])
        }
    }

    // MARK: - Nested Objects in Arrays

    @Test("Valid array of nested objects")
    func validArrayOfNestedObjects() throws {
        try JSONSchemaValidator.validate([
            "users": [
                [
                    "name": "John",
                    "address": [
                        "city": "NYC"
                    ]
                ],
                [
                    "name": "Jane",
                    "address": [
                        "city": "LA"
                    ]
                ]
            ]
        ], schema: [
            "type": "object",
            "properties": [
                "users": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string"],
                            "address": [
                                "type": "object",
                                "properties": [
                                    "city": ["type": "string"]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ])
    }

    @Test("Invalid nested object within array")
    func invalidNestedObjectWithinArray() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "users": [
                    [
                        "name": "John",
                        "address": [
                            "city": "NYC"
                        ]
                    ],
                    [
                        "name": "Jane",
                        "address": [
                            "city": 123  // Should be string
                        ]
                    ]
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "users": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "properties": [
                                "name": ["type": "string"],
                                "address": [
                                    "type": "object",
                                    "properties": [
                                        "city": ["type": "string"]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ])
        }
    }

    // MARK: - Mixed Nested Structures

    @Test("Valid object containing array containing objects")
    func validMixedNestedStructure() throws {
        try JSONSchemaValidator.validate([
            "company": [
                "name": "Acme",
                "departments": [
                    [
                        "name": "Engineering",
                        "employees": [
                            ["name": "John"],
                            ["name": "Jane"]
                        ]
                    ]
                ]
            ]
        ], schema: [
            "type": "object",
            "properties": [
                "company": [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "departments": [
                            "type": "array",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "name": ["type": "string"],
                                    "employees": [
                                        "type": "array",
                                        "items": [
                                            "type": "object",
                                            "properties": [
                                                "name": ["type": "string"]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ])
    }

    @Test("Invalid value in deeply mixed structure")
    func invalidValueInDeeplyMixedStructure() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "company": [
                    "name": "Acme",
                    "departments": [
                        [
                            "name": "Engineering",
                            "employees": [
                                ["name": "John"],
                                ["name": 123]  // Should be string
                            ]
                        ]
                    ]
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "company": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string"],
                            "departments": [
                                "type": "array",
                                "items": [
                                    "type": "object",
                                    "properties": [
                                        "name": ["type": "string"],
                                        "employees": [
                                            "type": "array",
                                            "items": [
                                                "type": "object",
                                                "properties": [
                                                    "name": ["type": "string"]
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ])
        }
    }

    // MARK: - Edge Cases

    @Test("Valid empty nested object")
    func validEmptyNestedObject() throws {
        try JSONSchemaValidator.validate([
            "user": [
                "name": "John",
                "metadata": [:] as [String: Any]
            ]
        ], schema: [
            "type": "object",
            "properties": [
                "user": [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "metadata": [
                            "type": "object"
                        ]
                    ]
                ]
            ]
        ])
    }

    @Test("Valid missing optional nested object")
    func validMissingOptionalNestedObject() throws {
        try JSONSchemaValidator.validate([
            "user": [
                "name": "John"
                // address is optional and not provided
            ]
        ], schema: [
            "type": "object",
            "properties": [
                "user": [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "address": [
                            "type": "object",
                            "properties": [
                                "city": ["type": "string"]
                            ]
                        ]
                    ],
                    "required": ["name"]
                ]
            ]
        ])
    }

    @Test("Invalid nested object when object expected but other type provided")
    func invalidNestedObjectWrongTypeProvided() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([
                "user": [
                    "name": "John",
                    "address": "not an object"  // Should be object
                ]
            ], schema: [
                "type": "object",
                "properties": [
                    "user": [
                        "type": "object",
                        "properties": [
                            "name": ["type": "string"],
                            "address": [
                                "type": "object",
                                "properties": [
                                    "city": ["type": "string"]
                                ]
                            ]
                        ]
                    ]
                ]
            ])
        }
    }
}
