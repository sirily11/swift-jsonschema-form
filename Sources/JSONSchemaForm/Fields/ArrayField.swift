import JSONSchema
import SwiftUI

/// Implements a field for array values
struct ArrayField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: Binding<FormData>
    var required: Bool
    var propertyName: String?

    /// Access to the form controller for field-level error display
    @Environment(\.formController) private var formController

    /// Returns field-level errors for this field from the controller
    private var currentFieldErrors: [String]? {
        guard let errors = formController?.errorsForField(id), !errors.isEmpty else {
            return nil
        }
        return errors
    }

    private var arraySchema: JSONSchema.ArraySchema? {
        guard case .array = schema.type else {
            return nil
        }
        return schema.arraySchema
    }

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(fieldTitle)
                    if let description = schema.description{
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
            .padding(.bottom, 8)
            arrayfieldBody()

            // Display field-level errors
            if let errors = currentFieldErrors, !errors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(errors, id: \.self) { error in
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    func arrayfieldBody() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if case .array(let items) = formData.wrappedValue {
                // Display existing items
                if !items.isEmpty {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, _ in
                        let itemIdString = "\(id)_\(index)"

                        // Get the item schema
                        let itemSchema = arraySchema?.items ?? .string()

                        // Render the item with its own schema field
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Item \(index + 1)")
                                    .font(.headline)

                                Spacer()

                                // Remove button
                                Button(action: {
                                    removeItem(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }

                            // Render the appropriate field for this item
                            SchemaField(
                                schema: itemSchema,
                                uiSchema: getItemUiSchema(),
                                id: itemIdString,
                                formData: Binding(
                                    get: { items[index] },
                                    set: { newValue in
                                        var updatedItems = items
                                        updatedItems[index] = newValue
                                        formData.wrappedValue = FormData.array(items: updatedItems)
                                    }
                                ),
                                required: true,
                                propertyName: propertyName
                            )
                        }
                    }
                } else {
                    Text("No items")
                        .foregroundColor(.secondary)
                        .italic()
                }

                // Right-aligned Add button
                HStack {
                    Spacer()
                    Button("Add Item") {
                        addItem()
                    }
                }
            } else {
                InvalidValueType(
                    valueType: formData.wrappedValue,
                    expectedType: FormData.array(items: [])
                )
            }
        }
    }

    // Get the UI schema for array items
    private func getItemUiSchema() -> [String: Any]? {
        return uiSchema?["items"] as? [String: Any]
    }

    // Add a new item
    private func addItem() {
        // Create default value based on item schema
        let defaultValue: FormData
        if let itemSchema = arraySchema?.items {
            defaultValue = createDefaultValue(for: itemSchema)
        } else {
            defaultValue = FormData.null
        }

        // Update the form data with the new item
        if case .array(var items) = formData.wrappedValue {
            items.append(defaultValue)
            formData.wrappedValue = FormData.array(items: items)
        }
    }

    // Remove an item at the specified index
    private func removeItem(at index: Int) {
        if case .array(var items) = formData.wrappedValue {
            items.remove(at: index)
            formData.wrappedValue = FormData.array(items: items)
        }
    }

    // Update an item at the specified index
    private func updateItem(at index: Int, value: FormData) {
        if case .array(var items) = formData.wrappedValue {
            // Ensure the array is large enough
            while items.count <= index {
                items.append(FormData.null)
            }

            items[index] = value
            formData.wrappedValue = FormData.array(items: items)
        }
    }

    // Create a default value for a schema
    private func createDefaultValue(for schema: JSONSchema) -> FormData {
        switch schema.type {
        case .string:
            return FormData.string("")
        case .number, .integer:
            return FormData.number(0)
        case .boolean:
            return FormData.boolean(false)
        case .array:
            return FormData.array(items: [])
        case .object:
            return FormData.object(properties: [:])
        default:
            return FormData.null
        }
    }
}

// Helper struct for array field options
private struct ArrayFieldOptions {
    var orderable: Bool
    var addable: Bool
    var removable: Bool
}

#Preview {
    @Previewable @State var formData = FormData.array(items: [
        .string("Item 1"),
        .string("Item 2"),
        .string("Item 3"),
    ])

    let schema = JSONSchema.array(
        title: "Tags",
        items: .string()
    )

    Form {
        ArrayField(
            schema: schema,
            uiSchema: nil,
            id: "root_tags",
            formData: $formData,
            required: false,
            propertyName: "tags"
        )
    }
    .formStyle(.grouped)
}
