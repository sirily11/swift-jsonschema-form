import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

class JSONSchemaFormStringTests: XCTestCase {
    @MainActor
    func testDefaultFormDataString() async throws {
        let formData = FormData.object(properties: [
            "name": .string("Jane")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "name": { "type": "string" }
                    },
                    "required": ["name"]
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema, formData: data)
        // find the text field
        let textField = try form.inspect().find(viewWithId: "root_name").textField()
        // get the text
        let text = try textField.input()
        // assert text is Jane
        XCTAssertEqual(text, "Jane")
    }

    @MainActor
    func testDefaultSchemaString() async throws {
        let formData = FormData.object(properties: [:])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "name": { 
                            "type": "string",
                            "default": "Jane"
                        }
                    },
                    "required": ["name"]
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema, formData: data)
        // find the text field
        let textField = try form.inspect().find(viewWithId: "root_name").textField()
        // get the text
        let text = try textField.input()
        // assert text is Jane
        XCTAssertEqual(text, "Jane")
    }

    @MainActor
    func testNestedString() async throws {
        let formData = FormData.object(properties: [
            "name": .string("Jane"),
            "address": .object(properties: [
                "street": .string("123 Main St"),
                "city": .string("Anytown"),
            ]),
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "name": { "type": "string" },
                        "address": {
                            "type": "object",
                            "properties": {
                                "street": { "type": "string" },
                                "city": { "type": "string" }
                            }
                        },
                    },
                    "required": ["name"]
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema, formData: data)
        // find the text field
        let nameTextField = try form.inspect().find(viewWithId: "root_name").textField()
        let addressTextField = try form.inspect().find(viewWithId: "root_address_city").textField()
        let customField = try form.inspect().find(viewWithId: "root_address_city_string_field")
        // get the text
        let address = try addressTextField.input()
        let name = try nameTextField.input()
        XCTAssertEqual(address, "Anytown")
        XCTAssertEqual(name, "Jane")
        try customField.callOnChange(oldValue: "Anytown", newValue: "Newtown")
        XCTAssertEqual(data.wrappedValue.object?["address"]?.object?["city"], .string("Newtown"))
    }

    @MainActor
    func testEditString() async throws {
        let formData = FormData.object(properties: [
            "name": .string("John")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "name": { "type": "string" }
                    },
                    "required": ["name"]
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema, formData: data)
        // find the text field
        let textField = try form.inspect().find(viewWithId: "root_name").textField()
        let customField = try form.inspect().find(viewWithId: "root_name_string_field")
        // enter text
        try textField.setInput("Jane")
        // call onChange
        try customField.callOnChange(oldValue: "John", newValue: "Jane")
        XCTAssertEqual(data.wrappedValue.object?["name"], .string("Jane"))
    }
}
