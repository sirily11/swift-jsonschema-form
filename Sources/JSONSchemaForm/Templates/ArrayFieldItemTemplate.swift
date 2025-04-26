import SwiftUI
import JSONSchema

/// The ArrayFieldItemTemplate component renders an item in an array field.
struct ArrayFieldItemTemplate: View {
    let children: AnyView
    let className: String
    let disabled: Bool
    let hasCopy: Bool
    let hasMoveDown: Bool
    let hasMoveUp: Bool
    let hasRemove: Bool
    let hasToolbar: Bool
    let index: Int
    let totalItems: Int
    let onAddIndexClick: (Int) -> () -> Void
    let onCopyIndexClick: (Int) -> () -> Void
    let onDropIndexClick: (Int) -> () -> Void
    let onReorderClick: (Int, Int) -> () -> Void
    let readonly: Bool
    let key: String
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let registry: Registry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // The item content
            children
            
            // Toolbar with buttons if enabled
            if hasToolbar {
                HStack(spacing: 8) {
                    if hasMoveUp && index > 0 {
                        Button(action: {
                            onReorderClick(index, index - 1)()
                        } ) {
                            Image(systemName: "arrow.up")
                                .frame(width: 24, height: 24)
                        }
                        .disabled(disabled || readonly)
                    }
                    
                    if hasMoveDown && index < totalItems - 1 {
                        Button(action: {
                            onReorderClick(index, index + 1)()
                        }) {
                            Image(systemName: "arrow.down")
                                .frame(width: 24, height: 24)
                        }
                        .disabled(disabled || readonly)
                    }
                    
                    if hasCopy {
                        Button(action: {
                            onCopyIndexClick(index)()
                        }) {
                            Image(systemName: "doc.on.doc")
                                .frame(width: 24, height: 24)
                        }
                        .disabled(disabled || readonly)
                    }
                    
                    if hasRemove {
                        Button(action: {
                            onDropIndexClick(index)()
                        }) {
                            Image(systemName: "trash")
                                .frame(width: 24, height: 24)
                                .foregroundColor(.red)
                        }
                        .disabled(disabled || readonly)
                    }
                }
                .padding(.top, 5)
            }
        }
        .padding(.bottom, 10)
        .id(key)
    }
}

extension ArrayFieldItemTemplate {
    init(props: ArrayFieldItemTemplateProps) {
        self.children = props.children
        self.className = props.className
        self.disabled = props.disabled
        self.hasCopy = props.hasCopy
        self.hasMoveDown = props.hasMoveDown
        self.hasMoveUp = props.hasMoveUp
        self.hasRemove = props.hasRemove
        self.hasToolbar = props.hasToolbar
        self.index = props.index
        self.totalItems = props.totalItems
        self.onAddIndexClick = props.onAddIndexClick
        self.onCopyIndexClick = props.onCopyIndexClick
        self.onDropIndexClick = props.onDropIndexClick
        self.onReorderClick = props.onReorderClick
        self.readonly = props.readonly
        self.key = props.key
        self.schema = props.schema
        self.uiSchema = props.uiSchema
        self.registry = props.registry
    }
} 