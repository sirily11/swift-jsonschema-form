import XCTest

@testable import JSONSchemaForm

final class FormFieldMetadataTests: XCTestCase {
    func testOptionsPreferXOptionsLabels() {
        let field = JSONSchemaFormFieldMetadata(
            id: "language",
            schema: [
                "title": "Language",
                "description": "The language used for planning and generation.",
                "enum": ["en-US", "zh-CN"],
                "x-options": [
                    ["id": "en-US", "label": "English"],
                    ["id": "zh-CN", "label": "Chinese (Simplified)", "description": "Simplified Chinese"]
                ]
            ])

        XCTAssertEqual(field.title, "Language")
        XCTAssertEqual(field.description, "The language used for planning and generation.")
        XCTAssertEqual(field.options, [
            JSONSchemaFormFieldOption(id: "en-US", label: "English", description: nil),
            JSONSchemaFormFieldOption(id: "zh-CN", label: "Chinese (Simplified)", description: "Simplified Chinese")
        ])
    }

    func testOptionsFallBackToEnumValues() {
        let field = JSONSchemaFormFieldMetadata(
            id: "template",
            schema: [
                "enum": ["default", "research"]
            ])

        XCTAssertEqual(field.title, "template")
        XCTAssertEqual(field.options, [
            JSONSchemaFormFieldOption(id: "default", label: "default", description: nil),
            JSONSchemaFormFieldOption(id: "research", label: "research", description: nil)
        ])
    }

    func testIntegerBoundsParseFromSchema() {
        let field = JSONSchemaFormFieldMetadata(
            id: "discussants",
            schema: [
                "minimum": 2,
                "maximum": 6
            ])

        XCTAssertEqual(field.minimumInt, 2)
        XCTAssertEqual(field.maximumInt, 6)
    }
}
