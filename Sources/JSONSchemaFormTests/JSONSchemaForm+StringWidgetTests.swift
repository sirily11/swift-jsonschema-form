import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

class JSONSchemaFormStringWidgetTests: XCTestCase {

    // MARK: - Default Widget Tests

    @MainActor
    func testDefaultStringRendersTextWidget() async throws {
        let formData = FormData.object(properties: [
            "name": .string("John")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "name": { "type": "string" }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify TextWidget renders with correct ID suffix
        let textWidget = try form.inspect().find(viewWithId: "root_name_text")
        XCTAssertNotNil(textWidget)

        // Verify it's a TextField
        let textField = try textWidget.find(ViewType.TextField.self)
        let input = try textField.input()
        XCTAssertEqual(input, "John")
    }

    // MARK: - ui:widget Tests

    @MainActor
    func testTextareaWidgetRendersTextEditor() async throws {
        let formData = FormData.object(properties: [
            "bio": .string("My biography")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "bio": { "type": "string" }
                    }
                }
                """)

        let uiSchema: [String: Any] = [
            "bio": ["ui:widget": "textarea"]
        ]

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema,
            uiSchema: uiSchema,
            formData: data
        )

        // Verify TextAreaWidget renders with correct ID suffix
        let textareaWidget = try form.inspect().find(viewWithId: "root_bio_textarea")
        XCTAssertNotNil(textareaWidget)

        // Verify it's a TextEditor
        let textEditor = try textareaWidget.find(ViewType.TextEditor.self)
        XCTAssertNotNil(textEditor)
    }

    @MainActor
    func testPasswordWidgetRendersSecureField() async throws {
        let formData = FormData.object(properties: [
            "password": .string("secret123")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "password": { "type": "string" }
                    }
                }
                """)

        let uiSchema: [String: Any] = [
            "password": ["ui:widget": "password"]
        ]

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema,
            uiSchema: uiSchema,
            formData: data
        )

        // Verify PasswordWidget renders with correct ID suffix
        let passwordWidget = try form.inspect().find(viewWithId: "root_password_password")
        XCTAssertNotNil(passwordWidget)

        // Verify it contains a SecureField (default state is secured)
        let secureField = try passwordWidget.find(ViewType.SecureField.self)
        XCTAssertNotNil(secureField)
    }

    @MainActor
    func testColorWidgetRendersColorPicker() async throws {
        let formData = FormData.object(properties: [
            "favoriteColor": .string("#FF0000")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "favoriteColor": { "type": "string" }
                    }
                }
                """)

        let uiSchema: [String: Any] = [
            "favoriteColor": ["ui:widget": "color"]
        ]

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema,
            uiSchema: uiSchema,
            formData: data
        )

        // Verify ColorWidget renders with correct ID suffix
        let colorWidget = try form.inspect().find(viewWithId: "root_favoriteColor_color")
        XCTAssertNotNil(colorWidget)

        // Verify it's a ColorPicker
        let colorPicker = try colorWidget.find(ViewType.ColorPicker.self)
        XCTAssertNotNil(colorPicker)
    }

    // MARK: - format Tests

    @MainActor
    func testEmailFormatRendersEmailWidget() async throws {
        let formData = FormData.object(properties: [
            "email": .string("test@example.com")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "email": {
                            "type": "string",
                            "format": "email"
                        }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify EmailWidget renders with correct ID suffix
        let emailWidget = try form.inspect().find(viewWithId: "root_email_email")
        XCTAssertNotNil(emailWidget)

        // Verify it's a TextField
        let textField = try emailWidget.find(ViewType.TextField.self)
        let input = try textField.input()
        XCTAssertEqual(input, "test@example.com")
    }

    @MainActor
    func testUriFormatRendersURLWidget() async throws {
        let formData = FormData.object(properties: [
            "website": .string("https://example.com")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "website": {
                            "type": "string",
                            "format": "uri"
                        }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify URLWidget renders with correct ID suffix
        let urlWidget = try form.inspect().find(viewWithId: "root_website_url")
        XCTAssertNotNil(urlWidget)

        // Verify it's a TextField
        let textField = try urlWidget.find(ViewType.TextField.self)
        let input = try textField.input()
        XCTAssertEqual(input, "https://example.com")
    }

    @MainActor
    func testDateTimeFormatRendersDateTimePicker() async throws {
        let formData = FormData.object(properties: [
            "appointment": .string("2024-01-15T10:30:00Z")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "appointment": {
                            "type": "string",
                            "format": "date-time"
                        }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify DateTimeWidget renders with correct ID suffix
        let datetimeWidget = try form.inspect().find(viewWithId: "root_appointment_datetime")
        XCTAssertNotNil(datetimeWidget)

        // Verify it's a DatePicker
        let datePicker = try datetimeWidget.find(ViewType.DatePicker.self)
        XCTAssertNotNil(datePicker)
    }

    @MainActor
    func testDateFormatRendersDatePicker() async throws {
        let formData = FormData.object(properties: [
            "birthday": .string("2000-01-15")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "birthday": {
                            "type": "string",
                            "format": "date"
                        }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify DateWidget renders with correct ID suffix
        let dateWidget = try form.inspect().find(viewWithId: "root_birthday_date")
        XCTAssertNotNil(dateWidget)

        // Verify it's a DatePicker
        let datePicker = try dateWidget.find(ViewType.DatePicker.self)
        XCTAssertNotNil(datePicker)
    }

    // MARK: - Edge Case Tests

    @MainActor
    func testWidgetOverridesFormat() async throws {
        // When both ui:widget and format are specified, ui:widget should take precedence
        let formData = FormData.object(properties: [
            "field": .string("test@example.com")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "field": {
                            "type": "string",
                            "format": "email"
                        }
                    }
                }
                """)

        let uiSchema: [String: Any] = [
            "field": ["ui:widget": "textarea"]
        ]

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema,
            uiSchema: uiSchema,
            formData: data
        )

        // ui:widget="textarea" should override format="email"
        // Should find textarea widget, not email widget
        let textareaWidget = try form.inspect().find(viewWithId: "root_field_textarea")
        XCTAssertNotNil(textareaWidget)

        // Verify it's a TextEditor (not TextField which email would render)
        let textEditor = try textareaWidget.find(ViewType.TextEditor.self)
        XCTAssertNotNil(textEditor)

        // Email widget should NOT be present
        XCTAssertThrowsError(try form.inspect().find(viewWithId: "root_field_email"))
    }

    @MainActor
    func testUnknownFormatRendersTextWidget() async throws {
        // Unknown formats should fall back to default TextWidget
        let formData = FormData.object(properties: [
            "field": .string("some value")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "field": {
                            "type": "string",
                            "format": "unknown-format"
                        }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Unknown format should fall back to TextWidget
        let textWidget = try form.inspect().find(viewWithId: "root_field_text")
        XCTAssertNotNil(textWidget)

        // Verify it's a TextField
        let textField = try textWidget.find(ViewType.TextField.self)
        let input = try textField.input()
        XCTAssertEqual(input, "some value")
    }
}
