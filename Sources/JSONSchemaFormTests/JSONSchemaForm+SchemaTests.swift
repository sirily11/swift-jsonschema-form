import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

/// Integration tests using the 19 example schemas from react-jsonschema-form
class JSONSchemaFormSchemaTests: XCTestCase {
    override func setUp() {
        super.setUp()
        executionTimeAllowance = 30
    }

    /// Helper to parse schema with preprocessing
    private func parseSchema(_ jsonString: String) throws -> JSONSchema {
        let preprocessed = try SchemaPreprocessor.preprocess(jsonString)
        return try JSONSchema(jsonString: preprocessed)
    }

    /// Helper to parse schema with preprocessing and extract conditionals
    private func parseSchemaWithConditionals(_ jsonString: String) throws -> (JSONSchema, [ConditionalSchema]) {
        let preprocessed = try SchemaPreprocessor.preprocessWithConditionals(jsonString)
        let schema = try JSONSchema(jsonString: preprocessed.jsonString)
        return (schema, preprocessed.conditionals)
    }

    // MARK: - Phase 1: Basic Schemas

    /// testSchema1: A registration form with strings, integer, and required fields
    @MainActor
    func testSchema1_BasicRegistration() async throws {
        let schema = try parseSchema(testSchema1)
        let formData = FormData.object(properties: [
            "firstName": .string("Chuck"),
            "lastName": .string("Norris"),
            "age": .number(80),
            "bio": .string("Legendary martial artist"),
            "password": .string("secret123"),
            "telephone": .string("1234567890")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify firstName field
        let firstNameField = try form.inspect().find(viewWithId: "root_firstName").textField()
        XCTAssertEqual(try firstNameField.input(), "Chuck")

        // Verify lastName field
        let lastNameField = try form.inspect().find(viewWithId: "root_lastName").textField()
        XCTAssertEqual(try lastNameField.input(), "Norris")

        // Verify age field
        let ageField = try form.inspect().find(viewWithId: "root_age").textField()
        XCTAssertEqual(try ageField.input(), "80")
    }

    /// testSchema2: Empty schema {}
    @MainActor
    func testSchema2_EmptySchema() async throws {
        let schema = try parseSchema(testSchema2)
        let formData = FormData.object(properties: [:])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Empty schema should render without errors
        let _ = try form.inspect()
    }

    /// testSchema3: Task list with nested arrays of objects
    @MainActor
    func testSchema3_TaskList() async throws {
        let schema = try parseSchema(testSchema3)
        let formData = FormData.object(properties: [
            "title": .string("My Tasks"),
            "tasks": .array(items: [
                .object(properties: [
                    "title": .string("Task 1"),
                    "details": .string("Details for task 1"),
                    "done": .boolean(false)
                ]),
                .object(properties: [
                    "title": .string("Task 2"),
                    "details": .string("Details for task 2"),
                    "done": .boolean(true)
                ])
            ])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify title field
        let titleField = try form.inspect().find(viewWithId: "root_title").textField()
        XCTAssertEqual(try titleField.input(), "My Tasks")
    }

    /// testSchema5: Number fields with enums and ranges
    @MainActor
    func testSchema5_NumberFields() async throws {
        let schema = try parseSchema(testSchema5)
        let formData = FormData.object(properties: [
            "number": .number(3.14),
            "integer": .number(42)
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify number field
        let numberField = try form.inspect().find(viewWithId: "root_number").textField()
        XCTAssertEqual(try numberField.input(), "3")

        // Verify integer field
        let integerField = try form.inspect().find(viewWithId: "root_integer").textField()
        XCTAssertEqual(try integerField.input(), "42")
    }

    /// testSchema15: Null field example
    @MainActor
    func testSchema15_NullField() async throws {
        let schema = try parseSchema(testSchema15)
        let formData = FormData.object(properties: [
            "firstName": .string("Chuck"),
            "helpText": .null
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify firstName field
        let firstNameField = try form.inspect().find(viewWithId: "root_firstName").textField()
        XCTAssertEqual(try firstNameField.input(), "Chuck")

        // Null field should be rendered (as informational text)
        // The form should render without errors
        let _ = try form.inspect()
    }

    // MARK: - Phase 2: Combinators

    /// testSchema11: anyOf combinator
    /// This schema has both direct properties (age) AND anyOf options
    @MainActor
    func testSchema11_AnyOf() async throws {
        let schema = try parseSchema(testSchema11)

        // Verify schema parsed as anyOf type
        XCTAssertEqual(schema.type, .anyOf, "Schema should be parsed as anyOf type")

        // Verify anyOf options exist
        XCTAssertNotNil(schema.combinedSchema?.anyOf, "Schema should have anyOf options")
        XCTAssertEqual(schema.combinedSchema?.anyOf?.count, 2, "Schema should have 2 anyOf options")

        // Test form rendering with anyOf data
        let formData = FormData.object(properties: [
            "age": .number(25),
            "firstName": .string("John"),
            "lastName": .string("Doe")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // anyOf schemas render as UnsupportedField currently
        // Verify form renders without crashing
        let _ = try form.inspect()
    }

    /// testSchema12: oneOf combinator
    /// Schema where exactly one of the subschemas must validate
    @MainActor
    func testSchema12_OneOf() async throws {
        let schema = try parseSchema(testSchema12)

        // Verify schema parsed as oneOf type
        XCTAssertEqual(schema.type, .oneOf, "Schema should be parsed as oneOf type")

        // Verify oneOf options exist (lorem OR ipsum)
        XCTAssertNotNil(schema.combinedSchema?.oneOf, "Schema should have oneOf options")
        XCTAssertEqual(schema.combinedSchema?.oneOf?.count, 2, "Schema should have 2 oneOf options")

        // Verify each option has the expected structure
        let options = schema.combinedSchema?.oneOf ?? []
        XCTAssertTrue(options.contains { $0.objectSchema?.properties?["lorem"] != nil }, "First option should have lorem property")
        XCTAssertTrue(options.contains { $0.objectSchema?.properties?["ipsum"] != nil }, "Second option should have ipsum property")

        // Test form rendering with lorem option selected (first option)
        let formData = FormData.object(properties: [
            "lorem": .string("hello world")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify oneOf picker is rendered
        let picker = try form.inspect().find(viewWithId: "root_oneOf_picker")
        XCTAssertNotNil(picker, "OneOf picker should be rendered")

        // Verify lorem field is rendered (first option's field)
        let loremField = try form.inspect().find(viewWithId: "root_lorem").textField()
        XCTAssertEqual(try loremField.input(), "hello world", "Lorem field should display the value")
    }

    /// Test oneOf with second option selected - comprehensive UI and interaction tests
    /// Note: ViewInspector doesn't trigger onAppear, so the initial option detection
    /// that happens in onAppear doesn't run. We verify form rendering and structure.
    @MainActor
    func testSchema12_OneOf_SecondOption() async throws {
        let schema = try parseSchema(testSchema12)

        // Test form rendering with ipsum option (second option)
        let formData = FormData.object(properties: [
            "ipsum": .string("ipsum value")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // MARK: - Basic Rendering Tests

        // Verify form renders without error
        let _ = try form.inspect()

        // Verify picker renders with correct options
        let picker = try form.inspect().find(viewWithId: "root_oneOf_picker")
        XCTAssertNotNil(picker, "OneOf picker should be rendered")

        // MARK: - Form Data Verification

        // Verify form data structure is intact
        XCTAssertEqual(
            data.wrappedValue.object?["ipsum"],
            .string("ipsum value"),
            "Form data should contain ipsum value"
        )

        // Verify schema has correct structure for both options
        XCTAssertEqual(schema.combinedSchema?.oneOf?.count, 2, "Should have 2 oneOf options")

        // Verify first option structure (lorem)
        let options = schema.combinedSchema?.oneOf ?? []
        XCTAssertTrue(
            options.contains { $0.objectSchema?.properties?["lorem"] != nil },
            "First option should have lorem property"
        )

        // Verify second option structure (ipsum)
        XCTAssertTrue(
            options.contains { $0.objectSchema?.properties?["ipsum"] != nil },
            "Second option should have ipsum property"
        )
    }

    /// testSchema13: allOf combinator with type arrays
    /// Schema where all sub-schemas must validate (merges constraints)
    /// See JSONSchemaForm+AllOfTests.swift for comprehensive allOf tests
    @MainActor
    func testSchema13_AllOf() async throws {
        let schema = try parseSchema(testSchema13)

        // Verify schema parsed as allOf type
        XCTAssertEqual(schema.type, .allOf, "Schema should be parsed as allOf type")

        // Verify allOf schemas exist (merges lorem and ipsum properties)
        XCTAssertNotNil(schema.combinedSchema?.allOf, "Schema should have allOf schemas")
        XCTAssertEqual(schema.combinedSchema?.allOf?.count, 2, "Schema should have 2 allOf schemas to merge")

        // Verify merged properties exist in sub-schemas
        let allOfSchemas = schema.combinedSchema?.allOf ?? []
        let hasLorem = allOfSchemas.contains { $0.objectSchema?.properties?["lorem"] != nil }
        let hasIpsum = allOfSchemas.contains { $0.objectSchema?.properties?["ipsum"] != nil }
        XCTAssertTrue(hasLorem, "allOf should contain lorem property")
        XCTAssertTrue(hasIpsum, "allOf should contain ipsum property")

        // Verify SchemaMerger correctly merges properties
        let merged = SchemaMerger.merge(schemas: allOfSchemas, baseSchema: schema)
        XCTAssertEqual(merged.properties.count, 2, "Merged schema should have 2 properties")
        XCTAssertNotNil(merged.properties["lorem"], "Merged schema should have lorem")
        XCTAssertNotNil(merged.properties["ipsum"], "Merged schema should have ipsum")

        // Test form rendering with merged data
        let formData = FormData.object(properties: [
            "lorem": .boolean(true),
            "ipsum": .string("test value")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify both merged fields are rendered
        // Lorem should be rendered as a toggle (boolean type from second allOf schema)
        let loremToggle = try form.inspect().find(viewWithId: "root_lorem").toggle()
        XCTAssertTrue(try loremToggle.isOn(), "Lorem toggle should be on")

        // Ipsum should be rendered as a text field
        let ipsumField = try form.inspect().find(viewWithId: "root_ipsum").textField()
        XCTAssertEqual(try ipsumField.input(), "test value", "Ipsum field should display the value")
    }

    // MARK: - Phase 3: References

    /// testSchema4: Arrays with definitions and $ref
    @MainActor
    func testSchema4_ArraysWithRefs() async throws {
        let schema = try parseSchema(testSchema4)
        let formData = FormData.object(properties: [
            "listOfStrings": .array(items: [.string("item1"), .string("item2")])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify array items render - find first item's text field
        let item0Field = try form.inspect().find(viewWithId: "root_listOfStrings_0").textField()
        XCTAssertEqual(try item0Field.input(), "item1")

        let item1Field = try form.inspect().find(viewWithId: "root_listOfStrings_1").textField()
        XCTAssertEqual(try item1Field.input(), "item2")
    }

    /// testSchema6: Nested refs with address definitions
    @MainActor
    func testSchema6_NestedRefs() async throws {
        let schema = try parseSchema(testSchema6)
        let formData = FormData.object(properties: [
            "billing_address": .object(properties: [
                "street_address": .string("123 Main St"),
                "city": .string("New York"),
                "state": .string("NY")
            ])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify nested fields from resolved $ref
        let streetField = try form.inspect().find(viewWithId: "root_billing_address_street_address").textField()
        XCTAssertEqual(try streetField.input(), "123 Main St")

        let cityField = try form.inspect().find(viewWithId: "root_billing_address_city").textField()
        XCTAssertEqual(try cityField.input(), "New York")

        let stateField = try form.inspect().find(viewWithId: "root_billing_address_state").textField()
        XCTAssertEqual(try stateField.input(), "NY")
    }

    /// testSchema16: Complex enum with object values
    @MainActor
    func testSchema16_ComplexEnum() async throws {
        let schema = try parseSchema(testSchema16)

        // Verify schema has location property with enum
        XCTAssertNotNil(schema.objectSchema?.properties?["location"], "Schema should have location property")

        // Test form rendering with location selected
        let formData = FormData.object(properties: [
            "location": .string("{\"lat\":40,\"lon\":74,\"name\":\"New York\"}")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify location picker is rendered
        // The preprocessor converts object enums to JSON strings
        let _ = try form.inspect().find(viewWithId: "root_location_enum_field")
    }

    /// testSchema18: Schema defaults with refs
    @MainActor
    func testSchema18_DefaultsWithRefs() async throws {
        let schema = try parseSchema(testSchema18)

        // Verify schema structure - should have valuesInFormData and noValuesInFormData properties
        XCTAssertNotNil(schema.objectSchema?.properties?["valuesInFormData"], "Schema should have valuesInFormData property")
        XCTAssertNotNil(schema.objectSchema?.properties?["noValuesInFormData"], "Schema should have noValuesInFormData property")

        // Test form rendering with nested data including defaults
        let formData = FormData.object(properties: [
            "valuesInFormData": .object(properties: [
                "scalar": .string("custom value"),
                "object": .object(properties: [
                    "nested": .string("nested value")
                ])
            ])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify nested scalar field is rendered with provided value
        let scalarField = try form.inspect().find(viewWithId: "root_valuesInFormData_scalar").textField()
        XCTAssertEqual(try scalarField.input(), "custom value")

        // Verify nested object field is rendered
        let nestedField = try form.inspect().find(viewWithId: "root_valuesInFormData_object_nested").textField()
        XCTAssertEqual(try nestedField.input(), "nested value")
    }

    /// testSchema19: $defs with $id (URI-based references)
    /// Tests resolution of $defs using $id URIs like "/schemas/mixins/integer"
    @MainActor
    func testSchema19_DefsWithId() async throws {
        let schema = try parseSchema(testSchema19)

        // MARK: Schema Resolution Tests

        // Verify schema is parsed as object (root level)
        XCTAssertEqual(schema.type, .object, "Root schema should be object type")

        // Verify num property exists (resolved from $ref to nonNegativeInteger)
        XCTAssertNotNil(schema.objectSchema?.properties?["num"], "Schema should have num property")

        // The num property references an allOf that combines integer + non-negative
        let numSchema = schema.objectSchema?.properties?["num"]
        XCTAssertEqual(numSchema?.type, .allOf, "num property should be allOf type (integer + non-negative)")

        // Verify allOf has exactly 2 sub-schemas (integer type + minimum constraint)
        let allOfSchemas = numSchema?.combinedSchema?.allOf
        XCTAssertEqual(allOfSchemas?.count, 2, "num should combine 2 schemas")

        // Verify first sub-schema is integer type (resolved from /schemas/mixins/integer)
        XCTAssertEqual(allOfSchemas?[0].type, .integer, "First allOf schema should be integer type")

        // Verify second sub-schema exists (resolved from /schemas/mixins/non-negative)
        // The second schema has minimum:0 constraint - verify it's present by checking the schema is not nil
        XCTAssertNotNil(allOfSchemas?[1], "Second allOf schema should exist with minimum constraint")

        // MARK: Field Rendering Tests

        // Test form rendering with positive value
        let formData = FormData.object(properties: [
            "num": .number(42)
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify form renders without errors
        let _ = try form.inspect()

        // Verify the num field is rendered with correct ID
        // The allOf field should render a number input for primitive integer type
        let numField = try form.inspect().find(viewWithId: "root_num").textField()
        XCTAssertEqual(try numField.input(), "42", "Number field should display value 42")
    }

    /// testSchema19: Test allOf with zero value (boundary case)
    @MainActor
    func testSchema19_DefsWithId_ZeroValue() async throws {
        let schema = try parseSchema(testSchema19)

        let formData = FormData.object(properties: [
            "num": .number(0)  // Exactly at minimum boundary
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        let numField = try form.inspect().find(viewWithId: "root_num").textField()
        XCTAssertEqual(try numField.input(), "0", "Number field should display value 0")
    }

    /// testSchema19: Validation rejects negative values
    @MainActor
    func testSchema19_DefsWithId_ValidationRejectsNegative() async throws {
        let schema = try parseSchema(testSchema19)

        // Create form data with negative value
        let formData = FormData.object(properties: [
            "num": .number(-5)
        ])

        // Convert FormData to dictionary for validation
        let formDataDict = formData.toDictionary()

        // Validate the data
        let result = validateFormData(
            formData: formDataDict,
            schema: schema,
            customValidate: nil
        )

        // Should have validation errors for negative value
        XCTAssertFalse(result.errors.isEmpty, "Negative value should fail validation with minimum:0 constraint")
    }

    /// testSchema19: Validation accepts zero (boundary case)
    @MainActor
    func testSchema19_DefsWithId_ValidationAcceptsZero() async throws {
        let schema = try parseSchema(testSchema19)

        let formData = FormData.object(properties: [
            "num": .number(0)
        ])

        let formDataDict = formData.toDictionary()

        let result = validateFormData(
            formData: formDataDict,
            schema: schema,
            customValidate: nil
        )

        XCTAssertTrue(result.errors.isEmpty, "Zero should pass validation (minimum is inclusive)")
    }

    /// testSchema19: Validation accepts positive integers
    @MainActor
    func testSchema19_DefsWithId_ValidationAcceptsPositive() async throws {
        let schema = try parseSchema(testSchema19)

        let formData = FormData.object(properties: [
            "num": .number(100)
        ])

        let formDataDict = formData.toDictionary()

        let result = validateFormData(
            formData: formDataDict,
            schema: schema,
            customValidate: nil
        )

        XCTAssertTrue(result.errors.isEmpty, "Positive integer should pass validation")
    }

    /// testSchema19: Validation rejects decimal values (integer type constraint)
    @MainActor
    func testSchema19_DefsWithId_ValidationRejectsDecimal() async throws {
        let schema = try parseSchema(testSchema19)

        let formData = FormData.object(properties: [
            "num": .number(3.14)  // Decimal, not integer
        ])

        let formDataDict = formData.toDictionary()

        let result = validateFormData(
            formData: formDataDict,
            schema: schema,
            customValidate: nil
        )

        // Should have validation error for non-integer
        XCTAssertFalse(result.errors.isEmpty, "Decimal value should fail integer validation")
    }

    // MARK: - Phase 4: Nullable Types

    /// testSchema17: Nullable types with type arrays
    @MainActor
    func testSchema17_NullableTypes() async throws {
        let schema = try parseSchema(testSchema17)
        let formData = FormData.object(properties: [
            "firstName": .string("Chuck"),
            "lastName": .string("Norris"),
            "age": .number(80),
            "bio": .string("A legendary martial artist")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify firstName field (regular string)
        let firstNameField = try form.inspect().find(viewWithId: "root_firstName").textField()
        XCTAssertEqual(try firstNameField.input(), "Chuck")

        // Verify lastName field (regular string)
        let lastNameField = try form.inspect().find(viewWithId: "root_lastName").textField()
        XCTAssertEqual(try lastNameField.input(), "Norris")

        // Verify age field (nullable integer - preprocessor converts ["integer", "null"] to "integer")
        let ageField = try form.inspect().find(viewWithId: "root_age").textField()
        XCTAssertEqual(try ageField.input(), "80")

        // Verify bio field (nullable string - preprocessor converts ["string", "null"] to "string")
        let bioField = try form.inspect().find(viewWithId: "root_bio").textField()
        XCTAssertEqual(try bioField.input(), "A legendary martial artist")
    }

    // MARK: - Phase 5: Object Extensions

    /// testSchema9: Additional properties
    @MainActor
    func testSchema9_AdditionalProperties() async throws {
        let schema = try parseSchema(testSchema9)
        let formData = FormData.object(properties: [
            "firstName": .string("John"),
            "lastName": .string("Doe")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify defined properties
        let firstNameField = try form.inspect().find(viewWithId: "root_firstName").textField()
        XCTAssertEqual(try firstNameField.input(), "John")
    }

    /// testSchema10: Pattern properties
    @MainActor
    func testSchema10_PatternProperties() async throws {
        let schema = try parseSchema(testSchema10)
        let formData = FormData.object(properties: [
            "firstName": .string("John"),
            "lastName": .string("Doe")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify defined properties
        let firstNameField = try form.inspect().find(viewWithId: "root_firstName").textField()
        XCTAssertEqual(try firstNameField.input(), "John")
    }

    // MARK: - Phase 6: Dependencies

    /// testSchema7: Property dependencies
    @MainActor
    func testSchema7_PropertyDependencies() async throws {
        let schema = try parseSchema(testSchema7)
        let formData = FormData.object(properties: [
            "unidirectional": .object(properties: [
                "name": .string("John")
            ])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify nested name field in unidirectional object
        let nameField = try form.inspect().find(viewWithId: "root_unidirectional_name").textField()
        XCTAssertEqual(try nameField.input(), "John")
    }

    /// testSchema8: Schema dependencies
    @MainActor
    func testSchema8_SchemaDependencies() async throws {
        let schema = try parseSchema(testSchema8)
        let formData = FormData.object(properties: [
            "simple": .object(properties: [
                "name": .string("John")
            ])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify nested name field in simple object
        let nameField = try form.inspect().find(viewWithId: "root_simple_name").textField()
        XCTAssertEqual(try nameField.input(), "John")
    }

    // MARK: - Phase 7: Conditionals

    /// testSchema14: if/then/else conditionals
    /// Tests that conditional fields appear based on animal selection
    @MainActor
    func testSchema14_IfThenElse() async throws {
        let (schema, conditionals) = try parseSchemaWithConditionals(testSchema14)

        // Verify conditionals were extracted
        XCTAssertEqual(conditionals.count, 2, "Should extract 2 conditionals (Cat and Fish)")

        // Test 1: Cat selection - should show food field only
        var formData = FormData.object(properties: [
            "animal": .string("Cat")
        ])
        var binding = Binding(wrappedValue: formData)
        var form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)
        var view = try form.inspect()

        // Animal field should always be visible
        let animalField = try view.find(viewWithId: "root_animal_enum_field")
        XCTAssertNotNil(animalField, "Animal field should be visible")

        // Food field should be visible for Cat
        XCTAssertNoThrow(
            try view.find(viewWithId: "root_food_enum_field"),
            "Food field should be visible when Cat is selected"
        )

        // Water field should NOT be visible for Cat
        XCTAssertThrowsError(
            try view.find(viewWithId: "root_water_enum_field"),
            "Water field should not be visible for Cat"
        )

        // Test 2: Fish selection - should show both food and water fields
        formData = FormData.object(properties: [
            "animal": .string("Fish")
        ])
        binding = Binding(wrappedValue: formData)
        form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)
        view = try form.inspect()

        // Food field should be visible for Fish
        XCTAssertNoThrow(
            try view.find(viewWithId: "root_food_enum_field"),
            "Food field should be visible when Fish is selected"
        )

        // Water field should be visible for Fish
        XCTAssertNoThrow(
            try view.find(viewWithId: "root_water_enum_field"),
            "Water field should be visible when Fish is selected"
        )

        // Test 3: No selection - no conditional fields visible
        formData = FormData.object(properties: [:])
        binding = Binding(wrappedValue: formData)
        form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)
        view = try form.inspect()

        // Neither food nor water should be visible without selection
        XCTAssertThrowsError(
            try view.find(viewWithId: "root_food_enum_field"),
            "Food field should not be visible without animal selection"
        )
        XCTAssertThrowsError(
            try view.find(viewWithId: "root_water_enum_field"),
            "Water field should not be visible without animal selection"
        )
    }
}
