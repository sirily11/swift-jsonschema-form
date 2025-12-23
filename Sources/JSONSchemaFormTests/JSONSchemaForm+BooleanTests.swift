import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

// can toggle on and off
// seems to be a bug in the view inspector
class JSONSchemaFormBooleanTests: XCTestCase {
    @MainActor
    func testBooleanTrue() async throws {
        let formData = FormData.object(properties: [
            "isActive": .boolean(true)
        ])
        let schema = try JSONSchema(
            jsonString: """
            {
                "type": "object",
                "properties": {
                    "isActive": { "type": "boolean" }
                },
                "required": ["isActive"]
            }
            """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema, formData: data)
        // find the toggle
        let toggle = try form.inspect().find(viewWithId: "root_isActive").find(ViewType.Toggle.self)
        // toggle the value
        let isOn = try toggle.isOn()
        XCTAssertTrue(isOn)
        // toggle the value
        try toggle.tap()
    }

    @MainActor
    func testBooleanFalse() async throws {
        let formData = FormData.object(properties: [
            "isActive": .boolean(false)
        ])
        let schema = try JSONSchema(
            jsonString: """
            {
                "type": "object",
                "properties": {
                    "isActive": { "type": "boolean" }
                },
                "required": ["isActive"]
            }
            """)

        let data = Binding(wrappedValue: formData)
        let form = JSONSchemaForm(
            schema: schema, formData: data)
        // find the toggle
        let toggle = try form.inspect().find(viewWithId: "root_isActive").find(ViewType.Toggle.self)
        // toggle the value
        let isOn = try toggle.isOn()
        XCTAssertFalse(isOn)
    }
}
