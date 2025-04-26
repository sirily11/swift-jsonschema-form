import SwiftUI
import JSONSchema

/// Represents a property in an object field
struct ObjectFieldProperty {
    var content: AnyView
    var name: String
    var disabled: Bool
    var readonly: Bool
    var hidden: Bool
}

/// ObjectFieldTemplate provides layout for object fields and their properties
struct ObjectFieldTemplate: View {
    var title: String
    var description: String?
    var properties: [ObjectFieldProperty]
    var required: Bool
    var readonly: Bool
    var disabled: Bool
    var onAddClick: (() -> Void)?
    var addButton: AnyView
    
    init(
        title: String,
        description: String? = nil,
        properties: [ObjectFieldProperty],
        required: Bool = false,
        readonly: Bool = false,
        disabled: Bool = false,
        onAddClick: (() -> Void)? = nil,
        @ViewBuilder addButton: () -> AnyView
    ) {
        self.title = title
        self.description = description
        self.properties = properties
        self.required = required
        self.readonly = readonly
        self.disabled = disabled
        self.onAddClick = onAddClick
        self.addButton = addButton()
    }

    init(props: ObjectFieldTemplateProps) {
        self.title = props.title
        self.description = props.description
        self.properties = props.properties
        self.required = props.required
        self.readonly = props.readonly
        self.disabled = props.disabled
        self.onAddClick = props.onAddClick
        self.addButton = props.addButton()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title for the object
            if !title.isEmpty {
                TitleField(id: "object_title", title: title, required: required)
            }
            
            // Description if provided
            if let description = description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
            
            // Each property in the object
            ForEach(properties.indices, id: \.self) { index in
                let property = properties[index]
                
                if !property.hidden {
                    VStack(alignment: .leading) {
                        property.content
                            .disabled(property.disabled || disabled || readonly)
                    }
                    .padding(.vertical, 4)
                    
                    // Add a divider between properties (except after the last one)
                    if index < properties.count - 1 {
                        Divider()
                    }
                }
            }
            
            // "Add" button for additional properties if provided
            if let onAddClick = onAddClick {
                Button(action: onAddClick) {
                    addButton
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
} 