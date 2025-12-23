@testable import JSONSchemaForm
import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

/// Tests for default values with $ref functionality
/// Uses testSchema18 which defines defaults in referenced definitions
class JSONSchemaFormDefaultWithRefsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        executionTimeAllowance = 30
    }

    /// Helper to parse schema with preprocessing
    private func parseSchema(_ jsonString: String) throws -> JSONSchema {
        let preprocessed = try SchemaPreprocessor.preprocess(jsonString)
        return try JSONSchema(jsonString: preprocessed)
    }

    // MARK: - Basic Default with $ref Tests

    /// Test that empty form data shows default scalar value from referenced definition
    @MainActor
    func testDefaultScalarValue() async throws {
        let schema = try parseSchema(testSchema18)

        // Use empty form data - defaults should be applied
        let formData = FormData.object(properties: [
            "valuesInFormData": .object(properties: [:])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify scalar field shows default value "scalar default"
        let scalarField = try form.inspect().find(viewWithId: "root_valuesInFormData_scalar").textField()
        XCTAssertEqual(try scalarField.input(), "scalar default", "Scalar field should show schema default")
    }

    /// Test that empty form data shows default nested object value
    @MainActor
    func testDefaultNestedObjectValue() async throws {
        let schema = try parseSchema(testSchema18)

        // Use empty nested object - defaults should be applied
        let formData = FormData.object(properties: [
            "valuesInFormData": .object(properties: [
                "object": .object(properties: [:])
            ])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify nested object field shows default value "nested object default"
        let nestedField = try form.inspect().find(viewWithId: "root_valuesInFormData_object_nested").textField()
        XCTAssertEqual(try nestedField.input(), "nested object default", "Nested object field should show schema default")
    }

    // MARK: - Override Default Tests

    /// Test that provided value in FormData overrides schema default
    @MainActor
    func testProvidedValueOverridesDefault() async throws {
        let schema = try parseSchema(testSchema18)

        // Provide custom value that should override default
        let formData = FormData.object(properties: [
            "valuesInFormData": .object(properties: [
                "scalar": .string("custom value")
            ])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify scalar field shows provided value, not default
        let scalarField = try form.inspect().find(viewWithId: "root_valuesInFormData_scalar").textField()
        XCTAssertEqual(try scalarField.input(), "custom value", "Provided value should override default")
    }

    /// Test mix of provided values and defaults
    @MainActor
    func testPartialFormDataWithDefaults() async throws {
        let schema = try parseSchema(testSchema18)

        // Provide some values, leave others to use defaults
        let formData = FormData.object(properties: [
            "valuesInFormData": .object(properties: [
                "scalar": .string("provided scalar"),
                "object": .object(properties: [:])  // Leave nested to use default
            ])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify provided value is used
        let scalarField = try form.inspect().find(viewWithId: "root_valuesInFormData_scalar").textField()
        XCTAssertEqual(try scalarField.input(), "provided scalar", "Provided scalar should be used")

        // Verify nested default is used
        let nestedField = try form.inspect().find(viewWithId: "root_valuesInFormData_object_nested").textField()
        XCTAssertEqual(try nestedField.input(), "nested object default", "Nested field should use default")
    }

    // MARK: - Nested Structure Tests

    /// Test multiple levels of nesting with defaults
    @MainActor
    func testNestedObjectDefaults() async throws {
        let schema = try parseSchema(testSchema18)

        // Provide outer object but let inner use defaults
        let formData = FormData.object(properties: [
            "valuesInFormData": .object(properties: [
                "object": .object(properties: [
                    "nested": .string("custom nested value")
                ])
            ])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify custom nested value is used
        let nestedField = try form.inspect().find(viewWithId: "root_valuesInFormData_object_nested").textField()
        XCTAssertEqual(try nestedField.input(), "custom nested value", "Custom nested value should be used")
    }

    /// Test that both properties using same $ref get defaults
    @MainActor
    func testBothPropertiesHaveDefaults() async throws {
        let schema = try parseSchema(testSchema18)

        // Both properties reference defaultsExample definition
        let formData = FormData.object(properties: [
            "valuesInFormData": .object(properties: [:]),
            "noValuesInFormData": .object(properties: [:])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify both get scalar defaults
        let valuesScalar = try form.inspect().find(viewWithId: "root_valuesInFormData_scalar").textField()
        XCTAssertEqual(try valuesScalar.input(), "scalar default", "valuesInFormData.scalar should have default")

        let noValuesScalar = try form.inspect().find(viewWithId: "root_noValuesInFormData_scalar").textField()
        XCTAssertEqual(try noValuesScalar.input(), "scalar default", "noValuesInFormData.scalar should have default")
    }

    // MARK: - Empty vs Default Tests

    /// Test that completely empty FormData triggers default initialization
    @MainActor
    func testEmptyFormDataUsesDefaults() async throws {
        let schema = try parseSchema(testSchema18)

        // Completely empty form data
        let formData = FormData.object(properties: [:])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Form should render without errors
        let _ = try form.inspect()
    }

    /// Test schema structure is correctly parsed with defaults preserved
    @MainActor
    func testSchemaStructureWithDefaults() async throws {
        let schema = try parseSchema(testSchema18)

        // Verify schema has expected structure
        XCTAssertNotNil(schema.objectSchema?.properties?["valuesInFormData"], "Should have valuesInFormData")
        XCTAssertNotNil(schema.objectSchema?.properties?["noValuesInFormData"], "Should have noValuesInFormData")

        // Verify referenced properties are resolved
        let valuesInFormData = schema.objectSchema?.properties?["valuesInFormData"]
        XCTAssertNotNil(valuesInFormData?.objectSchema?.properties?["scalar"], "Should have scalar property")
        XCTAssertNotNil(valuesInFormData?.objectSchema?.properties?["array"], "Should have array property")
        XCTAssertNotNil(valuesInFormData?.objectSchema?.properties?["object"], "Should have object property")

        // Verify defaults are present in resolved schema
        let scalarSchema = valuesInFormData?.objectSchema?.properties?["scalar"]
        XCTAssertNotNil(scalarSchema?.defaultValue, "Scalar should have default value")
    }
}
