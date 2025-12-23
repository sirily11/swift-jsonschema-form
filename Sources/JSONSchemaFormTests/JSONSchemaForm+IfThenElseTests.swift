import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

/// Tests for if/then/else conditional schema support
class JSONSchemaFormIfThenElseTests: XCTestCase {
    override func setUp() {
        super.setUp()
        executionTimeAllowance = 30
    }

    /// Helper to parse schema with preprocessing and extract conditionals
    private func parseSchemaWithConditionals(_ jsonString: String) throws -> (JSONSchema, [ConditionalSchema]) {
        let preprocessed = try SchemaPreprocessor.preprocessWithConditionals(jsonString)
        let schema = try JSONSchema(jsonString: preprocessed.jsonString)
        return (schema, preprocessed.conditionals)
    }

    /// Helper to parse schema without conditionals (for backwards compatibility)
    private func parseSchema(_ jsonString: String) throws -> JSONSchema {
        let preprocessed = try SchemaPreprocessor.preprocess(jsonString)
        return try JSONSchema(jsonString: preprocessed)
    }

    // MARK: - Unit Tests: Condition Evaluator

    /// Test const condition evaluation
    @MainActor
    func testEvaluateConstCondition() async throws {
        // Condition: animal == "Cat"
        let condition: [String: Any] = [
            "properties": [
                "animal": ["const": "Cat"]
            ]
        ]

        // FormData with animal = "Cat" should match
        let matchingFormData = FormData.object(properties: [
            "animal": .string("Cat")
        ])
        XCTAssertTrue(
            ConditionEvaluator.evaluate(condition: condition, formData: matchingFormData),
            "Condition should match when animal is Cat"
        )

        // FormData with animal = "Fish" should not match
        let nonMatchingFormData = FormData.object(properties: [
            "animal": .string("Fish")
        ])
        XCTAssertFalse(
            ConditionEvaluator.evaluate(condition: condition, formData: nonMatchingFormData),
            "Condition should not match when animal is Fish"
        )

        // FormData without animal property should not match
        let emptyFormData = FormData.object(properties: [:])
        XCTAssertFalse(
            ConditionEvaluator.evaluate(condition: condition, formData: emptyFormData),
            "Condition should not match when animal property is missing"
        )
    }

    /// Test enum condition evaluation
    @MainActor
    func testEvaluateEnumCondition() async throws {
        // Condition: animal is one of ["Cat", "Dog"]
        let condition: [String: Any] = [
            "properties": [
                "animal": ["enum": ["Cat", "Dog"]]
            ]
        ]

        // FormData with animal = "Cat" should match
        let catFormData = FormData.object(properties: [
            "animal": .string("Cat")
        ])
        XCTAssertTrue(
            ConditionEvaluator.evaluate(condition: condition, formData: catFormData),
            "Condition should match when animal is Cat"
        )

        // FormData with animal = "Dog" should match
        let dogFormData = FormData.object(properties: [
            "animal": .string("Dog")
        ])
        XCTAssertTrue(
            ConditionEvaluator.evaluate(condition: condition, formData: dogFormData),
            "Condition should match when animal is Dog"
        )

        // FormData with animal = "Fish" should not match
        let fishFormData = FormData.object(properties: [
            "animal": .string("Fish")
        ])
        XCTAssertFalse(
            ConditionEvaluator.evaluate(condition: condition, formData: fishFormData),
            "Condition should not match when animal is Fish"
        )
    }

    /// Test required condition evaluation
    @MainActor
    func testEvaluateRequiredCondition() async throws {
        // Condition: animal field is required
        let condition: [String: Any] = [
            "required": ["animal"]
        ]

        // FormData with animal should match
        let formDataWithAnimal = FormData.object(properties: [
            "animal": .string("Cat")
        ])
        XCTAssertTrue(
            ConditionEvaluator.evaluate(condition: condition, formData: formDataWithAnimal),
            "Condition should match when required field exists"
        )

        // FormData without animal should not match
        let formDataWithoutAnimal = FormData.object(properties: [:])
        XCTAssertFalse(
            ConditionEvaluator.evaluate(condition: condition, formData: formDataWithoutAnimal),
            "Condition should not match when required field is missing"
        )

        // FormData with null animal should not match
        let formDataWithNullAnimal = FormData.object(properties: [
            "animal": .null
        ])
        XCTAssertFalse(
            ConditionEvaluator.evaluate(condition: condition, formData: formDataWithNullAnimal),
            "Condition should not match when required field is null"
        )
    }

    // MARK: - Unit Tests: Preprocessor Extraction

