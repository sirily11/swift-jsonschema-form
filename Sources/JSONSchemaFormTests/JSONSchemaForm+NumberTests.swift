import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

class JSONSchemaFormNumberTests: XCTestCase {
    @MainActor
    func testDefaultFormDataNumber() async throws {
        let formData = FormData.object(properties: [
            "age": .number(25),
        ])
        let schema = try JSONSchema(
            jsonString: """
            {
                "type": "object",
                "properties": {
                    "age": { "type": "number" }
                },
                "required": ["age"]
            }
            """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema, formData: data)

        // find the text field
        let textField = try form.inspect().find(viewWithId: "root_age").textField()
        // get the text
        let text = try textField.input()
        // assert text is "25.0" (decimal representation)
        XCTAssertEqual(text, "25")
    }

    @MainActor
    func testDefaultSchemaNumber() async throws {
        let formData = FormData.object(properties: [:])
        let schema = try JSONSchema(
            jsonString: """
            {
                "type": "object",
                "properties": {
                    "age": { 
                        "type": "number",
                        "default": 30
                    }
                },
                "required": ["age"]
            }
            """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema, formData: data)

        // find the text field
        let textField = try form.inspect().find(viewWithId: "root_age").textField()
        // get the text
        let text = try textField.input()
        // assert text is "30.0" (decimal representation)
        XCTAssertEqual(text, "30")
    }

    @MainActor
    func testNestedNumber() async throws {
        let formData = FormData.object(properties: [
            "name": .string("Jane"),
            "stats": .object(properties: [
                "age": .number(25),
                "height": .number(175.5),
            ]),
        ])
        let schema = try JSONSchema(
            jsonString: """
            {
                "type": "object",
                "properties": {
                    "name": { "type": "string" },
                    "stats": {
                        "type": "object",
                        "properties": {
                            "age": { "type": "number" },
                            "height": { "type": "number" }
                        }
                    }
                },
                "required": ["name"]
            }
            """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema, formData: data)

        // find the text fields
        let ageTextField = try form.inspect().find(viewWithId: "root_stats_age").textField()
        let heightTextField = try form.inspect().find(viewWithId: "root_stats_height").textField()

        // get the text values
        let age = try ageTextField.input()
        let height = try heightTextField.input()

        // assert values
        XCTAssertEqual(age, "25")
        XCTAssertEqual(height, "176")
    }

    @MainActor
    func testEditNumber() async throws {
        let formData = FormData.object(properties: [
            "age": .number(25),
        ])
        let schema = try JSONSchema(
            jsonString: """
            {
                "type": "object",
                "properties": {
                    "age": { "type": "number" }
                },
                "required": ["age"]
            }
            """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema, formData: data)

        // find the text field and the onChange handler view
        let textField = try form.inspect().find(viewWithId: "root_age").textField()
        let vStack = try form.inspect().find(ViewType.VStack.self) { view in
            do {
                let id = try view.id()
                if let stringId = id as? String, stringId.contains("number_field") {
                    return true
                }
                return false
            } catch {
                return false
            }
        }

        // set new value
        try textField.setInput("30")
        // call onChange
        try vStack.callOnChange(oldValue: 25.0, newValue: 30.0)

        // verify the data changed
        XCTAssertEqual(data.wrappedValue.object?["age"], .number(30.0))
    }
}
