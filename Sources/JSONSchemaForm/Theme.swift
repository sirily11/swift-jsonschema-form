// ... existing code ...
struct Theme<T, S: Schema, F> {
    /// A dictionary of custom field components, keyed by field name or type.
    var fields: [String: FieldComponent]?

    /// A dictionary of custom template components, keyed by template name.
    var templates: [String: TemplateComponent]?

    /// A dictionary of custom widget components, keyed by widget name.
    var widgets: [String: WidgetComponent]?

    /// Custom button templates.
    var buttonTemplates: ButtonTemplates? // Add optional button templates override

    // Note: _internalFormWrapper from RJSF is likely React-specific

    init(
        fields: [String: FieldComponent]? = nil,
        templates: [String: TemplateComponent]? = nil,
        widgets: [String: WidgetComponent]? = nil,
        buttonTemplates: ButtonTemplates? = nil // Add to initializer
    ) {
        self.fields = fields
        self.templates = templates
        self.widgets = widgets
        self.buttonTemplates = buttonTemplates // Assign in initializer
    }
}
// ... existing code ...