    /// Test that preprocessor extracts if/then/else from allOf
    @MainActor
    func testPreprocessorExtractsIfThenElse() async throws {
        let (schema, conditionals) = try parseSchemaWithConditionals(testSchema14)

        // Should have extracted 2 conditionals (Cat and Fish conditions)
        XCTAssertEqual(conditionals.count, 2, "Should extract 2 conditionals from testSchema14")

        // First conditional should be for Cat
        let catConditional = conditionals[0]
        XCTAssertNotNil(catConditional.thenSchema, "Cat conditional should have then schema")

        // Second conditional should be for Fish
        let fishConditional = conditionals[1]
        XCTAssertNotNil(fishConditional.thenSchema, "Fish conditional should have then schema")
    }

    /// Test that preprocessor preserves non-conditional allOf schemas
    @MainActor
    func testPreprocessorPreservesNonConditionalAllOf() async throws {
        let preprocessed = try SchemaPreprocessor.preprocessWithConditionals(testSchema14)
        let schema = try JSONSchema(jsonString: preprocessed.jsonString)

        // Schema should be allOf type
        XCTAssertEqual(schema.type, .allOf, "Schema type should be allOf")

        // allOf should have schemas
        let allOfSchemas = schema.combinedSchema?.allOf ?? []
        XCTAssertFalse(allOfSchemas.isEmpty, "allOf should have schemas")

        // The animal property should be in one of the allOf schemas
        var foundAnimal = false
        for subSchema in allOfSchemas {
            if subSchema.objectSchema?.properties?["animal"] != nil {
                foundAnimal = true
                break
            }
        }
        XCTAssertTrue(foundAnimal, "Animal property should be in one of the allOf schemas")
    }

    // MARK: - Integration Tests: Static

    /// Test Cat selection shows correct food options
    @MainActor
    func testSchema14_CatSelection() async throws {
        let (schema, conditionals) = try parseSchemaWithConditionals(testSchema14)
        let formData = FormData.object(properties: [
            "animal": .string("Cat")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data, conditionalSchemas: conditionals)

        // Form should render
        let view = try form.inspect()

        // Animal field should be visible
        let animalField = try view.find(viewWithId: "root_animal_enum_field")
        XCTAssertNotNil(animalField, "Animal field should be visible")

        // Food field should be visible when Cat is selected
        let foodField = try view.find(viewWithId: "root_food_enum_field")
        XCTAssertNotNil(foodField, "Food field should be visible for Cat")

        // Water field should NOT be visible for Cat
        XCTAssertThrowsError(
            try view.find(viewWithId: "root_water_enum_field"),
            "Water field should not be visible for Cat"
        )
    }

    /// Test Fish selection shows both food and water options
    @MainActor
    func testSchema14_FishSelection() async throws {
        let (schema, conditionals) = try parseSchemaWithConditionals(testSchema14)
        let formData = FormData.object(properties: [
            "animal": .string("Fish")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data, conditionalSchemas: conditionals)

        // Form should render
        let view = try form.inspect()

        // Animal field should be visible
        let animalField = try view.find(viewWithId: "root_animal_enum_field")
        XCTAssertNotNil(animalField, "Animal field should be visible")

        // Food field should be visible when Fish is selected
        let foodField = try view.find(viewWithId: "root_food_enum_field")
        XCTAssertNotNil(foodField, "Food field should be visible for Fish")

        // Water field should be visible for Fish
        let waterField = try view.find(viewWithId: "root_water_enum_field")
        XCTAssertNotNil(waterField, "Water field should be visible for Fish")
    }

    /// Test no selection shows no conditional fields
    @MainActor
    func testSchema14_NoSelection() async throws {
        let (schema, conditionals) = try parseSchemaWithConditionals(testSchema14)
        let formData = FormData.object(properties: [:])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data, conditionalSchemas: conditionals)

        // Form should render
        let view = try form.inspect()

        // Food and water fields should NOT be visible without animal selection
        XCTAssertThrowsError(
            try view.find(viewWithId: "root_food_enum_field"),
            "Food field should not be visible without animal selection"
        )
        XCTAssertThrowsError(
            try view.find(viewWithId: "root_water_enum_field"),
            "Water field should not be visible without animal selection"
        )
    }

    // MARK: - Dynamic Interaction Tests

    /// Test switching from Cat to Fish updates visible fields
    @MainActor
    func testDynamicSwitchCatToFish() async throws {
        let (schema, conditionals) = try parseSchemaWithConditionals(testSchema14)

        // Start with Cat
        var formData = FormData.object(properties: [
            "animal": .string("Cat"),
            "food": .string("meat")
        ])
        let binding = Binding(
            get: { formData },
            set: { formData = $0 }
        )
        var form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)

        // Initial state: Cat selected, food visible, water not visible
        var view = try form.inspect()
        XCTAssertNoThrow(try view.find(viewWithId: "root_food_enum_field"), "Food should be visible for Cat")
        XCTAssertThrowsError(try view.find(viewWithId: "root_water_enum_field"), "Water should not be visible for Cat")

        // Switch to Fish
        formData = FormData.object(properties: [
            "animal": .string("Fish")
        ])
        form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)

