// The Swift Programming Language
// https://docs.swift.org/swift-book

import JSONSchema
import SwiftUI

struct JSONSchemaForm: View {
    let schema: JSONSchema

    init(schema: JSONSchema) {
        self.schema = schema
    }

    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    JSONSchemaForm(
        schema: .object(
            description: "Some field",
            properties: [
                "name": .string(description: "Some field"),
                "age": .integer(description: "Some field"),
                "isActive": .boolean(description: "Some field"),
                "email": .string(description: "Some field"),
                "interests": .array(
                    description: "Some field",
                    items: .string(description: "Some field")
                ),
                "address": .object(
                    description: "Some object",
                    properties: [
                        "city": .enum(
                            description: "List of city",
                            values: [
                                .string("New York"),
                                .string("Los Angeles"),
                                .string("Chicago"),
                                .string("Houston"),
                                .string("Miami"),
                                .string("San Francisco"),
                                .string("San Francisco"),
                            ])
                    ],
                    required: ["city", "street"]
                ),
            ],
            required: ["someField"]
        )
    )
}
