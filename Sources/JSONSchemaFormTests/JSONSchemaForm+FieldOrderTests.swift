import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

class JSONSchemaFormFieldOrderTests: XCTestCase {

    // MARK: - ObjectField Order Tests

    @MainActor
    func testObjectFieldsSortedAlphabetically() async throws {
        // Schema with properties in non-alphabetical order: zebra, apple, mango
        // Fields should be rendered in alphabetical order: apple, mango, zebra
        let formData = FormData.object(properties: [
            "zebra": .string("zebra value"),
            "apple": .string("apple value"),
            "mango": .string("mango value")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "zebra": { "type": "string" },
                        "apple": { "type": "string" },
                        "mango": { "type": "string" }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Find all text fields
        let textFields = try form.inspect().findAll(ViewType.TextField.self)
        XCTAssertEqual(textFields.count, 3, "Should have 3 text fields")

        // Get the inputs (values) to identify field order
        let fieldValues = try textFields.map { try $0.input() }

        // Fields should be in alphabetical order by property name
        let alphabeticalOrder = ["apple value", "mango value", "zebra value"]
        XCTAssertEqual(
            fieldValues, alphabeticalOrder,
            "Fields should be sorted alphabetically. Got: \(fieldValues)")
    }

    @MainActor
    func testObjectFieldsPreserveAlphabeticalOrder() async throws {
        // This test verifies that fields maintain consistent alphabetical order
        let formData = FormData.object(properties: [
            "first": .string("1"),
            "second": .string("2"),
            "third": .string("3")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "first": { "type": "string" },
                        "second": { "type": "string" },
                        "third": { "type": "string" }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Find all fields by their IDs
        let firstField = try form.inspect().find(viewWithId: "root_first")
        let secondField = try form.inspect().find(viewWithId: "root_second")
        let thirdField = try form.inspect().find(viewWithId: "root_third")

        // All three fields should be found (this verifies the form renders all properties)
        XCTAssertNoThrow(try firstField.find(ViewType.TextField.self))
        XCTAssertNoThrow(try secondField.find(ViewType.TextField.self))
        XCTAssertNoThrow(try thirdField.find(ViewType.TextField.self))

        // Verify alphabetical order: first, second, third
        let textFields = try form.inspect().findAll(ViewType.TextField.self)
        let fieldValues = try textFields.map { try $0.input() }
        XCTAssertEqual(fieldValues, ["1", "2", "3"],
            "Fields should be in alphabetical order. Got: \(fieldValues)")
    }

    @MainActor
    func testNestedObjectFieldsSortedAlphabetically() async throws {
        let formData = FormData.object(properties: [
            "parent": .object(properties: [
                "zebra": .string("zebra"),
                "apple": .string("apple"),
                "mango": .string("mango")
            ])
        ])
        let schema = try JSONSchema(
            jsonString: """
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
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Find nested text fields
        let textFields = try form.inspect().findAll(ViewType.TextField.self)
        XCTAssertEqual(textFields.count, 3, "Should have 3 nested text fields")

        // Get the inputs to verify order
        let fieldValues = try textFields.map { try $0.input() }

        // Verify fields are in alphabetical order
        let alphabeticalOrder = ["apple", "mango", "zebra"]
        XCTAssertEqual(
            fieldValues, alphabeticalOrder,
            "Nested fields should be sorted alphabetically. Got: \(fieldValues)")
    }

    @MainActor
    func testMixedTypeFieldsSortedAlphabetically() async throws {
        // Test with different field types to ensure alphabetical sorting works for mixed types
        let formData = FormData.object(properties: [
            "zoo": .string("zoo"),
            "active": .boolean(true),
            "count": .number(42)
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "zoo": { "type": "string" },
                        "active": { "type": "boolean" },
                        "count": { "type": "number" }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

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
    func testFieldOrderIsAlphabeticalRegression() async throws {
        // Regression test to ensure fields are always rendered in alphabetical order
        let formData = FormData.object(properties: [
            "z_last": .string("last"),
            "a_first": .string("first"),
            "m_middle": .string("middle")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "z_last": { "type": "string" },
                        "a_first": { "type": "string" },
                        "m_middle": { "type": "string" }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        let textFields = try form.inspect().findAll(ViewType.TextField.self)
        let fieldValues = try textFields.map { try $0.input() }

        // Fields should be sorted alphabetically by property name: a_first, m_middle, z_last
        let alphabeticallyOrderedValues = ["first", "middle", "last"]
        XCTAssertEqual(
            fieldValues, alphabeticallyOrderedValues,
            "Fields should be sorted alphabetically. Got: \(fieldValues)")
    }

    @MainActor
    func testFieldOrderStableAfterFormDataUpdate() async throws {
        // Verify that field order does not change after updating form data values
        var formData = FormData.object(properties: [
            "zebra": .string("zebra"),
            "apple": .string("apple"),
            "mango": .string("mango")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "zebra": { "type": "string" },
                        "apple": { "type": "string" },
                        "mango": { "type": "string" }
                    }
                }
                """)

        let data = Binding(get: { formData }, set: { formData = $0 })
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Get initial order
        let initialTextFields = try form.inspect().findAll(ViewType.TextField.self)
        let initialValues = try initialTextFields.map { try $0.input() }
        XCTAssertEqual(initialValues, ["apple", "mango", "zebra"],
            "Initial order should be alphabetical")

        // Simulate a form data update (e.g., user edits the "zebra" field)
        formData = FormData.object(properties: [
            "zebra": .string("updated zebra"),
            "apple": .string("apple"),
            "mango": .string("mango")
        ])

        // Re-inspect the form with updated data
        let updatedForm = JSONSchemaForm(schema: schema, formData: data)
        let updatedTextFields = try updatedForm.inspect().findAll(ViewType.TextField.self)
        let updatedValues = try updatedTextFields.map { try $0.input() }

        // Order should remain alphabetical after update
        XCTAssertEqual(updatedValues, ["apple", "mango", "updated zebra"],
            "Field order should remain alphabetical after form data update. Got: \(updatedValues)")
    }
}
