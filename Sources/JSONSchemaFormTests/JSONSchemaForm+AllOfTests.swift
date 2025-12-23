import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

/// Comprehensive tests for allOf schema combinator
/// Tests cover schema parsing, property merging, UI rendering, data binding, and edge cases
class JSONSchemaFormAllOfTests: XCTestCase {

    override func setUp() {
        super.setUp()
        executionTimeAllowance = 30
    }

    // MARK: - Test Schemas (Inline)

    /// Basic allOf with two schemas merging different properties
    private let basicAllOfSchema = """
        {
          "type": "object",
          "allOf": [
            {
              "properties": {
                "firstName": {
                  "type": "string",
                  "title": "First Name"
                }
              },
              "required": ["firstName"]
            },
            {
              "properties": {
                "lastName": {
                  "type": "string",
                  "title": "Last Name"
                }
              },
              "required": ["lastName"]
            }
          ]
        }
        """

    /// allOf with three schemas to test multiple merging
    private let threeSchemaAllOf = """
        {
          "type": "object",
          "allOf": [
            {
              "properties": {
                "name": {
                  "type": "string"
                }
              }
            },
            {
              "properties": {
                "age": {
                  "type": "integer"
                }
              }
            },
            {
              "properties": {
                "email": {
                  "type": "string"
                }
              },
              "required": ["email"]
            }
          ]
        }
        """

    /// allOf with property override (same property in multiple schemas)
    private let propertyOverrideAllOf = """
        {
          "type": "object",
          "allOf": [
            {
              "properties": {
                "value": {
                  "type": "string",
                  "title": "Value (String)"
                }
              }
            },
            {
              "properties": {
                "value": {
                  "type": "boolean",
                  "title": "Value (Boolean)"
                }
              }
            }
          ]
        }
        """

    /// allOf with mixed types: boolean, string, number
    private let mixedTypesAllOf = """
        {
          "type": "object",
          "allOf": [
            {
              "properties": {
                "isActive": {
                  "type": "boolean",
                  "title": "Is Active"
                }
              }
            },
            {
              "properties": {
                "description": {
                  "type": "string",
                  "title": "Description"
                }
              }
            },
            {
              "properties": {
                "count": {
                  "type": "integer",
                  "title": "Count"
                }
              }
            }
          ]
        }
        """

    /// allOf with title and description inheritance
    private let titledAllOf = """
        {
          "type": "object",
          "title": "Root Title",
          "description": "Root Description",
          "allOf": [
            {
              "title": "Schema 1 Title",
              "properties": {
                "field1": {
                  "type": "string"
                }
              }
            },
            {
              "description": "Schema 2 Description",
              "properties": {
                "field2": {
                  "type": "string"
                }
              }
            }
          ]
        }
        """

    /// allOf with default values
    private let defaultValuesAllOf = """
        {
          "type": "object",
          "allOf": [
            {
              "properties": {
                "name": {
                  "type": "string",
                  "default": "John"
                }
              }
            },
            {
              "properties": {
                "age": {
                  "type": "integer",
                  "default": 25
                }
              }
            }
          ]
        }
        """

    /// Empty allOf array
    private let emptyAllOfSchema = """
        {
          "type": "object",
          "allOf": []
        }
        """

    /// Single schema in allOf
    private let singleSchemaAllOf = """
        {
          "type": "object",
          "allOf": [
            {
              "properties": {
                "solo": {
                  "type": "string",
                  "title": "Solo Field"
                }
              },
              "required": ["solo"]
            }
          ]
        }
        """

    /// allOf with nested object
    private let nestedObjectAllOf = """
        {
          "type": "object",
          "allOf": [
            {
              "properties": {
                "user": {
                  "type": "object",
                  "properties": {
                    "name": {
                      "type": "string"
                    }
                  }
                }
              }
            },
            {
              "properties": {
                "settings": {
                  "type": "object",
                  "properties": {
                    "theme": {
                      "type": "string"
                    }
                  }
                }
              }
            }
          ]
        }
        """

