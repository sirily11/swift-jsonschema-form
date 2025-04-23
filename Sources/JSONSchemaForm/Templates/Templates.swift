import SwiftUI
import JSONSchema

/// Provides the default set of template components for the registry.
/// Corresponds to the function exported by `components/templates/index.ts` in RJSF.
///
/// - Returns: A dictionary mapping template names to their corresponding `TemplateComponent` (AnyView wrapping the specific template view).
func getDefaultTemplates() -> [String: TemplateComponent] {
    return [
        "ArrayFieldDescriptionTemplate": AnyView(ArrayFieldDescriptionTemplate()),
        "ArrayFieldItemTemplate": AnyView(ArrayFieldItemTemplate()),
        "ArrayFieldTemplate": AnyView(ArrayFieldTemplate()),
        "ArrayFieldTitleTemplate": AnyView(ArrayFieldTitleTemplate()),
        "BaseInputTemplate": AnyView(BaseInputTemplate()),
        // ButtonTemplates needs special handling as it's a collection itself
        // "ButtonTemplates": ???
        "DescriptionFieldTemplate": AnyView(DescriptionFieldTemplate()),
        "ErrorListTemplate": AnyView(ErrorListTemplate()),
        "FieldTemplate": AnyView(FieldTemplate()),
        "FieldErrorTemplate": AnyView(FieldErrorTemplate()),
        "FieldHelpTemplate": AnyView(FieldHelpTemplate()),
        "ObjectFieldTemplate": AnyView(ObjectFieldTemplate()),
        "TitleFieldTemplate": AnyView(TitleFieldTemplate()),
        "UnsupportedFieldTemplate": AnyView(UnsupportedFieldTemplate()),
        "WrapIfAdditionalTemplate": AnyView(WrapIfAdditionalTemplate()),
    ]
    // Note: Similar to fields, generics <T, S, F> might be needed later for actual implementations.
    // We'll also need to handle ButtonTemplates separately.
}

// Placeholder for ButtonTemplates structure (needs specific definition)
struct ButtonTemplatesView: View {
    // TODO: Define specific button views (e.g., Add, Remove, Submit)
    var body: some View {
        Text("Placeholder: ButtonTemplates")
    }
} 