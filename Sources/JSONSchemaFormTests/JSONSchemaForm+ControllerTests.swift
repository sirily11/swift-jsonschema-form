import JSONSchema
import JSONSchemaValidator
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

/// Integration tests for JSONSchemaForm with JSONSchemaFormController
class JSONSchemaFormControllerIntegrationTests: XCTestCase {

    // MARK: - Form with Internal Controller Tests

    @MainActor
    func testFormCreatesInternalController() async throws {
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "name": { "type": "string" }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "name": .string("John")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        // Create form without external controller
        let form = JSONSchemaForm(
            schema: schema,
            formData: binding,
            showSubmitButton: false
        )

        // The form should work without an external controller
        let textField = try form.inspect().find(viewWithId: "root_name").find(ViewType.TextField.self)
        let text = try textField.input()
        XCTAssertEqual(text, "John")
    }

    // MARK: - Form with External Controller Tests

    @MainActor
    func testFormWithExternalController() async throws {
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "name": { "type": "string" }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "name": .string("Jane")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        // Create external controller
        let controller = JSONSchemaFormController()

        let form = JSONSchemaForm(
            schema: schema,
            formData: binding,
            showSubmitButton: false,
            controller: controller
        )

        // Form should work with external controller
        let textField = try form.inspect().find(viewWithId: "root_name").find(ViewType.TextField.self)
        let text = try textField.input()
        XCTAssertEqual(text, "Jane")
    }

    @MainActor
    func testExternalControllerValidation() async throws {
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["name"],
                    "properties": {
                        "name": {
                            "type": "string",
                            "minLength": 3
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "name": .string("Jo")  // Too short
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let controller = JSONSchemaFormController()

        // Configure controller manually (simulating what the form does)
        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        // Validate using the controller
        let isValid = controller.validate()

        XCTAssertFalse(isValid, "Validation should fail with short name")
        XCTAssertFalse(controller.isValid, "Controller should report invalid")
        XCTAssertFalse(controller.errors.isEmpty, "Controller should have errors")
    }

    @MainActor
    func testExternalControllerSubmit() async throws {
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "username": { "type": "string" }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "username": .string("testuser")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let controller = JSONSchemaFormController()
        var submitSuccessCalled = false
        var receivedFormData: FormData?

        controller.onSubmitSuccess = { data in
            submitSuccessCalled = true
            receivedFormData = data
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        // Submit programmatically
        let success = try await controller.submit()

        XCTAssertTrue(success, "Submit should succeed")
        XCTAssertTrue(submitSuccessCalled, "onSubmitSuccess should be called")
        XCTAssertNotNil(receivedFormData, "Should receive form data")
    }

    // MARK: - Live Validation Integration Tests

    @MainActor
    func testLiveValidationUpdatesErrors() async throws {
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "email": {
                            "type": "string",
                            "minLength": 5
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "email": .string("ab")  // Too short
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let controller = JSONSchemaFormController()

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: true,
            customValidate: nil,
            transformErrors: nil
        )

        // Simulate form data change (what happens when user types)
        controller.handleFormDataChange()

        XCTAssertFalse(controller.isValid, "Should be invalid after live validation")
        XCTAssertFalse(controller.errors.isEmpty, "Should have errors after live validation")
    }

    @MainActor
    func testLiveValidationClearsOnValidInput() async throws {
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "name": {
                            "type": "string",
                            "minLength": 3
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "name": .string("Jo")  // Too short initially
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let controller = JSONSchemaFormController()

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: true,
            customValidate: nil,
            transformErrors: nil
        )

        // First validation with invalid data
        controller.handleFormDataChange()
        XCTAssertFalse(controller.isValid, "Should be invalid with short name")

        // Update form data to valid value
        formData = FormData.object(properties: [
            "name": .string("John")  // Now valid
        ])

        // Trigger validation again
        controller.handleFormDataChange()
        XCTAssertTrue(controller.isValid, "Should be valid with long enough name")
        XCTAssertTrue(controller.errors.isEmpty, "Errors should be cleared")
    }

    // MARK: - Error Callback Integration Tests

    @MainActor
    func testErrorCallbackTriggeredOnValidation() async throws {
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["password"],
                    "properties": {
                        "password": {
                            "type": "string",
                            "minLength": 8
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "password": .string("short")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let controller = JSONSchemaFormController()
        var errorCallbackTriggered = false
        var receivedErrors: [ValidationError] = []

        controller.onValidationError = { errors in
            errorCallbackTriggered = true
            receivedErrors = errors
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        _ = controller.validate()

        XCTAssertTrue(errorCallbackTriggered, "Error callback should be triggered")
        XCTAssertFalse(receivedErrors.isEmpty, "Should receive errors in callback")
    }

    // MARK: - Form State Management Tests

    @MainActor
    func testControllerStateAfterMultipleValidations() async throws {
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "value": {
                            "type": "string",
                            "minLength": 3
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "value": .string("ab")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let controller = JSONSchemaFormController()

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        // First validation - invalid
        _ = controller.validate()
        XCTAssertFalse(controller.isValid)
        let firstErrorCount = controller.errors.count

        // Second validation - still invalid
        _ = controller.validate()
        XCTAssertFalse(controller.isValid)
        XCTAssertEqual(controller.errors.count, firstErrorCount, "Error count should be consistent")

        // Update to valid data
        formData = FormData.object(properties: [
            "value": .string("abc")
        ])

        // Third validation - valid
        _ = controller.validate()
        XCTAssertTrue(controller.isValid)
        XCTAssertTrue(controller.errors.isEmpty)
    }

    // MARK: - Field Error Display Tests

    @MainActor
    func testFieldErrorsAreAccessible() async throws {
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "username": {
                            "type": "string",
                            "minLength": 5
                        },
                        "age": {
                            "type": "integer",
                            "minimum": 0
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "username": .string("ab"),  // Too short
            "age": .number(-5)  // Negative
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let controller = JSONSchemaFormController()

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        _ = controller.validate()

        // Field errors should be mapped
        XCTAssertFalse(controller.fieldErrors.isEmpty, "Should have field-level errors")
    }

    // MARK: - Complex Schema Tests

    @MainActor
    func testNestedObjectErrors() async throws {
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "user": {
                            "type": "object",
                            "required": ["email"],
                            "properties": {
                                "email": {
                                    "type": "string",
                                    "format": "email"
                                },
                                "profile": {
                                    "type": "object",
                                    "properties": {
                                        "bio": {
                                            "type": "string",
                                            "maxLength": 100
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "user": .object(properties: [
                "email": .string("invalid-email"),
                "profile": .object(properties: [
                    "bio": .string(String(repeating: "a", count: 150))  // Too long
                ])
            ])
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let controller = JSONSchemaFormController()

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let isValid = controller.validate()

        XCTAssertFalse(isValid, "Nested validation should fail")
        XCTAssertFalse(controller.errors.isEmpty, "Should have errors for nested fields")
    }

    // MARK: - Array Validation Tests

    @MainActor
    func testArrayValidation() async throws {
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "tags": {
                            "type": "array",
                            "minItems": 2,
                            "items": {
                                "type": "string"
                            }
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "tags": .array(items: [.string("tag1")])  // Only 1 item, needs 2
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        let controller = JSONSchemaFormController()

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let isValid = controller.validate()

        XCTAssertFalse(isValid, "Array validation should fail with too few items")
    }
}
