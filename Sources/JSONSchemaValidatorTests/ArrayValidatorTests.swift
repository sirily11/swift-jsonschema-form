import Testing
@testable import JSONSchemaValidator

@Suite("Array Validator Tests")
struct ArrayValidatorTests {
    // MARK: - minItems Tests

    @Test("Valid array with minItems")
    func validArrayWithMinItems() throws {
        try JSONSchemaValidator.validate([1, 2, 3], schema: [
            "type": "array",
            "minItems": 2
        ])
    }

    @Test("Valid array exactly at minItems")
    func validArrayExactlyAtMinItems() throws {
        try JSONSchemaValidator.validate([1, 2], schema: [
            "type": "array",
            "minItems": 2
        ])
    }

    @Test("Invalid array with too few items")
    func invalidArrayTooFewItems() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([1], schema: [
                "type": "array",
                "minItems": 2
            ])
        }
    }

    // MARK: - maxItems Tests

    @Test("Valid array with maxItems")
    func validArrayWithMaxItems() throws {
        try JSONSchemaValidator.validate([1, 2], schema: [
            "type": "array",
            "maxItems": 3
        ])
    }

    @Test("Valid array exactly at maxItems")
    func validArrayExactlyAtMaxItems() throws {
        try JSONSchemaValidator.validate([1, 2, 3], schema: [
            "type": "array",
            "maxItems": 3
        ])
    }

    @Test("Invalid array with too many items")
    func invalidArrayTooManyItems() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([1, 2, 3, 4], schema: [
                "type": "array",
                "maxItems": 3
            ])
        }
    }

    // MARK: - uniqueItems Tests

    @Test("Valid array with unique items")
    func validArrayWithUniqueItems() throws {
        try JSONSchemaValidator.validate([1, 2, 3], schema: [
            "type": "array",
            "uniqueItems": true
        ])
    }

    @Test("Valid array with unique string items")
    func validArrayWithUniqueStringItems() throws {
        try JSONSchemaValidator.validate(["a", "b", "c"], schema: [
            "type": "array",
            "uniqueItems": true
        ])
    }

    @Test("Invalid array with duplicate items")
    func invalidArrayWithDuplicateItems() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([1, 2, 2, 3], schema: [
                "type": "array",
                "uniqueItems": true
            ])
        }
    }

    @Test("Invalid array with duplicate string items")
    func invalidArrayWithDuplicateStringItems() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(["a", "b", "a"], schema: [
                "type": "array",
                "uniqueItems": true
            ])
        }
    }

    // MARK: - items Tests

    @Test("Valid array with items schema")
    func validArrayWithItemsSchema() throws {
        try JSONSchemaValidator.validate(["a", "b", "c"], schema: [
            "type": "array",
            "items": ["type": "string"]
        ])
    }

    @Test("Valid array with number items")
    func validArrayWithNumberItems() throws {
        try JSONSchemaValidator.validate([1, 2, 3], schema: [
            "type": "array",
            "items": ["type": "number"]
        ])
    }

    @Test("Invalid array with wrong item type")
    func invalidArrayWithWrongItemType() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(["a", 2, "c"], schema: [
                "type": "array",
                "items": ["type": "string"]
            ])
        }
    }

    @Test("Valid array with complex items schema")
    func validArrayWithComplexItemsSchema() throws {
        try JSONSchemaValidator.validate([
            ["name": "John", "age": 30],
            ["name": "Jane", "age": 25]
        ], schema: [
            "type": "array",
            "items": [
                "type": "object",
                "properties": [
                    "name": ["type": "string"],
                    "age": ["type": "integer"]
                ],
                "required": ["name"]
            ]
        ])
    }

    // MARK: - Combined Constraints Tests

    @Test("Valid array with multiple constraints")
    func validArrayWithMultipleConstraints() throws {
        try JSONSchemaValidator.validate([1, 2, 3], schema: [
            "type": "array",
            "items": ["type": "integer"],
            "minItems": 2,
            "maxItems": 5,
            "uniqueItems": true
        ])
    }

    @Test("Invalid array failing uniqueness with other constraints")
    func invalidArrayFailingUniqueness() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([1, 2, 2, 3], schema: [
                "type": "array",
                "items": ["type": "integer"],
                "minItems": 2,
                "maxItems": 5,
                "uniqueItems": true
            ])
        }
    }

    // MARK: - Empty Array Tests

    @Test("Valid empty array")
    func validEmptyArray() throws {
        let emptyArray: [Any] = []
        try JSONSchemaValidator.validate(emptyArray, schema: [
            "type": "array"
        ])
    }

    @Test("Invalid empty array with minItems")
    func invalidEmptyArrayWithMinItems() throws {
        #expect(throws: [ValidationError].self) {
            let emptyArray: [Any] = []
            try JSONSchemaValidator.validate(emptyArray, schema: [
                "type": "array",
                "minItems": 1
            ])
        }
    }

    // MARK: - prefixItems Tests

    @Test("Valid array with prefixItems - all items match")
    func validPrefixItemsAllMatch() throws {
        try JSONSchemaValidator.validate(["hello", 42], schema: [
            "type": "array",
            "prefixItems": [
                ["type": "string"],
                ["type": "number"]
            ]
        ])
    }

    @Test("Valid array with prefixItems - fewer items than schemas")
    func validPrefixItemsFewerItems() throws {
        try JSONSchemaValidator.validate(["hello"], schema: [
            "type": "array",
            "prefixItems": [
                ["type": "string"],
                ["type": "number"],
                ["type": "boolean"]
            ]
        ])
    }

    @Test("Invalid prefixItems - item doesn't match schema")
    func invalidPrefixItemsTypeMismatch() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([42, "hello"], schema: [
                "type": "array",
                "prefixItems": [
                    ["type": "string"],
                    ["type": "number"]
                ]
            ])
        }
    }

    @Test("Valid prefixItems with items schema for additional items")
    func validPrefixItemsWithAdditionalItems() throws {
        try JSONSchemaValidator.validate(["header", 100, true, true, true], schema: [
            "type": "array",
            "prefixItems": [
                ["type": "string"],
                ["type": "number"]
            ],
            "items": ["type": "boolean"]
        ])
    }

    @Test("Invalid additional items after prefixItems")
    func invalidAdditionalItemsAfterPrefixItems() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(["header", 100, "not-a-boolean"], schema: [
                "type": "array",
                "prefixItems": [
                    ["type": "string"],
                    ["type": "number"]
                ],
                "items": ["type": "boolean"]
            ])
        }
    }

    @Test("Valid prefixItems with items: false - no additional items")
    func validPrefixItemsNoAdditionalItems() throws {
        try JSONSchemaValidator.validate(["hello", 42], schema: [
            "type": "array",
            "prefixItems": [
                ["type": "string"],
                ["type": "number"]
            ],
            "items": false
        ])
    }

    @Test("Invalid prefixItems with items: false - has additional items")
    func invalidPrefixItemsHasAdditionalItems() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(["hello", 42, "extra"], schema: [
                "type": "array",
                "prefixItems": [
                    ["type": "string"],
                    ["type": "number"]
                ],
                "items": false
            ])
        }
    }

    // MARK: - contains Tests

    @Test("Valid array with contains - one item matches")
    func validContainsOneMatch() throws {
        try JSONSchemaValidator.validate([1, 2, "hello", 3], schema: [
            "type": "array",
            "contains": ["type": "string"]
        ])
    }

    @Test("Valid array with contains - multiple items match")
    func validContainsMultipleMatches() throws {
        try JSONSchemaValidator.validate(["a", "b", "c"], schema: [
            "type": "array",
            "contains": ["type": "string"]
        ])
    }

    @Test("Invalid array with contains - no items match")
    func invalidContainsNoMatch() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([1, 2, 3], schema: [
                "type": "array",
                "contains": ["type": "string"]
            ])
        }
    }

    @Test("Valid contains with minContains")
    func validContainsWithMinContains() throws {
        try JSONSchemaValidator.validate(["a", 1, "b", 2, "c"], schema: [
            "type": "array",
            "contains": ["type": "string"],
            "minContains": 3
        ])
    }

    @Test("Invalid contains with minContains - too few matches")
    func invalidContainsTooFewMatches() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(["a", 1, "b", 2], schema: [
                "type": "array",
                "contains": ["type": "string"],
                "minContains": 3
            ])
        }
    }

    @Test("Valid contains with maxContains")
    func validContainsWithMaxContains() throws {
        try JSONSchemaValidator.validate(["a", 1, "b", 2], schema: [
            "type": "array",
            "contains": ["type": "string"],
            "maxContains": 2
        ])
    }

    @Test("Invalid contains with maxContains - too many matches")
    func invalidContainsTooManyMatches() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate(["a", "b", "c"], schema: [
                "type": "array",
                "contains": ["type": "string"],
                "maxContains": 2
            ])
        }
    }

    @Test("Valid contains with minContains and maxContains range")
    func validContainsWithRange() throws {
        try JSONSchemaValidator.validate(["a", 1, "b", 2, "c"], schema: [
            "type": "array",
            "contains": ["type": "string"],
            "minContains": 2,
            "maxContains": 4
        ])
    }

    // MARK: - Edge Cases

    @Test("Empty array with contains fails")
    func emptyArrayWithContainsFails() throws {
        #expect(throws: [ValidationError].self) {
            let emptyArray: [Any] = []
            try JSONSchemaValidator.validate(emptyArray, schema: [
                "type": "array",
                "contains": ["type": "string"]
            ])
        }
    }

    @Test("Empty array with minContains: 0 succeeds")
    func emptyArrayWithMinContainsZero() throws {
        let emptyArray: [Any] = []
        try JSONSchemaValidator.validate(emptyArray, schema: [
            "type": "array",
            "contains": ["type": "string"],
            "minContains": 0
        ])
    }

    @Test("prefixItems with nested object validation")
    func prefixItemsWithNestedObject() throws {
        try JSONSchemaValidator.validate([["name": "test"]], schema: [
            "type": "array",
            "prefixItems": [
                [
                    "type": "object",
                    "properties": ["name": ["type": "string"]]
                ]
            ]
        ])
    }

    @Test("prefixItems with nested array validation")
    func prefixItemsWithNestedArray() throws {
        try JSONSchemaValidator.validate([[1, 2, 3]], schema: [
            "type": "array",
            "prefixItems": [
                [
                    "type": "array",
                    "items": ["type": "number"]
                ]
            ]
        ])
    }

    @Test("Invalid nested object in prefixItems")
    func invalidNestedObjectInPrefixItems() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate([[:]], schema: [
                "type": "array",
                "prefixItems": [
                    [
                        "type": "object",
                        "required": ["name"]
                    ]
                ]
            ])
        }
    }

    @Test("contains with complex object schema")
    func containsWithComplexObjectSchema() throws {
        try JSONSchemaValidator.validate([
            ["status": "inactive"],
            ["status": "active"]
        ], schema: [
            "type": "array",
            "contains": [
                "type": "object",
                "properties": [
                    "status": ["enum": ["active"]]
                ],
                "required": ["status"]
            ]
        ])
    }

    @Test("prefixItems boundary - exactly at schema count")
    func prefixItemsExactlyAtSchemaCount() throws {
        try JSONSchemaValidator.validate(["a", 1, true], schema: [
            "type": "array",
            "prefixItems": [
                ["type": "string"],
                ["type": "number"],
                ["type": "boolean"]
            ],
            "items": false
        ])
    }

    @Test("contains with minContains: 0 always succeeds")
    func containsMinContainsZeroAlwaysSucceeds() throws {
        try JSONSchemaValidator.validate([1, 2, 3], schema: [
            "type": "array",
            "contains": ["type": "string"],
            "minContains": 0
        ])
    }
}