    /// allOf with required field union
    private let requiredUnionAllOf = """
        {
          "type": "object",
          "allOf": [
            {
              "properties": {
                "a": { "type": "string" },
                "b": { "type": "string" }
              },
              "required": ["a"]
            },
            {
              "properties": {
                "c": { "type": "string" },
                "d": { "type": "string" }
              },
              "required": ["c", "d"]
            }
          ]
        }
        """

    // MARK: - Helper Methods

    private func parseSchema(_ jsonString: String) throws -> JSONSchema {
        let preprocessed = try SchemaPreprocessor.preprocess(jsonString)
        return try JSONSchema(jsonString: preprocessed)
    }

    // MARK: - 1.1 Schema Parsing Tests

    /// Test that allOf schemas are correctly detected
    @MainActor
    func testAllOf_SchemaTypeDetection() async throws {
        let schema = try parseSchema(basicAllOfSchema)

        XCTAssertEqual(schema.type, .allOf, "Schema should be detected as allOf type")
        XCTAssertNotNil(schema.combinedSchema?.allOf, "Should have allOf array in combinedSchema")
    }

    /// Test that multiple sub-schemas are parsed correctly
    @MainActor
    func testAllOf_MultipleSubSchemas() async throws {
        let schema = try parseSchema(threeSchemaAllOf)

        XCTAssertEqual(schema.type, .allOf, "Schema should be allOf type")
        XCTAssertEqual(schema.combinedSchema?.allOf?.count, 3, "Should have 3 sub-schemas")

        // Verify each sub-schema has expected properties
        let allOfSchemas = schema.combinedSchema?.allOf ?? []
        XCTAssertTrue(allOfSchemas[0].objectSchema?.properties?["name"] != nil, "First schema should have 'name'")
        XCTAssertTrue(allOfSchemas[1].objectSchema?.properties?["age"] != nil, "Second schema should have 'age'")
        XCTAssertTrue(allOfSchemas[2].objectSchema?.properties?["email"] != nil, "Third schema should have 'email'")
    }

    /// Test that properties from all schemas are merged
    @MainActor
    func testAllOf_PropertyMerging() async throws {
        let schema = try parseSchema(basicAllOfSchema)
        let allOfSchemas = schema.combinedSchema?.allOf ?? []

        // Merge schemas using SchemaMerger
        let merged = SchemaMerger.merge(schemas: allOfSchemas, baseSchema: schema)

        XCTAssertEqual(merged.properties.count, 2, "Merged schema should have 2 properties")
        XCTAssertNotNil(merged.properties["firstName"], "Should have firstName property")
        XCTAssertNotNil(merged.properties["lastName"], "Should have lastName property")
    }

    // MARK: - 1.2 Property Merging Tests

    /// Test property override when same property exists in multiple schemas
    @MainActor
    func testAllOf_PropertyOverride() async throws {
        let schema = try parseSchema(propertyOverrideAllOf)
        let allOfSchemas = schema.combinedSchema?.allOf ?? []

        let merged = SchemaMerger.merge(schemas: allOfSchemas, baseSchema: schema)

        // Later schema should override earlier
        XCTAssertEqual(merged.properties.count, 1, "Should have 1 merged property")
        XCTAssertNotNil(merged.properties["value"], "Should have 'value' property")

        // The second schema's boolean type should win
        XCTAssertEqual(merged.properties["value"]?.type, .boolean, "Later schema type should override")
    }

    /// Test that required fields are unioned from all schemas
    @MainActor
    func testAllOf_RequiredFieldUnion() async throws {
        let schema = try parseSchema(requiredUnionAllOf)
        let allOfSchemas = schema.combinedSchema?.allOf ?? []

        let merged = SchemaMerger.merge(schemas: allOfSchemas, baseSchema: schema)

        // Required should be union: ["a"] + ["c", "d"] = ["a", "c", "d"]
        XCTAssertEqual(Set(merged.required), Set(["a", "c", "d"]), "Required should be union of all schemas")
    }