        // After switch: Fish selected, food and water visible
        view = try form.inspect()
        XCTAssertNoThrow(try view.find(viewWithId: "root_food_enum_field"), "Food should be visible for Fish")
        XCTAssertNoThrow(try view.find(viewWithId: "root_water_enum_field"), "Water should be visible for Fish")
    }

    /// Test switching from Fish to Cat updates visible fields
    @MainActor
    func testDynamicSwitchFishToCat() async throws {
        let (schema, conditionals) = try parseSchemaWithConditionals(testSchema14)

        // Start with Fish
        var formData = FormData.object(properties: [
            "animal": .string("Fish"),
            "food": .string("insect"),
            "water": .string("lake")
        ])
        let binding = Binding(
            get: { formData },
            set: { formData = $0 }
        )
        var form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)

        // Initial state: Fish selected, food and water visible
        var view = try form.inspect()
        XCTAssertNoThrow(try view.find(viewWithId: "root_food_enum_field"), "Food should be visible for Fish")
        XCTAssertNoThrow(try view.find(viewWithId: "root_water_enum_field"), "Water should be visible for Fish")

        // Switch to Cat
        formData = FormData.object(properties: [
            "animal": .string("Cat")
        ])
        form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)

        // After switch: Cat selected, only food visible
        view = try form.inspect()
        XCTAssertNoThrow(try view.find(viewWithId: "root_food_enum_field"), "Food should be visible for Cat")
        XCTAssertThrowsError(try view.find(viewWithId: "root_water_enum_field"), "Water should not be visible for Cat")
    }

    /// Test starting with empty selection then selecting Cat
    @MainActor
    func testDynamicFromEmptyToCat() async throws {
        let (schema, conditionals) = try parseSchemaWithConditionals(testSchema14)

        // Start with no selection
        var formData = FormData.object(properties: [:])
        let binding = Binding(
            get: { formData },
            set: { formData = $0 }
        )
        var form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)

        // Initial state: no conditional fields visible
        var view = try form.inspect()
        XCTAssertThrowsError(try view.find(viewWithId: "root_food_enum_field"), "Food should not be visible initially")

        // Select Cat
        formData = FormData.object(properties: [
            "animal": .string("Cat")
        ])
        form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)

        // After selection: food visible
        view = try form.inspect()
        XCTAssertNoThrow(try view.find(viewWithId: "root_food_enum_field"), "Food should be visible after selecting Cat")
    }

    /// Test starting with empty selection then selecting Fish
    @MainActor
    func testDynamicFromEmptyToFish() async throws {
        let (schema, conditionals) = try parseSchemaWithConditionals(testSchema14)

        // Start with no selection
        var formData = FormData.object(properties: [:])
        let binding = Binding(
            get: { formData },
            set: { formData = $0 }
        )
        var form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)

        // Initial state: no conditional fields visible
        var view = try form.inspect()
        XCTAssertThrowsError(try view.find(viewWithId: "root_food_enum_field"), "Food should not be visible initially")
        XCTAssertThrowsError(try view.find(viewWithId: "root_water_enum_field"), "Water should not be visible initially")

        // Select Fish
        formData = FormData.object(properties: [
            "animal": .string("Fish")
        ])
        form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)

        // After selection: both food and water visible
        view = try form.inspect()
        XCTAssertNoThrow(try view.find(viewWithId: "root_food_enum_field"), "Food should be visible after selecting Fish")
        XCTAssertNoThrow(try view.find(viewWithId: "root_water_enum_field"), "Water should be visible after selecting Fish")
    }

    /// Test clearing selection hides conditional fields
    @MainActor
    func testDynamicClearSelection() async throws {
        let (schema, conditionals) = try parseSchemaWithConditionals(testSchema14)

        // Start with Cat
        var formData = FormData.object(properties: [
            "animal": .string("Cat"),
            "food": .string("meat")
        ])
        let binding = Binding(
            get: { formData },
            set: { formData = $0 }
        )
        var form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)

        // Initial state: food visible
        var view = try form.inspect()
        XCTAssertNoThrow(try view.find(viewWithId: "root_food_enum_field"), "Food should be visible for Cat")

        // Clear selection
        formData = FormData.object(properties: [:])
        form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)

        // After clearing: no conditional fields visible
        view = try form.inspect()
        XCTAssertThrowsError(try view.find(viewWithId: "root_food_enum_field"), "Food should not be visible after clearing")
    }

    // MARK: - Edge Cases

    /// Test if without then or else is handled gracefully
    @MainActor
    func testIfWithoutThenOrElse() async throws {
        let schemaWithOnlyIf = """
        {
            "type": "object",
            "properties": {
                "name": { "type": "string" }
            },
            "allOf": [
                {
                    "if": {
                        "properties": { "name": { "const": "test" } }
                    }
                }
            ]
        }
        """

        let (schema, conditionals) = try parseSchemaWithConditionals(schemaWithOnlyIf)

        // Should have extracted 1 conditional
        XCTAssertEqual(conditionals.count, 1, "Should extract 1 conditional")

        // Conditional should have nil then and else
        XCTAssertNil(conditionals[0].thenSchema, "Then schema should be nil")
        XCTAssertNil(conditionals[0].elseSchema, "Else schema should be nil")

        // Form should still render without errors
        let formData = FormData.object(properties: [
            "name": .string("test")
        ])
        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data, conditionalSchemas: conditionals)
        XCTAssertNoThrow(try form.inspect(), "Form should render without errors")
    }

    /// Test else schema is applied when condition fails
    @MainActor
    func testElseSchemaApplied() async throws {
        let schemaWithElse = """
        {
            "type": "object",
            "properties": {
                "animal": { "enum": ["Cat", "Fish"] }
            },
            "allOf": [
                {
                    "if": {
                        "properties": { "animal": { "const": "Cat" } }
                    },
                    "then": {
                        "properties": {
                            "catFood": { "type": "string", "enum": ["meat", "fish"] }
                        }
                    },
                    "else": {
                        "properties": {
                            "otherFood": { "type": "string", "enum": ["generic"] }
                        }
                    }
                }
            ]
        }
        """

        let (schema, conditionals) = try parseSchemaWithConditionals(schemaWithElse)

        // Test with Cat - should show catFood, not otherFood
        var formData = FormData.object(properties: [
            "animal": .string("Cat")
        ])
        var binding = Binding(wrappedValue: formData)
        var form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)
        var view = try form.inspect()

        XCTAssertNoThrow(try view.find(viewWithId: "root_catFood_enum_field"), "catFood should be visible for Cat")
        XCTAssertThrowsError(try view.find(viewWithId: "root_otherFood_enum_field"), "otherFood should not be visible for Cat")

        // Test with Fish - should show otherFood (else branch)
        formData = FormData.object(properties: [
            "animal": .string("Fish")
        ])
        binding = Binding(wrappedValue: formData)
        form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)
        view = try form.inspect()

        XCTAssertThrowsError(try view.find(viewWithId: "root_catFood_enum_field"), "catFood should not be visible for Fish")
        XCTAssertNoThrow(try view.find(viewWithId: "root_otherFood_enum_field"), "otherFood should be visible for Fish")
    }

    /// Test multiple condition changes in sequence
    @MainActor
    func testMultipleConditionChanges() async throws {
        let (schema, conditionals) = try parseSchemaWithConditionals(testSchema14)

        var formData = FormData.object(properties: [:])
        let binding = Binding(
            get: { formData },
            set: { formData = $0 }
        )

        // Initial: empty
        var form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)
        var view = try form.inspect()
        XCTAssertThrowsError(try view.find(viewWithId: "root_food_enum_field"))

        // Change 1: Cat
        formData = FormData.object(properties: ["animal": .string("Cat")])
        form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)
        view = try form.inspect()
        XCTAssertNoThrow(try view.find(viewWithId: "root_food_enum_field"))
        XCTAssertThrowsError(try view.find(viewWithId: "root_water_enum_field"))

        // Change 2: Fish
        formData = FormData.object(properties: ["animal": .string("Fish")])
        form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)
        view = try form.inspect()
        XCTAssertNoThrow(try view.find(viewWithId: "root_food_enum_field"))
        XCTAssertNoThrow(try view.find(viewWithId: "root_water_enum_field"))

        // Change 3: Cat again
        formData = FormData.object(properties: ["animal": .string("Cat")])
        form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)
        view = try form.inspect()
        XCTAssertNoThrow(try view.find(viewWithId: "root_food_enum_field"))
        XCTAssertThrowsError(try view.find(viewWithId: "root_water_enum_field"))

        // Change 4: Empty
        formData = FormData.object(properties: [:])
        form = JSONSchemaForm(schema: schema, formData: binding, conditionalSchemas: conditionals)
        view = try form.inspect()
        XCTAssertThrowsError(try view.find(viewWithId: "root_food_enum_field"))
        XCTAssertThrowsError(try view.find(viewWithId: "root_water_enum_field"))
    }
}
