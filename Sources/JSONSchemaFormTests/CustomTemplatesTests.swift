import JSONSchema
import SwiftUI
import ViewInspector
import XCTest

@testable import JSONSchemaForm

final class CustomTemplatesTests: XCTestCase {
    @MainActor
    func testObjectTemplateResolvesNamedThenDefault() {
        let named: JSONSchemaFormObjectTemplate = { _ in AnyView(EmptyView()) }
        let fallback: JSONSchemaFormObjectTemplate = { _ in AnyView(EmptyView()) }

        let templates = JSONSchemaFormTemplates(
            objects: ["card": named],
            defaultObject: fallback)

        // Named match wins.
        XCTAssertNotNil(templates.object(for: "card"))
        // No name -> default object template.
        XCTAssertNotNil(templates.object(for: nil))
        // Unknown name -> default object template.
        XCTAssertNotNil(templates.object(for: "missing"))
    }

    @MainActor
    func testEmptyRegistryResolvesNothing() {
        let templates = JSONSchemaFormTemplates()
        XCTAssertTrue(templates.isEmpty)
        XCTAssertNil(templates.object(for: "card"))
        XCTAssertNil(templates.object(for: nil))
        XCTAssertNil(templates.field(for: "row"))
    }

    @MainActor
    func testFieldTemplateResolvesNamedThenDefault() {
        let named: JSONSchemaFormFieldTemplate = { _ in AnyView(EmptyView()) }
        let fallback: JSONSchemaFormFieldTemplate = { _ in AnyView(EmptyView()) }

        let templates = JSONSchemaFormTemplates(
            fields: ["row": named],
            defaultField: fallback)

        XCTAssertNotNil(templates.field(for: "row"))
        XCTAssertNotNil(templates.field(for: nil))
        XCTAssertNotNil(templates.field(for: "missing"))
    }

    @MainActor
    func testObjectTemplateContextCarriesRenderedProperties() {
        // The context exposes ordered, rendered child properties so a consumer
        // template can lay them out (e.g. a grouped card with dividers).
        let properties = [
            JSONSchemaFormObjectTemplateProperty(
                name: "topic", id: "root_topic", content: AnyView(EmptyView())),
            JSONSchemaFormObjectTemplateProperty(
                name: "language", id: "root_language", content: AnyView(EmptyView())),
        ]
        let context = JSONSchemaFormObjectTemplateContext(
            id: "root",
            title: "Settings",
            description: nil,
            required: false,
            uiSchema: nil,
            properties: properties)

        XCTAssertEqual(context.properties.map(\.name), ["topic", "language"])
        XCTAssertEqual(context.properties.map(\.id), ["root_topic", "root_language"])
    }
}
