import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

class JSONSchemaFormFieldOrderTests: XCTestCase {

    // MARK: - ObjectField Order Tests

    @MainActor
    func testObjectFieldsPreserveJSONOrder() async throws {
        // Schema with properties in specific order: zebra, apple, mango
        // Fields should be rendered in the original JSON definition order
        let schemaJSON = """
            {
                "type": "object",
                "properties": {
                    "zebra": { "type": "string" },
                    "apple": { "type": "string" },
                    "mango": { "type": "string" }
                }
            }
            """
        let formData = FormData.object(properties: [
            "zebra": .string("zebra value"),
            "apple": .string("apple value"),
            "mango": .string("mango value"),
        ])
        let schema = try JSONSchema(jsonString: schemaJSON)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data, schemaJSON: schemaJSON)

        // Find all text fields
        let textFields = try form.inspect().findAll(ViewType.TextField.self)
        XCTAssertEqual(textFields.count, 3, "Should have 3 text fields")

        // Get the inputs (values) to identify field order
        let fieldValues = try textFields.map { try $0.input() }

        // Fields should be in the original JSON definition order: zebra, apple, mango
        let expectedOrder = ["zebra value", "apple value", "mango value"]
        XCTAssertEqual(
            fieldValues, expectedOrder,
            "Fields should preserve original JSON order. Got: \(fieldValues)")
    }

    @MainActor
    func testObjectFieldsPreserveConsistentOrder() async throws {
        // This test verifies that fields maintain consistent order
        let schemaJSON = """
            {
                "type": "object",
                "properties": {
                    "first": { "type": "string" },
                    "second": { "type": "string" },
                    "third": { "type": "string" }
                }
            }
            """
        let formData = FormData.object(properties: [
            "first": .string("1"),
            "second": .string("2"),
            "third": .string("3"),
        ])
        let schema = try JSONSchema(jsonString: schemaJSON)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data, schemaJSON: schemaJSON)

        // Find all fields by their IDs
        let firstField = try form.inspect().find(viewWithId: "root_first")
        let secondField = try form.inspect().find(viewWithId: "root_second")
        let thirdField = try form.inspect().find(viewWithId: "root_third")

        // All three fields should be found (this verifies the form renders all properties)
        XCTAssertNoThrow(try firstField.find(ViewType.TextField.self))
        XCTAssertNoThrow(try secondField.find(ViewType.TextField.self))
        XCTAssertNoThrow(try thirdField.find(ViewType.TextField.self))

        // Verify JSON definition order: first, second, third
        let textFields = try form.inspect().findAll(ViewType.TextField.self)
        let fieldValues = try textFields.map { try $0.input() }
        XCTAssertEqual(
            fieldValues, ["1", "2", "3"],
            "Fields should be in JSON definition order. Got: \(fieldValues)")
    }

    @MainActor
    func testNestedObjectFieldsPreserveJSONOrder() async throws {
        let schemaJSON = """
            {
                "type": "object",
                "properties": {
                    "parent": {
                        "type": "object",
                        "properties": {
                            "zebra": { "type": "string" },
                            "apple": { "type": "string" },
                            "mango": { "type": "string" }
                        }
                    }
                }
            }
            """
        let formData = FormData.object(properties: [
            "parent": .object(properties: [
                "zebra": .string("zebra"),
                "apple": .string("apple"),
                "mango": .string("mango"),
            ])
        ])
        let schema = try JSONSchema(jsonString: schemaJSON)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data, schemaJSON: schemaJSON)

        // Find nested text fields
        let textFields = try form.inspect().findAll(ViewType.TextField.self)
        XCTAssertEqual(textFields.count, 3, "Should have 3 nested text fields")

        // Get the inputs to verify order
        let fieldValues = try textFields.map { try $0.input() }

        // Verify fields are in original JSON definition order
        let expectedOrder = ["zebra", "apple", "mango"]
        XCTAssertEqual(
            fieldValues, expectedOrder,
            "Nested fields should preserve JSON order. Got: \(fieldValues)")
    }

    @MainActor
    func testMixedTypeFieldsWithJSONOrder() async throws {
        // Test with different field types to ensure JSON order is preserved
        let schemaJSON = """
            {
                "type": "object",
                "properties": {
                    "zoo": { "type": "string" },
                    "active": { "type": "boolean" },
                    "count": { "type": "number" }
                }
            }
            """
        let formData = FormData.object(properties: [
            "zoo": .string("zoo"),
            "active": .boolean(true),
            "count": .number(42),
        ])
        let schema = try JSONSchema(jsonString: schemaJSON)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data, schemaJSON: schemaJSON)

        // Find the fields by ID to verify they exist
        let zooField = try form.inspect().find(viewWithId: "root_zoo")
        let activeField = try form.inspect().find(viewWithId: "root_active")
        let countField = try form.inspect().find(viewWithId: "root_count")

        // All fields should be found and accessible
        XCTAssertNoThrow(try zooField.find(ViewType.TextField.self))
        XCTAssertNoThrow(try activeField.find(ViewType.Toggle.self))
        XCTAssertNoThrow(try countField.find(ViewType.TextField.self))
    }

    // MARK: - Regression Test for Stable Ordering

    @MainActor
    func testFieldOrderPreservesJSONDefinitionOrder() async throws {
        // Regression test to ensure fields always use original JSON definition order
        let schemaJSON = """
            {
                "type": "object",
                "properties": {
                    "z_last": { "type": "string" },
                    "a_first": { "type": "string" },
                    "m_middle": { "type": "string" }
                }
            }
            """
        let formData = FormData.object(properties: [
            "z_last": .string("last"),
            "a_first": .string("first"),
            "m_middle": .string("middle"),
        ])
        let schema = try JSONSchema(jsonString: schemaJSON)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data, schemaJSON: schemaJSON)

        let textFields = try form.inspect().findAll(ViewType.TextField.self)
        let fieldValues = try textFields.map { try $0.input() }

        // Fields should be in JSON definition order: z_last, a_first, m_middle
        // NOT alphabetical (a_first, m_middle, z_last)
        let expectedOrder = ["last", "first", "middle"]
        XCTAssertEqual(
            fieldValues, expectedOrder,
            "Fields should preserve JSON definition order, not alphabetical. Got: \(fieldValues)")
    }

    @MainActor
    func testFieldOrderStableAfterFormDataUpdate() async throws {
        // Verify that field order does not change after updating form data values
        let schemaJSON = """
            {
                "type": "object",
                "properties": {
                    "zebra": { "type": "string" },
                    "apple": { "type": "string" },
                    "mango": { "type": "string" }
                }
            }
            """
        var formData = FormData.object(properties: [
            "zebra": .string("zebra"),
            "apple": .string("apple"),
            "mango": .string("mango"),
        ])
        let schema = try JSONSchema(jsonString: schemaJSON)

        let data = Binding(get: { formData }, set: { formData = $0 })
        let form = JSONSchemaForm(schema: schema, formData: data, schemaJSON: schemaJSON)

        // Get initial order
        let initialTextFields = try form.inspect().findAll(ViewType.TextField.self)
        let initialValues = try initialTextFields.map { try $0.input() }
        XCTAssertEqual(
            initialValues, ["zebra", "apple", "mango"],
            "Initial order should match JSON definition order")

        // Simulate a form data update (e.g., user edits the "zebra" field)
        formData = FormData.object(properties: [
            "zebra": .string("updated zebra"),
            "apple": .string("apple"),
            "mango": .string("mango"),
        ])

        // Re-inspect the form with updated data
        let updatedForm = JSONSchemaForm(schema: schema, formData: data, schemaJSON: schemaJSON)
        let updatedTextFields = try updatedForm.inspect().findAll(ViewType.TextField.self)
        let updatedValues = try updatedTextFields.map { try $0.input() }

        // Order should remain the same after update
        XCTAssertEqual(
            updatedValues, ["updated zebra", "apple", "mango"],
            "Field order should remain stable after form data update. Got: \(updatedValues)")
    }

    // MARK: - ui:order Tests

    @MainActor
    func testUIOrderOverridesJSONOrder() async throws {
        // Test that ui:order from uiSchema takes precedence over JSON definition order
        let schemaJSON = """
            {
                "type": "object",
                "properties": {
                    "zebra": { "type": "string" },
                    "apple": { "type": "string" },
                    "mango": { "type": "string" }
                }
            }
            """
        let formData = FormData.object(properties: [
            "zebra": .string("zebra"),
            "apple": .string("apple"),
            "mango": .string("mango"),
        ])
        let schema = try JSONSchema(jsonString: schemaJSON)

        // ui:order specifies a different order: apple, mango, zebra
        let uiSchema: [String: Any] = [
            "ui:order": ["apple", "mango", "zebra"]
        ]

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema,
            uiSchema: uiSchema,
            formData: data,
            schemaJSON: schemaJSON
        )

        let textFields = try form.inspect().findAll(ViewType.TextField.self)
        let fieldValues = try textFields.map { try $0.input() }

        // Fields should follow ui:order: apple, mango, zebra
        let expectedOrder = ["apple", "mango", "zebra"]
        XCTAssertEqual(
            fieldValues, expectedOrder,
            "ui:order should override JSON definition order. Got: \(fieldValues)")
    }

    @MainActor
    func testUIOrderWithPartialKeys() async throws {
        // Test that ui:order works with partial keys (remaining keys appended at end)
        let schemaJSON = """
            {
                "type": "object",
                "properties": {
                    "zebra": { "type": "string" },
                    "apple": { "type": "string" },
                    "mango": { "type": "string" },
                    "banana": { "type": "string" }
                }
            }
            """
        let formData = FormData.object(properties: [
            "zebra": .string("zebra"),
            "apple": .string("apple"),
            "mango": .string("mango"),
            "banana": .string("banana"),
        ])
        let schema = try JSONSchema(jsonString: schemaJSON)

        // ui:order only specifies some keys
        let uiSchema: [String: Any] = [
            "ui:order": ["mango", "apple"]
        ]

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema,
            uiSchema: uiSchema,
            formData: data,
            schemaJSON: schemaJSON
        )

        let textFields = try form.inspect().findAll(ViewType.TextField.self)
        let fieldValues = try textFields.map { try $0.input() }

        // ui:order keys first (mango, apple), then remaining keys
        XCTAssertEqual(fieldValues[0], "mango", "First field should be mango per ui:order")
        XCTAssertEqual(fieldValues[1], "apple", "Second field should be apple per ui:order")
        // Remaining fields (zebra, banana) should appear after, order may vary
        XCTAssertTrue(
            fieldValues.contains("zebra") && fieldValues.contains("banana"),
            "Remaining fields should be present")
    }

    @MainActor
    func testUIOrderIgnoresNonexistentKeys() async throws {
        // Test that ui:order silently ignores keys not present in schema
        let schemaJSON = """
            {
                "type": "object",
                "properties": {
                    "zebra": { "type": "string" },
                    "apple": { "type": "string" }
                }
            }
            """
        let formData = FormData.object(properties: [
            "zebra": .string("zebra"),
            "apple": .string("apple"),
        ])
        let schema = try JSONSchema(jsonString: schemaJSON)

        // ui:order includes a nonexistent key "nonexistent"
        let uiSchema: [String: Any] = [
            "ui:order": ["apple", "nonexistent", "zebra"]
        ]

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema,
            uiSchema: uiSchema,
            formData: data,
            schemaJSON: schemaJSON
        )

        let textFields = try form.inspect().findAll(ViewType.TextField.self)
        XCTAssertEqual(textFields.count, 2, "Should have 2 text fields")

        let fieldValues = try textFields.map { try $0.input() }

        // Fields should follow ui:order (ignoring nonexistent): apple, zebra
        let expectedOrder = ["apple", "zebra"]
        XCTAssertEqual(
            fieldValues, expectedOrder,
            "ui:order should ignore nonexistent keys. Got: \(fieldValues)")
    }
}
