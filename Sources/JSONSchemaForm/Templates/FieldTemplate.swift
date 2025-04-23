import SwiftUI
import JSONSchema

/// FieldTemplate provides the layout structure for rendering individual fields
struct FieldTemplate: View {
    var id: String
    var classNames: String?
    var label: String
    var description: String?
    var errors: [String]?
    var help: String?
    var hidden: Bool
    var required: Bool
    var readonly: Bool
    var displayLabel: Bool
    var content: AnyView
    
    init(
        id: String,
        classNames: String? = nil,
        label: String,
        description: String? = nil,
        errors: [String]? = nil,
        help: String? = nil,
        hidden: Bool = false,
        required: Bool = false,
        readonly: Bool = false,
        displayLabel: Bool = true,
        @ViewBuilder content: () -> AnyView
    ) {
        self.id = id
        self.classNames = classNames
        self.label = label
        self.description = description
        self.errors = errors
        self.help = help
        self.hidden = hidden
        self.required = required
        self.readonly = readonly
        self.displayLabel = displayLabel
        self.content = content()
    }

    init(props: FieldTemplateProps) {
        self.id = props.id
        self.classNames = props.classNames
        self.label = props.label
        self.description = props.description
        self.errors = props.errors
        self.help = props.help
        self.hidden = props.hidden
        self.required = props.required
        self.readonly = props.readonly
        self.displayLabel = props.displayLabel
        self.content = props.content()
    }
    
    var body: some View {
        if !hidden {
            VStack(alignment: .leading, spacing: 8) {
                // Field label
                if displayLabel && !label.isEmpty {
                    TitleField(id: "\(id)_title", title: label, required: required)
                }
                
                // Field description if available
                if let description = description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
                
                // Field content (the actual input widget)
                content
                    .disabled(readonly)
                
                // Field errors if any
                if let errors = errors, !errors.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(errors, id: \.self) { error in
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Help text if available
                if let help = help, !help.isEmpty {
                    Text(help)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .id(id)
            .padding(.vertical, 8)
        }
    }
} 