import JSONSchema
import SwiftUI

/// Implements an array field that can render as a list of items with add/remove capabilities
struct ArrayField: Field {
    var schema: JSONSchema
    var uiSchema: [String: Any]?
    var id: String
    var formData: [Any]?
    var required: Bool
    var onChange: ([Any]?) -> Void
    
    // Options for the array field
    private var options: ArrayFieldOptions {
        // Default options
        var opts = ArrayFieldOptions(
            orderable: true,
            addable: true,
            removable: true
        )
        
        // Override with UI schema options if provided
        if let uiSchema = uiSchema,
           let uiOptions = uiSchema["ui:options"] as? [String: Any]
        {
            if let orderable = uiOptions["orderable"] as? Bool {
                opts.orderable = orderable
            }
            if let addable = uiOptions["addable"] as? Bool {
                opts.addable = addable
            }
            if let removable = uiOptions["removable"] as? Bool {
                opts.removable = removable
            }
        }
        
        return opts
    }
    
    // Extract item schema from the array schema
    private var itemSchema: JSONSchema? {
        // TODO: Implement schema extraction logic
        return nil
    }
    
    // Safe access to formData with an empty array fallback
    private var items: [Any] {
        return formData ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Render the field title if present
            if !fieldTitle.isEmpty {
                Text(fieldTitle)
                    .font(.headline)
            }
            
            // Render the array items
            ForEach(0 ..< items.count, id: \.self) { index in
                arrayItemView(for: index)
            }
            
            // Add button if the array is addable
            if options.addable {
                addButton()
            }
        }
    }
    
    // View for a single array item
    private func arrayItemView(for index: Int) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                // Item content (placeholder - would need specific field rendering)
                Text("Item \(index + 1)")
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                
                Spacer()
                
                // Item toolbar with move up/down/remove buttons
                if options.orderable || options.removable {
                    HStack(spacing: 8) {
                        // Move up button
                        if options.orderable && index > 0 {
                            Button(action: {
                                moveItemUp(at: index)
                            }) {
                                Image(systemName: "arrow.up")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Move down button
                        if options.orderable && index < items.count - 1 {
                            Button(action: {
                                moveItemDown(at: index)
                            }) {
                                Image(systemName: "arrow.down")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Remove button
                        if options.removable {
                            Button(action: {
                                removeItem(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // Add button view
    private func addButton() -> some View {
        Button(action: {
            addItem()
        }) {
            HStack {
                Image(systemName: "plus")
                Text("Add Item")
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Array manipulation methods
    
    private func addItem() {
        var newArray = items
        
        // Add empty item (in a real implementation, this would create a default based on the schema)
        // This is simplified - would need type-specific handling
        newArray.append("New Item")
        
        onChange(newArray)
    }
    
    private func removeItem(at index: Int) {
        var newArray = items
        
        if index >= 0 && index < newArray.count {
            newArray.remove(at: index)
            onChange(newArray.isEmpty ? nil : newArray)
        }
    }
    
    private func moveItemUp(at index: Int) {
        guard index > 0 && index < items.count else {
            return
        }
        
        var newArray = items
        newArray.swapAt(index, index - 1)
        onChange(newArray)
    }
    
    private func moveItemDown(at index: Int) {
        guard index >= 0 && index < items.count - 1 else {
            return
        }
        
        var newArray = items
        newArray.swapAt(index, index + 1)
        onChange(newArray)
    }
}

// Helper struct for array field options
private struct ArrayFieldOptions {
    var orderable: Bool
    var addable: Bool
    var removable: Bool
}