    /// Test title and description merging (first non-nil wins)
    @MainActor
    func testAllOf_TitleDescriptionMerge() async throws {
        let schema = try parseSchema(titledAllOf)
        let allOfSchemas = schema.combinedSchema?.allOf ?? []

        let merged = SchemaMerger.merge(schemas: allOfSchemas, baseSchema: schema)

        // Base schema title/description should be used first
        XCTAssertEqual(merged.title, "Root Title", "Root title should be preserved")
        XCTAssertEqual(merged.description, "Root Description", "Root description should be preserved")
    }

    /// Test default value handling in merged schemas
    @MainActor
    func testAllOf_DefaultValueMerge() async throws {
        let schema = try parseSchema(defaultValuesAllOf)
        let allOfSchemas = schema.combinedSchema?.allOf ?? []

        let merged = SchemaMerger.merge(schemas: allOfSchemas, baseSchema: schema)

        // Verify properties exist (defaults are handled at field level)
        XCTAssertNotNil(merged.properties["name"], "Should have name property")
        XCTAssertNotNil(merged.properties["age"], "Should have age property")
    }

    // MARK: - 1.3 UI Rendering Tests

    /// Test that boolean field renders as toggle
    @MainActor
    func testAllOf_RendersBooleanField() async throws {
        let schema = try parseSchema(mixedTypesAllOf)
        let formData = FormData.object(properties: [
            "isActive": .boolean(true),
            "description": .string("test"),
            "count": .number(5)
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Boolean should render as toggle
        let toggle = try form.inspect().find(viewWithId: "root_isActive").find(ViewType.Toggle.self)
        XCTAssertTrue(try toggle.isOn(), "Boolean toggle should be on")
    }

    /// Test that string field renders as text field
    @MainActor
    func testAllOf_RendersTextField() async throws {
        let schema = try parseSchema(basicAllOfSchema)
        let formData = FormData.object(properties: [
            "firstName": .string("John"),
            "lastName": .string("Doe")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // String should render as text field
        let firstNameField = try form.inspect().find(viewWithId: "root_firstName").find(ViewType.TextField.self)
        XCTAssertEqual(try firstNameField.input(), "John", "Text field should display value")

        let lastNameField = try form.inspect().find(viewWithId: "root_lastName").find(ViewType.TextField.self)
        XCTAssertEqual(try lastNameField.input(), "Doe", "Text field should display value")
    }

    /// Test that integer field renders as number field
    @MainActor
    func testAllOf_RendersNumberField() async throws {
        let schema = try parseSchema(mixedTypesAllOf)
        let formData = FormData.object(properties: [
            "isActive": .boolean(false),
            "description": .string("test"),
            "count": .number(42)
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Integer should render as text field (number input)
        let countField = try form.inspect().find(viewWithId: "root_count").find(ViewType.TextField.self)
        XCTAssertEqual(try countField.input(), "42", "Number field should display integer value")
    }

    /// Test that nested objects render correctly
    @MainActor
    func testAllOf_RendersNestedObject() async throws {
        let schema = try parseSchema(nestedObjectAllOf)
        let formData = FormData.object(properties: [
            "user": .object(properties: [
                "name": .string("Alice")
            ]),
            "settings": .object(properties: [
                "theme": .string("dark")
            ])
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify nested fields render
        let nameField = try form.inspect().find(viewWithId: "root_user_name").find(ViewType.TextField.self)
        XCTAssertEqual(try nameField.input(), "Alice", "Nested user.name should render")

        let themeField = try form.inspect().find(viewWithId: "root_settings_theme").find(ViewType.TextField.self)
        XCTAssertEqual(try themeField.input(), "dark", "Nested settings.theme should render")
    }

    /// Test that field IDs follow correct pattern
    @MainActor
    func testAllOf_FieldIdsAreCorrect() async throws {
        let schema = try parseSchema(threeSchemaAllOf)
        let formData = FormData.object(properties: [
            "name": .string("Test"),
            "age": .number(30),
            "email": .string("test@example.com")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify field IDs match expected pattern
        XCTAssertNoThrow(try form.inspect().find(viewWithId: "root_name"), "Should find root_name")
        XCTAssertNoThrow(try form.inspect().find(viewWithId: "root_age"), "Should find root_age")
        XCTAssertNoThrow(try form.inspect().find(viewWithId: "root_email"), "Should find root_email")
    }

    // MARK: - 1.4 Form Data Binding Tests

    /// Test that initial form data values display correctly
    @MainActor
    func testAllOf_InitialValueDisplay() async throws {
        let schema = try parseSchema(basicAllOfSchema)
        let formData = FormData.object(properties: [
            "firstName": .string("Initial First"),
            "lastName": .string("Initial Last")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        let firstNameField = try form.inspect().find(viewWithId: "root_firstName").find(ViewType.TextField.self)
        XCTAssertEqual(try firstNameField.input(), "Initial First", "Should display initial value")

        let lastNameField = try form.inspect().find(viewWithId: "root_lastName").find(ViewType.TextField.self)
        XCTAssertEqual(try lastNameField.input(), "Initial Last", "Should display initial value")
    }

    /// Test that form handles empty initial state
    @MainActor
    func testAllOf_EmptyInitialState() async throws {
        let schema = try parseSchema(basicAllOfSchema)
        let formData = FormData.object(properties: [:])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Form should render without crashing
        let _ = try form.inspect()
    }

    // MARK: - 1.5 Edge Case Tests

    /// Test empty allOf array handling
    @MainActor
    func testAllOf_EmptyAllOf() async throws {
        let schema = try parseSchema(emptyAllOfSchema)
        let formData = FormData.object(properties: [:])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Should render "Empty allOf schema" message
        let _ = try form.inspect()
    }

    /// Test single schema in allOf
    @MainActor
    func testAllOf_SingleSchema() async throws {
        let schema = try parseSchema(singleSchemaAllOf)
        let allOfSchemas = schema.combinedSchema?.allOf ?? []

        XCTAssertEqual(allOfSchemas.count, 1, "Should have exactly 1 sub-schema")

        let merged = SchemaMerger.merge(schemas: allOfSchemas, baseSchema: schema)
        XCTAssertEqual(merged.properties.count, 1, "Should have 1 property")
        XCTAssertNotNil(merged.properties["solo"], "Should have 'solo' property")
        XCTAssertEqual(merged.required, ["solo"], "Should have 'solo' as required")

        // Test rendering
        let formData = FormData.object(properties: [
            "solo": .string("single value")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        let soloField = try form.inspect().find(viewWithId: "root_solo").find(ViewType.TextField.self)
        XCTAssertEqual(try soloField.input(), "single value", "Single field should render")
    }

    /// Test allOf with $ref schemas (using testSchema19 pattern)
    @MainActor
    func testAllOf_WithRefs() async throws {
        // This tests the pattern from testSchema19 where allOf contains $refs
        let schemaWithRefs = """
            {
              "type": "object",
              "$defs": {
                "stringType": {
                  "type": "string"
                },
                "withMinLength": {
                  "minLength": 1
                }
              },
              "properties": {
                "field": {
                  "allOf": [
                    { "$ref": "#/$defs/stringType" },
                    { "$ref": "#/$defs/withMinLength" }
                  ]
                }
              }
            }
            """

        let schema = try parseSchema(schemaWithRefs)
        XCTAssertEqual(schema.type, .object, "Root should be object")

        // The field property should exist and be resolved
        XCTAssertNotNil(schema.objectSchema?.properties?["field"], "Should have field property")
    }

    // MARK: - 1.6 Integration Tests

    /// Detailed validation of testSchema13 allOf behavior
    @MainActor
    func testSchema13_AllOf_DetailedValidation() async throws {
        // testSchema13 has lorem (type array [string, boolean] -> boolean) and ipsum (string)
        let schema = try parseSchema(testSchema13)

        // Verify schema structure
        XCTAssertEqual(schema.type, .allOf, "Should be allOf type")
        XCTAssertEqual(schema.combinedSchema?.allOf?.count, 2, "Should have 2 allOf schemas")

        // Verify merged properties
        let allOfSchemas = schema.combinedSchema?.allOf ?? []
        let merged = SchemaMerger.merge(schemas: allOfSchemas, baseSchema: schema)

        XCTAssertEqual(merged.properties.count, 2, "Should have 2 merged properties")
        XCTAssertNotNil(merged.properties["lorem"], "Should have lorem")
        XCTAssertNotNil(merged.properties["ipsum"], "Should have ipsum")

        // lorem should be boolean (second schema overrides first)
        XCTAssertEqual(merged.properties["lorem"]?.type, .boolean, "Lorem should be boolean after override")

        // ipsum should be string
        XCTAssertEqual(merged.properties["ipsum"]?.type, .string, "Ipsum should be string")

        // Test form rendering
        let formData = FormData.object(properties: [
            "lorem": .boolean(true),
            "ipsum": .string("test ipsum")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Verify toggle for lorem
        let loremToggle = try form.inspect().find(viewWithId: "root_lorem").find(ViewType.Toggle.self)
        XCTAssertTrue(try loremToggle.isOn(), "Lorem toggle should be on")

        // Verify text field for ipsum
        let ipsumField = try form.inspect().find(viewWithId: "root_ipsum").find(ViewType.TextField.self)
        XCTAssertEqual(try ipsumField.input(), "test ipsum", "Ipsum should display value")
    }

    /// Test allOf with $ref resolution (testSchema19 pattern)
    @MainActor
    func testSchema19_AllOf_RefResolution() async throws {
        let schema = try parseSchema(testSchema19)

        // Root is object
        XCTAssertEqual(schema.type, .object, "Root should be object")

        // num property should exist
        XCTAssertNotNil(schema.objectSchema?.properties?["num"], "Should have num property")

        // num should be allOf type (combining integer + non-negative)
        let numSchema = schema.objectSchema?.properties?["num"]
        XCTAssertEqual(numSchema?.type, .allOf, "num should be allOf type")
        XCTAssertEqual(numSchema?.combinedSchema?.allOf?.count, 2, "num should combine 2 schemas")

        // Test form rendering with allOf field
        let formData = FormData.object(properties: [
            "num": .number(42)
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)

        // Form should render without crashing
        let _ = try form.inspect()
    }

    // MARK: - Additional Tests

    /// Test that allOf with all different property types works
    @MainActor
    func testAllOf_AllPropertyTypes() async throws {
        let allTypesSchema = """
            {
              "type": "object",
              "allOf": [
                {
                  "properties": {
                    "stringField": { "type": "string" },
                    "numberField": { "type": "number" }
                  }
                },
                {
                  "properties": {
                    "integerField": { "type": "integer" },
                    "booleanField": { "type": "boolean" }
                  }
                }
              ]
            }
            """

        let schema = try parseSchema(allTypesSchema)
        let allOfSchemas = schema.combinedSchema?.allOf ?? []
        let merged = SchemaMerger.merge(schemas: allOfSchemas, baseSchema: schema)

        XCTAssertEqual(merged.properties.count, 4, "Should merge all 4 properties")
        XCTAssertEqual(merged.properties["stringField"]?.type, .string)
        XCTAssertEqual(merged.properties["numberField"]?.type, .number)
        XCTAssertEqual(merged.properties["integerField"]?.type, .integer)
        XCTAssertEqual(merged.properties["booleanField"]?.type, .boolean)
    }

    /// Test SchemaMerger with no base schema
    @MainActor
    func testSchemaMerger_NoBaseSchema() async throws {
        let schema = try parseSchema(basicAllOfSchema)
        let allOfSchemas = schema.combinedSchema?.allOf ?? []

        // Merge without base schema
        let merged = SchemaMerger.merge(schemas: allOfSchemas, baseSchema: nil)

        XCTAssertEqual(merged.properties.count, 2, "Should still merge properties")
        XCTAssertEqual(Set(merged.required), Set(["firstName", "lastName"]), "Should merge required fields")
    }

    /// Test SchemaMerger isEmpty
    @MainActor
    func testSchemaMerger_IsEmpty() async throws {
        let schema = try parseSchema(emptyAllOfSchema)
        let allOfSchemas = schema.combinedSchema?.allOf ?? []

        let merged = SchemaMerger.merge(schemas: allOfSchemas, baseSchema: schema)

        XCTAssertTrue(merged.isEmpty, "Empty allOf should result in empty merged schema")
    }
}
