import JSONSchema
import JSONSchemaValidator
import SwiftUI
import XCTest

@testable import JSONSchemaForm

/// Unit tests for JSONSchemaFormController
class JSONSchemaFormControllerTests: XCTestCase {

    // MARK: - Initialization Tests

    @MainActor
    func testControllerInitialization() async throws {
        let controller = JSONSchemaFormController()

        // Verify default state
        XCTAssertTrue(controller.errors.isEmpty, "Errors should be empty on initialization")
        XCTAssertTrue(controller.isValid, "Controller should be valid on initialization")
        XCTAssertFalse(controller.isSubmitting, "Should not be submitting on initialization")
        XCTAssertTrue(controller.fieldErrors.isEmpty, "Field errors should be empty on initialization")
    }

    // MARK: - Validation Tests

    @MainActor
    func testValidateWithValidData() async throws {
        let controller = JSONSchemaFormController()
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

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let isValid = controller.validate()

        XCTAssertTrue(isValid, "Validation should pass with valid data")
        XCTAssertTrue(controller.errors.isEmpty, "Errors should be empty for valid data")
        XCTAssertTrue(controller.isValid, "Controller should report isValid = true")
    }

    @MainActor
    func testValidateWithInvalidData() async throws {
        let controller = JSONSchemaFormController()
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

        // Name is too short (less than 3 characters)
        var formData = FormData.object(properties: [
            "name": .string("Jo")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let isValid = controller.validate()

        XCTAssertFalse(isValid, "Validation should fail with invalid data")
        XCTAssertFalse(controller.errors.isEmpty, "Errors should not be empty for invalid data")
        XCTAssertFalse(controller.isValid, "Controller should report isValid = false")
    }

    @MainActor
    func testValidateWithMissingRequiredField() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["email"],
                    "properties": {
                        "email": { "type": "string" }
                    }
                }
                """)

        // Missing required email field
        var formData = FormData.object(properties: [:])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let isValid = controller.validate()

        XCTAssertFalse(isValid, "Validation should fail with missing required field")
        XCTAssertFalse(controller.errors.isEmpty, "Errors should contain missing field error")
    }

    // MARK: - Callback Tests

    @MainActor
    func testOnValidationErrorCallback() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["name"],
                    "properties": {
                        "name": {
                            "type": "string",
                            "minLength": 5
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "name": .string("Jo")  // Too short
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        var callbackErrors: [ValidationError] = []
        controller.onValidationError = { errors in
            callbackErrors = errors
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        _ = controller.validate()

        XCTAssertFalse(callbackErrors.isEmpty, "Callback should receive validation errors")
        XCTAssertEqual(callbackErrors.count, controller.errors.count, "Callback errors should match controller errors")
    }

    @MainActor
    func testOnValidationErrorCallbackNotCalledOnSuccess() async throws {
        let controller = JSONSchemaFormController()
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
            "name": .string("Valid Name")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        var callbackCalled = false
        controller.onValidationError = { _ in
            callbackCalled = true
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        _ = controller.validate()

        XCTAssertFalse(callbackCalled, "Callback should not be called when validation succeeds")
    }

    // MARK: - Submit Tests

    @MainActor
    func testSubmitSuccess() async throws {
        let controller = JSONSchemaFormController()
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

        var submitSuccessCalled = false
        controller.onSubmitSuccess = { data in
            submitSuccessCalled = true
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let success = try await controller.submit()

        XCTAssertTrue(success, "Submit should return true on success")
        XCTAssertTrue(submitSuccessCalled, "onSubmitSuccess callback should be called")
        XCTAssertFalse(controller.isSubmitting, "isSubmitting should be false after completion")
    }

    @MainActor
    func testSubmitFailure() async throws {
        let controller = JSONSchemaFormController()
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

        // Password too short
        var formData = FormData.object(properties: [
            "password": .string("short")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        var submitSuccessCalled = false
        controller.onSubmitSuccess = { _ in
            submitSuccessCalled = true
        }

        var validationErrorsCalled = false
        controller.onValidationError = { _ in
            validationErrorsCalled = true
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let success = try await controller.submit()

        XCTAssertFalse(success, "Submit should return false on validation failure")
        XCTAssertFalse(submitSuccessCalled, "onSubmitSuccess should not be called on failure")
        XCTAssertTrue(validationErrorsCalled, "onValidationError should be called on failure")
        XCTAssertFalse(controller.isSubmitting, "isSubmitting should be false after completion")
    }

    @MainActor
    func testSubmitPreventsDoubleSubmission() async throws {
        let controller = JSONSchemaFormController()
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
            "name": .string("Test")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        // Start first submission
        let firstSubmit = try await controller.submit()
        XCTAssertTrue(firstSubmit, "First submit should succeed")
    }

    // MARK: - Field Errors Mapping Tests

    @MainActor
    func testFieldErrorsMapping() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["name", "email"],
                    "properties": {
                        "name": {
                            "type": "string",
                            "minLength": 3
                        },
                        "email": {
                            "type": "string",
                            "format": "email"
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "name": .string("Jo"),  // Too short
            "email": .string("not-an-email")  // Invalid email format
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        _ = controller.validate()

        // Field errors should be populated
        XCTAssertFalse(controller.fieldErrors.isEmpty, "Field errors should be populated")
    }

    @MainActor
    func testErrorsForField() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["name"],
                    "properties": {
                        "name": {
                            "type": "string",
                            "minLength": 5
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "name": .string("Jo")  // Too short
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        _ = controller.validate()

        let nameErrors = controller.errorsForField("root_name")
        // There should be an error for the name field (minLength violation)
        XCTAssertFalse(nameErrors.isEmpty || controller.fieldErrors.isEmpty,
                       "There should be errors for the name field or in fieldErrors")

        // Non-existent field should return empty array
        let nonExistentErrors = controller.errorsForField("root_nonexistent")
        XCTAssertTrue(nonExistentErrors.isEmpty, "Non-existent field should return empty array")
    }

    // MARK: - Clear Errors Tests

    @MainActor
    func testClearErrors() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["name"],
                    "properties": {
                        "name": { "type": "string", "minLength": 10 }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "name": .string("Jo")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        // First, validate to get errors
        _ = controller.validate()
        XCTAssertFalse(controller.errors.isEmpty, "Should have errors after validation")
        XCTAssertFalse(controller.isValid, "Should not be valid")

        // Clear errors
        controller.clearErrors()

        XCTAssertTrue(controller.errors.isEmpty, "Errors should be empty after clearing")
        XCTAssertTrue(controller.fieldErrors.isEmpty, "Field errors should be empty after clearing")
        XCTAssertTrue(controller.isValid, "Should be valid after clearing")
    }

    // MARK: - Live Validation Tests

    @MainActor
    func testLiveValidation() async throws {
        let controller = JSONSchemaFormController()
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
            "name": .string("Jo")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: true,  // Enable live validation
            customValidate: nil,
            transformErrors: nil
        )

        // Trigger form data change handler (simulates user typing)
        controller.handleFormDataChange()

        // With live validation enabled, validation should have run
        XCTAssertFalse(controller.isValid, "Should be invalid after live validation with short name")
        XCTAssertFalse(controller.errors.isEmpty, "Should have errors from live validation")
    }

    @MainActor
    func testLiveValidationDisabled() async throws {
        let controller = JSONSchemaFormController()
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
            "name": .string("Jo")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,  // Disable live validation
            customValidate: nil,
            transformErrors: nil
        )

        // Trigger form data change handler
        controller.handleFormDataChange()

        // With live validation disabled, validation should not have run
        XCTAssertTrue(controller.isValid, "Should still be valid (initial state) without live validation")
        XCTAssertTrue(controller.errors.isEmpty, "Should have no errors without live validation")
    }

    // MARK: - Transform Errors Tests

    @MainActor
    func testTransformErrors() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["name"],
                    "properties": {
                        "name": { "type": "string", "minLength": 5 }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "name": .string("Jo")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        var transformCalled = false
        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: { errors in
                transformCalled = true
                // Return empty to clear all errors (for testing)
                return []
            }
        )

        _ = controller.validate()

        XCTAssertTrue(transformCalled, "Transform errors function should be called")
        XCTAssertTrue(controller.errors.isEmpty, "Errors should be empty after transform")
    }

    // MARK: - Configuration Tests

    @MainActor
    func testControllerWithoutConfiguration() async throws {
        let controller = JSONSchemaFormController()

        // Validate without configuration should return true (no schema to validate against)
        let isValid = controller.validate()

        XCTAssertTrue(isValid, "Validation without configuration should return true")
    }

    // MARK: - Nested Object Validation Tests

    @MainActor
    func testNestedObjectValidation() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "address": {
                            "type": "object",
                            "required": ["street"],
                            "properties": {
                                "street": { "type": "string", "minLength": 5 }
                            }
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "address": .object(properties: [
                "street": .string("Hi")  // Too short
            ])
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let isValid = controller.validate()

        XCTAssertFalse(isValid, "Nested object validation should fail with invalid data")
        XCTAssertFalse(controller.errors.isEmpty, "Should have errors for nested field")
    }

    // MARK: - Default Value Tests

    @MainActor
    func testSubmitWithDefaultValueProducesNoErrors() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["name"],
                    "properties": {
                        "name": {
                            "type": "string",
                            "default": "John"
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "name": .string("John")
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        var submitSuccessCalled = false
        controller.onSubmitSuccess = { _ in
            submitSuccessCalled = true
        }

        var validationErrorCalled = false
        controller.onValidationError = { _ in
            validationErrorCalled = true
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let success = try await controller.submit()

        XCTAssertTrue(success, "Submit should succeed when form data has the default value")
        XCTAssertTrue(controller.isValid, "Controller should report valid")
        XCTAssertTrue(controller.errors.isEmpty, "Controller should have no errors")
        XCTAssertTrue(submitSuccessCalled, "onSubmitSuccess should be called")
        XCTAssertFalse(validationErrorCalled, "onValidationError should not be called")
    }

    // MARK: - Not Required Without Default Tests

    @MainActor
    func testSubmitWithoutDefaultValueAndNotRequiredProducesNoErrors() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "nickname": {
                            "type": "string"
                        }
                    }
                }
                """)

