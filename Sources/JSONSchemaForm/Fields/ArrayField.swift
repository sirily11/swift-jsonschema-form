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

    // Keep a stable field identifier for array items
    @State private var itemIds: [UUID] = []

    private var arraySchema: JSONSchema.ArraySchema? {
        guard case .array = schema.type else {
            return nil
        }
        return schema.arraySchema
    }

    var body: some View {
        Section(fieldTitle) {
            if case .array(let items) = formData.wrappedValue {
                // Display existing items
                if !items.isEmpty {
                    ForEach(0..<items.count, id: \.self) { index in
                        let itemId = getItemId(at: index)
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
                                    }),
                                required: true,
                                propertyName: propertyName
                            )
                        }
                        .id(itemId)  // Use a stable ID for each item
                    }
                } else {
                    Text("No items")
                        .foregroundColor(.secondary)
                        .italic()
                }
                // Add button
                Button("Add Item") {
                    addItem()
                }
            } else {
                InvalidValueType(
                    valueType: formData.wrappedValue,
                    expectedType: FormData.array(items: [])
                )
            }
        }
        .onAppear {
            // Initialize item IDs if needed
            initializeItemIds()
        }
    }

    // Get a stable ID for an item at the given index
    private func getItemId(at index: Int) -> UUID {
        // Ensure we have enough IDs
        while itemIds.count <= index {
            itemIds.append(UUID())
        }
        return itemIds[index]
    }

    // Initialize item IDs based on current formData
    private func initializeItemIds() {
        if case .array(let items) = formData.wrappedValue {
            // Create IDs for existing items if needed
            if itemIds.count < items.count {
                for _ in itemIds.count..<items.count {
                    itemIds.append(UUID())
                }
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
        var defaultValue: FormData?

        if let itemSchema = arraySchema?.items {
            defaultValue = createDefaultValue(for: itemSchema)
        }

        // Add a new UUID for this item
        itemIds.append(UUID())

        // Update the form data with the new item
        if case .array(var items) = formData.wrappedValue {
            items.append(defaultValue ?? FormData.null)
            formData.wrappedValue = FormData.array(items: items)
        }

    }

    // Remove an item at the specified index
    private func removeItem(at index: Int) {
        if case .array(var items) = formData.wrappedValue {
            items.remove(at: index)
            formData.wrappedValue = FormData.array(items: items)
        }
        // Also remove the ID
        if index < itemIds.count {
            itemIds.remove(at: index)
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
