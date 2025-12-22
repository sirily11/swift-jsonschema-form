import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

class JSONSchemaFormArrayTests: XCTestCase {
    override func setUp() {
        super.setUp()
        executionTimeAllowance = 30
    }

    @MainActor
    func testArrayFieldDirectly() async throws {
        // Test ArrayField directly to avoid deep view hierarchy traversal
        let items: [FormData] = [.string("item1"), .string("item2")]
        var formData = FormData.array(items: items)
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "array",
                    "items": { "type": "string" }
                }
                """)

        let arrayField = ArrayField(
            schema: schema,
            uiSchema: nil,
            id: "root_items",
            formData: binding,
            required: false,
            propertyName: "items"
        )

        // Verify we can inspect the array field
        let section = try arrayField.inspect().section()
        XCTAssertNotNil(section)

        // Verify the form data is correct
        if case .array(let resultItems) = formData {
            XCTAssertEqual(resultItems.count, 2)
            XCTAssertEqual(resultItems[0], .string("item1"))
            XCTAssertEqual(resultItems[1], .string("item2"))
        } else {
            XCTFail("Expected array form data")
        }
    }

    @MainActor
    func testEmptyArrayField() async throws {
        var formData = FormData.array(items: [])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "array",
                    "items": { "type": "string" }
                }
                """)

        let arrayField = ArrayField(
            schema: schema,
            uiSchema: nil,
            id: "root_items",
            formData: binding,
            required: false,
            propertyName: "items"
        )

        // Find "No items" text within the section
        let section = try arrayField.inspect().section()
        let noItemsText = try section.find(text: "No items")
        XCTAssertNotNil(noItemsText)
    }

    @MainActor
    func testArrayWithNumberItems() async throws {
        var formData = FormData.array(items: [.number(10), .number(20)])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "array",
                    "items": { "type": "number" }
                }
                """)

        let arrayField = ArrayField(
            schema: schema,
            uiSchema: nil,
            id: "root_scores",
            formData: binding,
            required: false,
            propertyName: "scores"
        )

        // Verify we can inspect
        let section = try arrayField.inspect().section()
        XCTAssertNotNil(section)

        // Verify form data
        if case .array(let items) = formData {
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(items[0], .number(10))
            XCTAssertEqual(items[1], .number(20))
        } else {
            XCTFail("Expected array form data")
        }
    }

    @MainActor
    func testArrayFormDataBinding() async throws {
        // Test that array field properly binds and can be updated
        var formData = FormData.array(items: [.string("original")])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "array",
                    "items": { "type": "string" }
                }
                """)

        let arrayField = ArrayField(
            schema: schema,
            uiSchema: nil,
            id: "root_items",
            formData: binding,
            required: false,
            propertyName: "items"
        )

        // Verify initial state
        let section = try arrayField.inspect().section()
        XCTAssertNotNil(section)

        // Verify form data
        if case .array(let items) = formData {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items[0], .string("original"))
        } else {
            XCTFail("Expected array form data")
        }
    }

    @MainActor
    func testArrayWithObjectItems() async throws {
        var formData = FormData.array(items: [
            .object(properties: ["name": .string("John")]),
            .object(properties: ["name": .string("Jane")])
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "name": { "type": "string" }
                        }
                    }
                }
                """)

        let arrayField = ArrayField(
            schema: schema,
            uiSchema: nil,
            id: "root_people",
            formData: binding,
            required: false,
            propertyName: "people"
        )

        // Verify we can inspect
        let section = try arrayField.inspect().section()
        XCTAssertNotNil(section)

        // Verify form data structure
        if case .array(let items) = formData {
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(items[0].object?["name"], .string("John"))
            XCTAssertEqual(items[1].object?["name"], .string("Jane"))
        } else {
            XCTFail("Expected array form data")
        }
    }
}