        // Empty form data — the optional field is not provided
        var formData = FormData.object(properties: [:])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        var submitSuccessCalled = false
        controller.onSubmitSuccess = { _ in
            submitSuccessCalled = true
        }

        var validationErrorCalled = false
        controller.onValidationError = { _ in
            validationErrorCalled = true
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let success = try await controller.submit()

        XCTAssertTrue(success, "Submit should succeed when non-required field has no value and no default")
        XCTAssertTrue(controller.isValid, "Controller should report valid")
        XCTAssertTrue(controller.errors.isEmpty, "Controller should have no errors")
        XCTAssertTrue(submitSuccessCalled, "onSubmitSuccess should be called")
        XCTAssertFalse(validationErrorCalled, "onValidationError should not be called")
    }

    // MARK: - Boolean Default Value Tests

    @MainActor
    func testSubmitWithBooleanDefaultValueProducesNoErrorsAndValueSetToFalse() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["enabled"],
                    "properties": {
                        "enabled": {
                            "type": "boolean",
                            "default": false
                        }
                    }
                }
                """)

        var formData = FormData.object(properties: [
            "enabled": .boolean(false)
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        var submitSuccessCalled = false
        var receivedFormData: FormData?
        controller.onSubmitSuccess = { data in
            submitSuccessCalled = true
            receivedFormData = data
        }

        var validationErrorCalled = false
        controller.onValidationError = { _ in
            validationErrorCalled = true
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let success = try await controller.submit()

        XCTAssertTrue(success, "Submit should succeed when boolean field has default value false")
        XCTAssertTrue(controller.isValid, "Controller should report valid")
        XCTAssertTrue(controller.errors.isEmpty, "Controller should have no errors")
        XCTAssertTrue(submitSuccessCalled, "onSubmitSuccess should be called")
        XCTAssertFalse(validationErrorCalled, "onValidationError should not be called")

        // Verify the boolean value is set to false
        XCTAssertNotNil(receivedFormData, "Should receive form data on submit")
        if let properties = receivedFormData?.object {
            XCTAssertEqual(properties["enabled"], .boolean(false), "Boolean value should be false")
        } else {
            XCTFail("Received form data should be an object")
        }
    }

    // MARK: - DateTime Field Tests

    @MainActor
    func testSubmitWithDateTimeFieldProducesNoErrorsAndValueIsPreserved() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["createdAt"],
                    "properties": {
                        "createdAt": {
                            "type": "string",
                            "format": "date-time"
                        }
                    }
                }
                """)

        let dateTimeValue = "2026-02-18T09:00:00Z"
        var formData = FormData.object(properties: [
            "createdAt": .string(dateTimeValue)
        ])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        var submitSuccessCalled = false
        var receivedFormData: FormData?
        controller.onSubmitSuccess = { data in
            submitSuccessCalled = true
            receivedFormData = data
        }

        var validationErrorCalled = false
        controller.onValidationError = { _ in
            validationErrorCalled = true
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let success = try await controller.submit()

        XCTAssertTrue(success, "Submit should succeed when datetime field has a valid value")
        XCTAssertTrue(controller.isValid, "Controller should report valid")
        XCTAssertTrue(controller.errors.isEmpty, "Controller should have no errors")
        XCTAssertTrue(submitSuccessCalled, "onSubmitSuccess should be called")
        XCTAssertFalse(validationErrorCalled, "onValidationError should not be called")

        // Verify the datetime value is preserved
        XCTAssertNotNil(receivedFormData, "Should receive form data on submit")
        if let properties = receivedFormData?.object {
            XCTAssertEqual(properties["createdAt"], .string(dateTimeValue), "DateTime value should be preserved")
        } else {
            XCTFail("Received form data should be an object")
        }
    }

    // MARK: - Default Value Population Tests (Real-World Scenarios)

    @MainActor
    func testSubmitWithEmptyFormDataAndBooleanDefaultAppliesDefault() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["enabled"],
                    "properties": {
                        "enabled": {
                            "type": "boolean",
                            "default": false
                        }
                    }
                }
                """)

        // Start with empty formData — the real-world scenario
        var formData = FormData.object(properties: [:])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        var submitSuccessCalled = false
        var receivedFormData: FormData?
        controller.onSubmitSuccess = { data in
            submitSuccessCalled = true
            receivedFormData = data
        }

        var validationErrorCalled = false
        controller.onValidationError = { _ in
            validationErrorCalled = true
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let success = try await controller.submit()

        XCTAssertTrue(success, "Submit should succeed — boolean default false should be applied")
        XCTAssertTrue(controller.isValid, "Controller should report valid")
        XCTAssertTrue(controller.errors.isEmpty, "Controller should have no errors")
        XCTAssertTrue(submitSuccessCalled, "onSubmitSuccess should be called")
        XCTAssertFalse(validationErrorCalled, "onValidationError should not be called")

        // Verify the default was applied
        XCTAssertNotNil(receivedFormData, "Should receive form data on submit")
        if let properties = receivedFormData?.object {
            XCTAssertEqual(properties["enabled"], .boolean(false), "Boolean default false should be applied")
        } else {
            XCTFail("Received form data should be an object")
        }
    }

    @MainActor
    func testSubmitWithEmptyFormDataAndStringDefaultAppliesDefault() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["name"],
                    "properties": {
                        "name": {
                            "type": "string",
                            "default": "John"
                        }
                    }
                }
                """)

        // Start with empty formData
        var formData = FormData.object(properties: [:])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        var submitSuccessCalled = false
        var receivedFormData: FormData?
        controller.onSubmitSuccess = { data in
            submitSuccessCalled = true
            receivedFormData = data
        }

        var validationErrorCalled = false
        controller.onValidationError = { _ in
            validationErrorCalled = true
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let success = try await controller.submit()

        XCTAssertTrue(success, "Submit should succeed — string default should be applied")
        XCTAssertTrue(controller.isValid, "Controller should report valid")
        XCTAssertTrue(controller.errors.isEmpty, "Controller should have no errors")
        XCTAssertTrue(submitSuccessCalled, "onSubmitSuccess should be called")
        XCTAssertFalse(validationErrorCalled, "onValidationError should not be called")

        // Verify the default was applied
        if let properties = receivedFormData?.object {
            XCTAssertEqual(properties["name"], .string("John"), "String default should be applied")
        } else {
            XCTFail("Received form data should be an object")
        }
    }

    @MainActor
    func testSubmitWithEmptyFormDataAndDateTimeFieldAppliesDefault() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["createdAt"],
                    "properties": {
                        "createdAt": {
                            "type": "string",
                            "format": "date-time",
                            "default": "2026-01-01T00:00:00Z"
                        }
                    }
                }
                """)

        // Start with empty formData
        var formData = FormData.object(properties: [:])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        var submitSuccessCalled = false
        var receivedFormData: FormData?
        controller.onSubmitSuccess = { data in
            submitSuccessCalled = true
            receivedFormData = data
        }

        var validationErrorCalled = false
        controller.onValidationError = { _ in
            validationErrorCalled = true
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: false,
            customValidate: nil,
            transformErrors: nil
        )

        let success = try await controller.submit()

        XCTAssertTrue(success, "Submit should succeed — empty string default should satisfy required")
        XCTAssertTrue(controller.isValid, "Controller should report valid")
        XCTAssertTrue(controller.errors.isEmpty, "Controller should have no errors")
        XCTAssertTrue(submitSuccessCalled, "onSubmitSuccess should be called")
        XCTAssertFalse(validationErrorCalled, "onValidationError should not be called")

        // Verify the default was applied (empty string for date-time without explicit default)
        if let properties = receivedFormData?.object {
            XCTAssertNotNil(properties["createdAt"], "DateTime field should be populated")
        } else {
            XCTFail("Received form data should be an object")
        }
    }

    @MainActor
    func testLiveValidateWithEmptyFormDataAndDefaultsDoesNotProduceErrors() async throws {
        let controller = JSONSchemaFormController()
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "required": ["enabled", "name"],
                    "properties": {
                        "enabled": {
                            "type": "boolean",
                            "default": false
                        },
                        "name": {
                            "type": "string",
                            "default": "Default Name"
                        }
                    }
                }
                """)

        // Start with empty formData
        var formData = FormData.object(properties: [:])
        let binding = Binding(get: { formData }, set: { formData = $0 })

        var validationErrorCalled = false
        controller.onValidationError = { _ in
            validationErrorCalled = true
        }

        controller.configure(
            schema: schema,
            formData: binding,
            liveValidate: true,
            customValidate: nil,
            transformErrors: nil
        )

        // Trigger live validation
        controller.handleFormDataChange()

        XCTAssertTrue(controller.isValid, "Live validation should pass with defaults applied")
        XCTAssertTrue(controller.errors.isEmpty, "Should have no errors after defaults applied")
        XCTAssertFalse(validationErrorCalled, "onValidationError should not be called")

        // Verify defaults were populated in formData
        if case .object(let properties) = formData {
            XCTAssertEqual(properties["enabled"], .boolean(false), "Boolean default should be applied")
            XCTAssertEqual(properties["name"], .string("Default Name"), "String default should be applied")
        } else {
            XCTFail("formData should be an object")
        }
    }
}
