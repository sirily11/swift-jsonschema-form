import XCTest

@testable import JSONSchemaForm

class FormDataEncodableTests: XCTestCase {

    // MARK: - Primitive Type Tests

    func testEncodeString() throws {
        let formData = FormData.string("hello")
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"hello\"")
    }

    func testEncodeEmptyString() throws {
        let formData = FormData.string("")
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "\"\"")
    }

    func testEncodeNumber() throws {
        let formData = FormData.number(42.5)
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "42.5")
    }

    func testEncodeIntegerNumber() throws {
        let formData = FormData.number(42)
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "42")
    }

    func testEncodeBooleanTrue() throws {
        let formData = FormData.boolean(true)
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "true")
    }

    func testEncodeBooleanFalse() throws {
        let formData = FormData.boolean(false)
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "false")
    }

    func testEncodeNull() throws {
        let formData = FormData.null
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "null")
    }

    // MARK: - Object Tests

    func testEncodeEmptyObject() throws {
        let formData = FormData.object(properties: [:])
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "{}")
    }

    func testEncodeSimpleObject() throws {
        let formData = FormData.object(properties: [
            "name": .string("John"),
            "age": .number(30)
        ])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "{\"age\":30,\"name\":\"John\"}")
    }

    func testEncodeNestedObject() throws {
        let formData = FormData.object(properties: [
            "person": .object(properties: [
                "name": .string("Jane"),
                "address": .object(properties: [
                    "city": .string("NYC")
                ])
            ])
        ])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "{\"person\":{\"address\":{\"city\":\"NYC\"},\"name\":\"Jane\"}}")
    }

    // MARK: - Array Tests

    func testEncodeEmptyArray() throws {
        let formData = FormData.array(items: [])
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "[]")
    }

    func testEncodeStringArray() throws {
        let formData = FormData.array(items: [
            .string("a"),
            .string("b"),
            .string("c")
        ])
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "[\"a\",\"b\",\"c\"]")
    }

    func testEncodeNumberArray() throws {
        let formData = FormData.array(items: [
            .number(1),
            .number(2),
            .number(3)
        ])
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "[1,2,3]")
    }

    func testEncodeMixedArray() throws {
        let formData = FormData.array(items: [
            .string("hello"),
            .number(42),
            .boolean(true),
            .null
        ])
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "[\"hello\",42,true,null]")
    }

    func testEncodeNestedArray() throws {
        let formData = FormData.array(items: [
            .array(items: [.number(1), .number(2)]),
            .array(items: [.number(3), .number(4)])
        ])
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "[[1,2],[3,4]]")
    }

    // MARK: - Mixed Structure Tests

    func testEncodeObjectWithArray() throws {
        let formData = FormData.object(properties: [
            "tags": .array(items: [
                .string("swift"),
                .string("ios")
            ])
        ])
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "{\"tags\":[\"swift\",\"ios\"]}")
    }

    func testEncodeArrayOfObjects() throws {
        let formData = FormData.array(items: [
            .object(properties: ["id": .number(1), "name": .string("Alice")]),
            .object(properties: ["id": .number(2), "name": .string("Bob")])
        ])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "[{\"id\":1,\"name\":\"Alice\"},{\"id\":2,\"name\":\"Bob\"}]")
    }

    func testEncodeComplexNestedStructure() throws {
        let formData = FormData.object(properties: [
            "users": .array(items: [
                .object(properties: [
                    "name": .string("John"),
                    "active": .boolean(true),
                    "scores": .array(items: [.number(90), .number(85)])
                ])
            ]),
            "metadata": .object(properties: [
                "version": .number(1),
                "nullable": .null
            ])
        ])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(formData)

        // Decode to verify structure
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(decoded)

        let users = decoded?["users"] as? [[String: Any]]
        XCTAssertEqual(users?.count, 1)
        XCTAssertEqual(users?.first?["name"] as? String, "John")
        XCTAssertEqual(users?.first?["active"] as? Bool, true)

        let scores = users?.first?["scores"] as? [Double]
        XCTAssertEqual(scores, [90, 85])

        let metadata = decoded?["metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["version"] as? Double, 1)
        XCTAssertTrue(metadata?["nullable"] is NSNull)
    }

    // MARK: - Special Character Tests

    func testEncodeStringWithSpecialCharacters() throws {
        let formData = FormData.string("Hello \"World\"\nNew Line\tTab")
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        let json = String(data: data, encoding: .utf8)
        XCTAssertNotNil(json)
        // Verify it can be decoded back
        let decoded = try JSONDecoder().decode(String.self, from: data)
        XCTAssertEqual(decoded, "Hello \"World\"\nNew Line\tTab")
    }

    func testEncodeStringWithUnicode() throws {
        let formData = FormData.string("こんにちは 🎉")
        let encoder = JSONEncoder()
        let data = try encoder.encode(formData)
        // Verify it can be decoded back via JSONSerialization
        let decoded = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? String
        XCTAssertEqual(decoded, "こんにちは 🎉")
    }

    // MARK: - Decode Primitive Type Tests

    func testDecodeString() throws {
        let formData = try FormData.fromJSONString("\"hello\"")
        XCTAssertEqual(formData, .string("hello"))
    }

    func testDecodeEmptyString() throws {
        let formData = try FormData.fromJSONString("\"\"")
        XCTAssertEqual(formData, .string(""))
    }

    func testDecodeNumber() throws {
        let formData = try FormData.fromJSONString("42.5")
        XCTAssertEqual(formData, .number(42.5))
    }

    func testDecodeIntegerNumber() throws {
        let formData = try FormData.fromJSONString("42")
        XCTAssertEqual(formData, .number(42))
    }

    func testDecodeBooleanTrue() throws {
        let formData = try FormData.fromJSONString("true")
        XCTAssertEqual(formData, .boolean(true))
    }

    func testDecodeBooleanFalse() throws {
        let formData = try FormData.fromJSONString("false")
        XCTAssertEqual(formData, .boolean(false))
    }

    func testDecodeNull() throws {
        let formData = try FormData.fromJSONString("null")
        XCTAssertEqual(formData, .null)
    }

    // MARK: - Decode Object Tests

    func testDecodeEmptyObject() throws {
        let formData = try FormData.fromJSONString("{}")
        XCTAssertEqual(formData, .object(properties: [:]))
    }

    func testDecodeSimpleObject() throws {
        let formData = try FormData.fromJSONString("""
            {"name": "John", "age": 30}
            """)
        XCTAssertEqual(formData, .object(properties: [
            "name": .string("John"),
            "age": .number(30)
        ]))
    }

    func testDecodeNestedObject() throws {
        let formData = try FormData.fromJSONString("""
            {"person": {"name": "Jane", "address": {"city": "NYC"}}}
            """)
        XCTAssertEqual(formData, .object(properties: [
            "person": .object(properties: [
                "name": .string("Jane"),
                "address": .object(properties: [
                    "city": .string("NYC")
                ])
            ])
        ]))
    }

    // MARK: - Decode Array Tests

    func testDecodeEmptyArray() throws {
        let formData = try FormData.fromJSONString("[]")
        XCTAssertEqual(formData, .array(items: []))
    }

    func testDecodeStringArray() throws {
        let formData = try FormData.fromJSONString("""
            ["a", "b", "c"]
            """)
        XCTAssertEqual(formData, .array(items: [
            .string("a"),
            .string("b"),
            .string("c")
        ]))
    }

    func testDecodeNumberArray() throws {
        let formData = try FormData.fromJSONString("[1, 2, 3]")
        XCTAssertEqual(formData, .array(items: [
            .number(1),
            .number(2),
            .number(3)
        ]))
    }

    func testDecodeMixedArray() throws {
        let formData = try FormData.fromJSONString("""
            ["hello", 42, true, null]
            """)
        XCTAssertEqual(formData, .array(items: [
            .string("hello"),
            .number(42),
            .boolean(true),
            .null
        ]))
    }

    func testDecodeNestedArray() throws {
        let formData = try FormData.fromJSONString("[[1, 2], [3, 4]]")
        XCTAssertEqual(formData, .array(items: [
            .array(items: [.number(1), .number(2)]),
            .array(items: [.number(3), .number(4)])
        ]))
    }

    // MARK: - Decode Mixed Structure Tests

    func testDecodeObjectWithArray() throws {
        let formData = try FormData.fromJSONString("""
            {"tags": ["swift", "ios"]}
            """)
        XCTAssertEqual(formData, .object(properties: [
            "tags": .array(items: [
                .string("swift"),
                .string("ios")
            ])
        ]))
    }

    func testDecodeArrayOfObjects() throws {
        let formData = try FormData.fromJSONString("""
            [{"id": 1, "name": "Alice"}, {"id": 2, "name": "Bob"}]
            """)
        XCTAssertEqual(formData, .array(items: [
            .object(properties: ["id": .number(1), "name": .string("Alice")]),
            .object(properties: ["id": .number(2), "name": .string("Bob")])
        ]))
    }

    func testDecodeComplexNestedStructure() throws {
        let json = """
            {
                "users": [
                    {
                        "name": "John",
                        "active": true,
                        "scores": [90, 85]
                    }
                ],
                "metadata": {
                    "version": 1,
                    "nullable": null
                }
            }
            """
        let formData = try FormData.fromJSONString(json)

        XCTAssertEqual(formData, .object(properties: [
            "users": .array(items: [
                .object(properties: [
                    "name": .string("John"),
                    "active": .boolean(true),
                    "scores": .array(items: [.number(90), .number(85)])
                ])
            ]),
            "metadata": .object(properties: [
                "version": .number(1),
                "nullable": .null
            ])
        ]))
    }

    // MARK: - Decode Special Character Tests

    func testDecodeStringWithSpecialCharacters() throws {
        let formData = try FormData.fromJSONString("\"Hello \\\"World\\\"\\nNew Line\\tTab\"")
        XCTAssertEqual(formData, .string("Hello \"World\"\nNew Line\tTab"))
    }

    func testDecodeStringWithUnicode() throws {
        let formData = try FormData.fromJSONString("\"こんにちは 🎉\"")
        XCTAssertEqual(formData, .string("こんにちは 🎉"))
    }

    // MARK: - Decode Error Tests

    func testDecodeInvalidJSON() throws {
        XCTAssertThrowsError(try FormData.fromJSONString("invalid json")) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDecodeEmptyInput() throws {
        XCTAssertThrowsError(try FormData.fromJSONString("")) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Round Trip Tests

    func testRoundTripPrimitives() throws {
        let testCases: [FormData] = [
            .string("hello"),
            .number(42.5),
            .boolean(true),
            .boolean(false),
            .null
        ]

        for original in testCases {
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(FormData.self, from: encoded)
            XCTAssertEqual(decoded, original, "Round trip failed for \(original.describe())")
        }
    }

    func testRoundTripObject() throws {
        let original = FormData.object(properties: [
            "name": .string("John"),
            "age": .number(30),
            "active": .boolean(true)
        ])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FormData.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }

    func testRoundTripArray() throws {
        let original = FormData.array(items: [
            .string("a"),
            .number(1),
            .boolean(true),
            .null
        ])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FormData.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }

    func testRoundTripComplexStructure() throws {
        let original = FormData.object(properties: [
            "users": .array(items: [
                .object(properties: [
                    "name": .string("John"),
                    "active": .boolean(true),
                    "scores": .array(items: [.number(90), .number(85)])
                ])
            ]),
            "metadata": .object(properties: [
                "version": .number(1),
                "nullable": .null
            ])
        ])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FormData.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }
}
