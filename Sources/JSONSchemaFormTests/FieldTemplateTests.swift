import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

class FieldTemplateTests: XCTestCase {
    // MARK: - Basic Rendering Tests

    @MainActor
    func testFieldTemplateRendersContent() throws {
        let template = FieldTemplate(
            id: "test_field",
            label: "Test Label",
            displayLabel: true
        ) {
            Text("Test Content")
        }

        let vStack = try template.inspect().find(ViewType.VStack.self)
        let text = try vStack.find(text: "Test Content")
        XCTAssertNotNil(text)
    }

    @MainActor
    func testFieldTemplateHasCorrectId() throws {
        let template = FieldTemplate(
            id: "my_unique_id",
            label: "Test Label"
        ) {
            Text("Content")
        }

        let vStack = try template.inspect().find(ViewType.VStack.self)
        let id = try vStack.id()
        XCTAssertEqual(id as? String, "my_unique_id")
    }

    // MARK: - Hidden State Tests

    @MainActor
    func testFieldTemplateHiddenRendersNothing() throws {
        let template = FieldTemplate(
            id: "hidden_field",
            label: "Hidden Label",
            hidden: true
        ) {
            Text("Should Not Appear")
        }

        // When hidden, the VStack should not be present
        XCTAssertThrowsError(try template.inspect().find(ViewType.VStack.self))
    }

    @MainActor
    func testFieldTemplateNotHiddenRendersContent() throws {
        let template = FieldTemplate(
            id: "visible_field",
            label: "Visible Label",
            hidden: false
        ) {
            Text("Should Appear")
        }

        let text = try template.inspect().find(text: "Should Appear")
        XCTAssertNotNil(text)
    }

    // MARK: - Description Tests

    @MainActor
    func testFieldTemplateDisplaysDescription() throws {
        let template = FieldTemplate(
            id: "field_with_description",
            label: "Test Label",
            description: "This is a helpful description"
        ) {
            Text("Content")
        }

        let description = try template.inspect().find(text: "This is a helpful description")
        XCTAssertNotNil(description)
    }

    @MainActor
    func testFieldTemplateHidesEmptyDescription() throws {
        let template = FieldTemplate(
            id: "field_no_description",
            label: "Test Label",
            description: ""
        ) {
            Text("Content")
        }

        // Empty description should not render - only content text should be present
        let texts = try template.inspect().findAll(ViewType.Text.self)
        let textStrings = texts.compactMap { try? $0.string() }
        XCTAssertTrue(textStrings.contains("Content"))
        XCTAssertFalse(textStrings.contains(""))
        XCTAssertEqual(textStrings.count, 1)
    }

    @MainActor
    func testFieldTemplateNilDescription() throws {
        let template = FieldTemplate(
            id: "field_nil_description",
            label: "Test Label",
            description: nil
        ) {
            Text("Content")
        }

        // Only the content text should be present, not a description
        let texts = try template.inspect().findAll(ViewType.Text.self)
        let textStrings = texts.compactMap { try? $0.string() }
        XCTAssertTrue(textStrings.contains("Content"))
        XCTAssertEqual(textStrings.count, 1)
    }

    // MARK: - Error Display Tests

    @MainActor
    func testFieldTemplateDisplaysSingleError() throws {
        let template = FieldTemplate(
            id: "field_with_error",
            label: "Test Label",
            errors: ["This field is required"]
        ) {
            Text("Content")
        }

        let errorText = try template.inspect().find(text: "This field is required")
        XCTAssertNotNil(errorText)
    }

    @MainActor
    func testFieldTemplateDisplaysMultipleErrors() throws {
        let errors = ["Error 1", "Error 2", "Error 3"]
        let template = FieldTemplate(
            id: "field_with_errors",
            label: "Test Label",
            errors: errors
        ) {
            Text("Content")
        }

        for error in errors {
            let errorText = try template.inspect().find(text: error)
            XCTAssertNotNil(errorText)
        }
    }

