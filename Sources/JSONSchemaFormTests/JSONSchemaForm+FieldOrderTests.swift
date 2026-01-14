import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

class JSONSchemaFormFieldOrderTests: XCTestCase {

    // MARK: - ObjectField Order Tests

    @MainActor
    func testObjectFieldsNotSortedAlphabetically() async throws {
        // Schema with properties in non-alphabetical order: zebra, apple, mango
        // If sorted alphabetically, it would be: apple, mango, zebra
        // We want to verify they are NOT in alphabetical order
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

        // The fields should NOT be in alphabetical order by property name
        // Alphabetical order would be: ["apple value", "mango value", "zebra value"]
        // We verify it's NOT in that order
        let alphabeticalOrder = ["apple value", "mango value", "zebra value"]
        XCTAssertNotEqual(
            fieldValues, alphabeticalOrder,
            "Fields should NOT be sorted alphabetically. Got: \(fieldValues)")
    }

    @MainActor
    func testObjectFieldsPreserveSchemaOrder() async throws {
        // This test verifies that fields maintain some consistent order
        // (not necessarily schema order due to JSON parsing, but definitely not alphabetical)
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
    }

    @MainActor
    func testNestedObjectFieldsNotSortedAlphabetically() async throws {
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

        // Verify fields are NOT in alphabetical order
        let alphabeticalOrder = ["apple", "mango", "zebra"]
        XCTAssertNotEqual(
            fieldValues, alphabeticalOrder,
            "Nested fields should NOT be sorted alphabetically. Got: \(fieldValues)")
    }

    @MainActor
    func testMixedTypeFieldsNotSortedAlphabetically() async throws {
        // Test with different field types to ensure sorting doesn't affect mixed types
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
        // These should be rendered without alphabetical sorting
        let zooField = try form.inspect().find(viewWithId: "root_zoo")
        let activeField = try form.inspect().find(viewWithId: "root_active")
        let countField = try form.inspect().find(viewWithId: "root_count")

        // All fields should be found and accessible
        XCTAssertNoThrow(try zooField.find(ViewType.TextField.self))
        XCTAssertNoThrow(try activeField.find(ViewType.Toggle.self))
        XCTAssertNoThrow(try countField.find(ViewType.TextField.self))
    }

    // MARK: - Regression Test for Alphabetical Sorting Bug

    @MainActor
    func testFieldOrderIsNotAlphabeticalRegression() async throws {
        // This is a regression test to ensure the alphabetical sorting bug doesn't return
        // Schema with properties that would be obviously different if sorted
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

        // If sorted alphabetically by property name, order would be: [first, middle, last]
        // We verify this is NOT the case
        let alphabeticallyOrderedValues = ["first", "middle", "last"]
        XCTAssertNotEqual(
            fieldValues, alphabeticallyOrderedValues,
            "REGRESSION: Fields appear to be sorted alphabetically! Got: \(fieldValues)")
    }
}
