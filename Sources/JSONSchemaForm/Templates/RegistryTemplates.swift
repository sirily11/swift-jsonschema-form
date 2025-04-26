import SwiftUI
import JSONSchema

/// Registry struct for JSONSchemaForm to keep track of templates, fields, widgets, etc.
public struct Registry {
    var templates: TemplatesType
    var fields: [String: AnyView]
    var widgets: [String: AnyView]
    var formContext: [String: Any]?
    var rootSchema: JSONSchema
    var globalUiOptions: [String: Any]?
    
    init(
        templates: TemplatesType,
        fields: [String: AnyView] = [:],
        widgets: [String: AnyView] = [:],
        formContext: [String: Any]? = nil,
        rootSchema: JSONSchema,
        globalUiOptions: [String: Any]? = nil
    ) {
        self.templates = templates
        self.fields = fields
        self.widgets = widgets
        self.formContext = formContext
        self.rootSchema = rootSchema
        self.globalUiOptions = globalUiOptions
    }
    
    /// Get a field by name, falling back to default fields if not found
    func getField(name: String) -> AnyView {
        if let field = fields[name] {
            return field
        }
        
        // If field not found, return an UnsupportedField view
        return AnyView(Text("Unsupported field: \(name)"))
    }
    
    /// Get a widget by name, falling back to default widgets if not found
    func getWidget(name: String) -> AnyView {
        if let widget = widgets[name] {
            return widget
        }
        
        // If widget not found, return a default Text widget
        return AnyView(Text("Unsupported widget: \(name)"))
    }
}

/// Type holding all the template functions
public struct TemplatesType {
    var arrayFieldTemplate: (ArrayFieldTemplateProps) -> AnyView
    var arrayFieldDescriptionTemplate: (ArrayFieldDescriptionTemplateProps) -> AnyView
    var arrayFieldItemTemplate: (ArrayFieldItemTemplateProps) -> AnyView 
    var arrayFieldTitleTemplate: (ArrayFieldTitleTemplateProps) -> AnyView
    var baseInputTemplate: (BaseInputTemplateProps) -> AnyView
    var descriptionFieldTemplate: (DescriptionFieldTemplateProps) -> AnyView
    var errorListTemplate: (ErrorListTemplateProps) -> AnyView
    var fieldErrorTemplate: (FieldErrorTemplateProps) -> AnyView
    var fieldHelpTemplate: (FieldHelpTemplateProps) -> AnyView
    var fieldTemplate: (FieldTemplateProps) -> AnyView
    var objectFieldTemplate: (ObjectFieldTemplateProps) -> AnyView
    var titleFieldTemplate: (TitleFieldTemplateProps) -> AnyView
    var unsupportedFieldTemplate: (UnsupportedFieldTemplateProps) -> AnyView
    var wrapIfAdditionalTemplate: (WrapIfAdditionalTemplateProps) -> AnyView
    
    var buttonTemplates: ButtonTemplates
}

/// Function to get default template functions
@MainActor
func getDefaultTemplates() -> TemplatesType {
    return TemplatesType(
        arrayFieldTemplate: { props in
            AnyView(ArrayFieldTemplate(props: props))
        },
        arrayFieldDescriptionTemplate: { props in
            AnyView(ArrayFieldDescriptionTemplate(props: props))
        },
        arrayFieldItemTemplate: { props in
            AnyView(ArrayFieldItemTemplate(props: props))
        },
        arrayFieldTitleTemplate: { props in
            AnyView(ArrayFieldTitleTemplate(props: props))
        },
        baseInputTemplate: { props in
            AnyView(BaseInputTemplate(props: props))
        },
        descriptionFieldTemplate: { props in
            AnyView(DescriptionFieldTemplate(props: props))
        },
        errorListTemplate: { props in
            AnyView(ErrorListTemplate(props: props))
        },
        fieldErrorTemplate: { props in
            AnyView(FieldErrorTemplate(props: props))
        },
        fieldHelpTemplate: { props in
            AnyView(FieldHelpTemplate(props: props))
        },
        fieldTemplate: { props in
            AnyView(FieldTemplate(props: props))
        },
        objectFieldTemplate: { props in
            AnyView(ObjectFieldTemplate(props: props))
        },
        titleFieldTemplate: { props in
            AnyView(TitleFieldTemplate(props: props))
        },
        unsupportedFieldTemplate: { props in
            AnyView(UnsupportedFieldTemplate(props: props))
        },
        wrapIfAdditionalTemplate: { props in
            AnyView(WrapIfAdditionalTemplate(props: props))
        },
        buttonTemplates: ButtonTemplates(
            submitButton: AnyView(Text("Submit")),
            addButton: AnyView(Text("Add")),
            copyButton: AnyView(Text("Copy")),
            moveDownButton: AnyView(Text("Move Down")),
            moveUpButton: AnyView(Text("Move Up")),
            removeButton: AnyView(Text("Remove"))
        )
    )
}

/// Creates a default registry instance
@MainActor
func getDefaultRegistry(rootSchema: JSONSchema) -> Registry {
    return Registry(
        templates: getDefaultTemplates(),
        rootSchema: rootSchema
    )
} 