    @MainActor
    func testFieldTemplateNoErrorsWhenEmpty() throws {
        let template = FieldTemplate(
            id: "field_no_errors",
            label: "Test Label",
            errors: []
        ) {
            Text("Content")
        }

        // Should only have the content text
        let texts = try template.inspect().findAll(ViewType.Text.self)
        XCTAssertEqual(texts.count, 1)
    }

    @MainActor
    func testFieldTemplateNoErrorsWhenNil() throws {
        let template = FieldTemplate(
            id: "field_nil_errors",
            label: "Test Label",
            errors: nil
        ) {
            Text("Content")
        }

        let texts = try template.inspect().findAll(ViewType.Text.self)
        XCTAssertEqual(texts.count, 1)
    }

    // MARK: - Help Text Tests

    @MainActor
    func testFieldTemplateDisplaysHelpText() throws {
        let template = FieldTemplate(
            id: "field_with_help",
            label: "Test Label",
            help: "Click here for more info"
        ) {
            Text("Content")
        }

        let helpText = try template.inspect().find(text: "Click here for more info")
        XCTAssertNotNil(helpText)
    }

    @MainActor
    func testFieldTemplateHidesEmptyHelpText() throws {
        let template = FieldTemplate(
            id: "field_empty_help",
            label: "Test Label",
            help: ""
        ) {
            Text("Content")
        }

        let texts = try template.inspect().findAll(ViewType.Text.self)
        XCTAssertEqual(texts.count, 1)
    }

    // MARK: - Combined Fields Tests

    @MainActor
    func testFieldTemplateWithDescriptionAndHelp() throws {
        let template = FieldTemplate(
            id: "full_field",
            label: "Full Field",
            description: "Field description",
            help: "Help text"
        ) {
            Text("Content")
        }

        let description = try template.inspect().find(text: "Field description")
        let help = try template.inspect().find(text: "Help text")
        let content = try template.inspect().find(text: "Content")

        XCTAssertNotNil(description)
        XCTAssertNotNil(help)
        XCTAssertNotNil(content)
    }

    @MainActor
    func testFieldTemplateWithAllElements() throws {
        let template = FieldTemplate(
            id: "complete_field",
            label: "Complete Field",
            description: "Description text",
            errors: ["Error message"],
            help: "Help text"
        ) {
            Text("Content")
        }

        let texts = try template.inspect().findAll(ViewType.Text.self)
        let textStrings = texts.compactMap { try? $0.string() }

        XCTAssertTrue(textStrings.contains("Content"))
        XCTAssertTrue(textStrings.contains("Description text"))
        XCTAssertTrue(textStrings.contains("Error message"))
        XCTAssertTrue(textStrings.contains("Help text"))
    }

    // MARK: - Required/Readonly Tests

    @MainActor
    func testFieldTemplateReadonlyDisablesContent() throws {
        let template = FieldTemplate(
            id: "readonly_field",
            label: "Readonly Field",
            readonly: true
        ) {
            TextField("Placeholder", text: .constant("Value"))
        }

        let textField = try template.inspect().find(ViewType.TextField.self)
        let isDisabled = textField.isDisabled()
        XCTAssertTrue(isDisabled)
    }

    @MainActor
    func testFieldTemplateNotReadonlyEnablesContent() throws {
        let template = FieldTemplate(
            id: "editable_field",
            label: "Editable Field",
            readonly: false
        ) {
            TextField("Placeholder", text: .constant("Value"))
        }

        let textField = try template.inspect().find(ViewType.TextField.self)
        let isDisabled = textField.isDisabled()
        XCTAssertFalse(isDisabled)
    }

    // MARK: - Default Values Tests

    @MainActor
    func testFieldTemplateDefaultValues() throws {
        let template = FieldTemplate(
            id: "default_field",
            label: "Default Field"
        ) {
            Text("Content")
        }

        // Should render (not hidden by default)
        let content = try template.inspect().find(text: "Content")
        XCTAssertNotNil(content)

        // Only content text should be present (no description, errors, or help)
        let texts = try template.inspect().findAll(ViewType.Text.self)
        XCTAssertEqual(texts.count, 1)
    }
}
