import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

class JSONSchemaFormObjectTests: XCTestCase {
    @MainActor
    func testSimpleObject() async throws {
        let formData = FormData.object(properties: [
            "name": .string("John"),
            "age": .number(25)
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "name": { "type": "string" },
                        "age": { "type": "number" }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Find the fields
        let nameTextField = try form.inspect().find(viewWithId: "root_name").find(ViewType.TextField.self)
        let ageTextField = try form.inspect().find(viewWithId: "root_age").find(ViewType.TextField.self)

        // Get the values
        let name = try nameTextField.input()
        let age = try ageTextField.input()

        // Assert values match
        XCTAssertEqual(name, "John")
        XCTAssertEqual(age, "25")
    }

    @MainActor
    func testNestedObject() async throws {
        let formData = FormData.object(properties: [
            "person": .object(properties: [
                "name": .string("Jane"),
                "address": .object(properties: [
                    "city": .string("New York"),
                    "street": .string("123 Main St")
                ])
            ])
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "person": {
                            "type": "object",
                            "properties": {
                                "name": { "type": "string" },
                                "address": {
                                    "type": "object",
                                    "properties": {
                                        "city": { "type": "string" },
                                        "street": { "type": "string" }
                                    }
                                }
                            }
                        }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Find the nested fields
        let nameTextField = try form.inspect().find(viewWithId: "root_person_name").find(ViewType.TextField.self)
        let cityTextField = try form.inspect().find(viewWithId: "root_person_address_city").find(ViewType.TextField.self)
        let streetTextField = try form.inspect().find(viewWithId: "root_person_address_street").find(ViewType.TextField.self)

        // Get the values
        let name = try nameTextField.input()
        let city = try cityTextField.input()
        let street = try streetTextField.input()

        // Assert values match
        XCTAssertEqual(name, "Jane")
        XCTAssertEqual(city, "New York")
        XCTAssertEqual(street, "123 Main St")
    }

    @MainActor
    func testObjectWithRequiredProperties() async throws {
        let formData = FormData.object(properties: [
            "email": .string("test@example.com"),
            "nickname": .string("tester")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "email": { "type": "string" },
                        "nickname": { "type": "string" }
                    },
                    "required": ["email"]
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Find the fields
        let emailTextField = try form.inspect().find(viewWithId: "root_email").find(ViewType.TextField.self)
        let nicknameTextField = try form.inspect().find(viewWithId: "root_nickname").find(ViewType.TextField.self)

        // Get the values
        let email = try emailTextField.input()
        let nickname = try nicknameTextField.input()

        // Assert values match
        XCTAssertEqual(email, "test@example.com")
        XCTAssertEqual(nickname, "tester")
    }

    @MainActor
    func testObjectPropertyEdit() async throws {
        let formData = FormData.object(properties: [
            "title": .string("Original Title")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "title": { "type": "string" }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Find the text field and custom field wrapper
        let textField = try form.inspect().find(viewWithId: "root_title").find(ViewType.TextField.self)
        let customField = try form.inspect().find(viewWithId: "root_title_string_field")

        // Set new input and trigger onChange
        try textField.setInput("Updated Title")
        try customField.callOnChange(oldValue: "Original Title", newValue: "Updated Title")

        // Assert binding was updated
        XCTAssertEqual(data.wrappedValue.object?["title"], .string("Updated Title"))
    }

    @MainActor
    func testEmptyObject() async throws {
        let formData = FormData.object(properties: [:])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "optional": { "type": "string" }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Should render without errors - find the optional field with default value
        let optionalTextField = try form.inspect().find(viewWithId: "root_optional").find(ViewType.TextField.self)
        let text = try optionalTextField.input()

        // Empty string is the default for string fields
        XCTAssertEqual(text, "")
    }
}
