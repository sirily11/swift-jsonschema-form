import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

class JSONSchemaFormEnumTests: XCTestCase {
    @MainActor
    func testEnumFieldWithPredefinedStringValue() async throws {
        let formData = FormData.object(properties: [
            "interval": .string("10s")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "interval": {
                            "type": "string",
                            "enum": ["1s", "10s", "30s"]
                        }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)
        let enumField = try form.inspect().find(viewWithId: "root_interval_enum_field")
        let picker = try enumField.find(ViewType.Picker.self)
        // The picker selection should be the EnumValue with displayName "10s"
        try picker.select(value: EnumValue(value: "10s", displayName: "10s"))
        // If selection succeeds without error, it means "10s" was already a valid tag
        // Verify formData still holds "10s"
        XCTAssertEqual(data.wrappedValue.object?["interval"], .string("10s"))
    }

    @MainActor
    func testEnumFieldWithNullFormDataDefaultsToEmpty() async throws {
        let formData = FormData.object(properties: [
            "interval": .null
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "interval": {
                            "type": "string",
                            "enum": ["1s", "10s", "30s"]
                        }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)
        let enumField = try form.inspect().find(viewWithId: "root_interval_enum_field")
        let picker = try enumField.find(ViewType.Picker.self)
        // Select a value and verify it updates formData
        try picker.select(value: EnumValue(value: "30s", displayName: "30s"))
        let onChangeView = try form.inspect().find(viewWithId: "root_interval_enum_field")
        try onChangeView.callOnChange(
            oldValue: EnumValue.emptyEnum,
            newValue: EnumValue(value: "30s", displayName: "30s"))
        XCTAssertEqual(data.wrappedValue.object?["interval"], .string("30s"))
    }

    @MainActor
    func testEnumFieldOnChangeUpdatesFormData() async throws {
        let formData = FormData.object(properties: [
            "interval": .string("1s")
        ])
        let schema = try JSONSchema(
            jsonString: """
                {
                    "type": "object",
                    "properties": {
                        "interval": {
                            "type": "string",
                            "enum": ["1s", "10s", "30s"]
                        }
                    }
                }
                """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(schema: schema, formData: data)
        let enumField = try form.inspect().find(viewWithId: "root_interval_enum_field")
        // Trigger onChange to simulate user selecting "30s"
        try enumField.callOnChange(
            oldValue: EnumValue(value: "1s", displayName: "1s"),
            newValue: EnumValue(value: "30s", displayName: "30s"))
        XCTAssertEqual(data.wrappedValue.object?["interval"], .string("30s"))
    }
}
