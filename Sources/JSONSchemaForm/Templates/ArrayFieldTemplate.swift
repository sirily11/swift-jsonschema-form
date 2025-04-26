import SwiftUI
import JSONSchema

/// Represents an item in an array field
struct ArrayFieldItem {
    var children: AnyView
    var key: String
    var index: Int
    var disabled: Bool
    var readonly: Bool
    var hasMoveUp: Bool
    var hasMoveDown: Bool
    var hasRemove: Bool
    var onReorderClick: ((Int, Int) -> Void)?
    var onDropIndexClick: ((Int) -> Void)?
    var description: String?
    var items: [ArrayFieldItem]
}

/// ArrayFieldTemplate provides layout for array fields and their items
struct ArrayFieldTemplate: View {
    var title: String
    var description: String?
    var items: [ArrayFieldItem]
    var canAdd: Bool
    var readonly: Bool
    var disabled: Bool
    var required: Bool
    var onAddClick: (() -> Void)?
    var addButton: AnyView
    
    init(
        title: String,
        description: String? = nil,
        items: [ArrayFieldItem],
        canAdd: Bool = true,
        readonly: Bool = false,
        disabled: Bool = false,
        required: Bool = false,
        onAddClick: (() -> Void)? = nil,
        @ViewBuilder addButton: () -> AnyView
    ) {
        self.title = title
        self.description = description
        self.items = items
        self.canAdd = canAdd
        self.readonly = readonly
        self.disabled = disabled
        self.required = required
        self.onAddClick = onAddClick
        self.addButton = addButton()
    }

    init(props: ArrayFieldTemplateProps) {
        self.title = props.title
        self.description = props.description
        self.items = props.items
        self.canAdd = props.canAdd
        self.readonly = props.readonly
        self.disabled = props.disabled
        self.required = props.required
        self.onAddClick = props.onAddClick
        self.addButton = props.addButton()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title for the array
            if !title.isEmpty {
                TitleField(id: "array_title", title: title, required: required)
            }
            
            // Description if provided
            if let description = description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            
            // No items message if array is empty
            if items.isEmpty {
                Text("No items")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 8)
            }
            
            // Each item in the array
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        // Item index/number
                        Text("#\(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                            .padding(.top, 8)
                        
                        // Item content
                        VStack(alignment: .leading) {
                            item.children
                                .disabled(disabled || readonly || item.disabled || item.readonly)
                        }
                        .padding(.vertical, 4)
                        
                        // Item controls (move up/down, remove)
                        if !readonly && !disabled {
                            VStack(spacing: 8) {
                                // Move up button
                                if item.hasMoveUp {
                                    Button(action: {
                                        item.onReorderClick?(index, index - 1)
                                    }) {
                                        Image(systemName: "arrow.up")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // Move down button
                                if item.hasMoveDown {
                                    Button(action: {
                                        item.onReorderClick?(index, index + 1)
                                    }) {
                                        Image(systemName: "arrow.down")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // Remove button
                                if item.hasRemove {
                                    Button(action: {
                                        item.onDropIndexClick?(index)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                .id(item.key)
                
                if index < items.count - 1 {
                    Spacer().frame(height: 8)
                }
            }
            
            // "Add" button if items can be added
            if canAdd && !readonly && !disabled && onAddClick != nil {
                Button(action: {
                    onAddClick?()
                }) {
                    addButton
                }
                .padding(.top, 8)
            }
        }
    }
} 