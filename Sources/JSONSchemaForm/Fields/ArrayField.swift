import JSONSchema
import SwiftUI

/// Implements a field for array values
struct ArrayField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: [Any]?
    var required: Bool
    var onChange: ([Any]?) -> Void
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
            // Display existing items
            if let formData = formData, !formData.isEmpty {
                ForEach(0..<formData.count, id: \.self) { index in
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
                            formData: formData[index],
                            required: true,
                            onChange: { newValue in
                                updateItem(at: index, value: newValue)
                            },
                            propertyName: propertyName
                        )
                    }
                    .id(itemId) // Use a stable ID for each item
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
        if let data = formData {
            // Create IDs for existing items if needed
            if itemIds.count < data.count {
                for _ in itemIds.count..<data.count {
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
        var defaultValue: Any?
        
        if let itemSchema = arraySchema?.items {
            defaultValue = createDefaultValue(for: itemSchema)
        }
        
        // Add a new UUID for this item
        itemIds.append(UUID())
        
        // Update the form data with the new item
        var updatedFormData = formData ?? []
        updatedFormData.append(defaultValue ?? NSNull())
        onChange(updatedFormData)
    }
    
    // Remove an item at the specified index
    private func removeItem(at index: Int) {
        var updatedFormData = formData ?? []
        
        if index < updatedFormData.count {
            updatedFormData.remove(at: index)
            
            // Also remove the ID
            if index < itemIds.count {
                itemIds.remove(at: index)
            }
            
            onChange(updatedFormData)
        }
    }
    
    // Update an item at the specified index
    private func updateItem(at index: Int, value: Any?) {
        var updatedFormData = formData ?? []
        
        // Ensure the array is large enough
        while updatedFormData.count <= index {
            updatedFormData.append(NSNull())
        }
        
        if let value = value {
            updatedFormData[index] = value
        } else {
            updatedFormData[index] = NSNull()
        }
        
        onChange(updatedFormData)
    }
    
    // Create a default value for a schema
    private func createDefaultValue(for schema: JSONSchema) -> Any? {
        switch schema.type {
        case .string:
            return ""
        case .number, .integer:
            return 0
        case .boolean:
            return false
        case .array:
            return []
        case .object:
            return [String: Any]()
        default:
            return nil
        }
    }
}

// Helper struct for array field options
private struct ArrayFieldOptions {
    var orderable: Bool
    var addable: Bool
    var removable: Bool
}
