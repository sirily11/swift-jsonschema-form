import SwiftUI

// MARK: - Object Field Template

/// A single property rendered inside a custom object template. `content` is the
/// fully rendered child field (already dispatched through `SchemaField`).
public struct JSONSchemaFormObjectTemplateProperty: Identifiable {
    public let name: String
    public let id: String
    public let content: AnyView

    public init(name: String, id: String, content: AnyView) {
        self.name = name
        self.id = id
        self.content = content
    }
}

/// Context handed to a custom object template, mirroring rjsf's `ObjectFieldTemplate`.
public struct JSONSchemaFormObjectTemplateContext {
    public let id: String
    public let title: String
    public let description: String?
    public let required: Bool
    public let uiSchema: [String: Any]?
    public let properties: [JSONSchemaFormObjectTemplateProperty]
}

public typealias JSONSchemaFormObjectTemplate = @MainActor @Sendable (JSONSchemaFormObjectTemplateContext) -> AnyView

// MARK: - Field Template

/// Context handed to a custom field (leaf) template, mirroring rjsf's `FieldTemplate`.
/// `content` is the rendered input widget for the field.
public struct JSONSchemaFormFieldTemplateContext {
    public let id: String
    public let label: String
    public let description: String?
    public let errors: [String]?
    public let required: Bool
    public let readonly: Bool
    public let uiSchema: [String: Any]?
    public let content: AnyView
}

public typealias JSONSchemaFormFieldTemplate = @MainActor @Sendable (JSONSchemaFormFieldTemplateContext) -> AnyView

// MARK: - Registry

/// A registry of custom templates, selected per-field via `ui:objectTemplate` /
/// `ui:fieldTemplate` names, with optional defaults applied when no name matches.
///
/// When no template (named or default) resolves for an object, the form falls back
/// to the built-in `Section` layout, keeping behaviour unchanged for consumers that
/// do not opt in.
public struct JSONSchemaFormTemplates: Sendable {
    public var objects: [String: JSONSchemaFormObjectTemplate]
    public var fields: [String: JSONSchemaFormFieldTemplate]
    public var defaultObject: JSONSchemaFormObjectTemplate?
    public var defaultField: JSONSchemaFormFieldTemplate?

    public init(
        objects: [String: JSONSchemaFormObjectTemplate] = [:],
        fields: [String: JSONSchemaFormFieldTemplate] = [:],
        defaultObject: JSONSchemaFormObjectTemplate? = nil,
        defaultField: JSONSchemaFormFieldTemplate? = nil
    ) {
        self.objects = objects
        self.fields = fields
        self.defaultObject = defaultObject
        self.defaultField = defaultField
    }

    public var isEmpty: Bool {
        objects.isEmpty && fields.isEmpty && defaultObject == nil && defaultField == nil
    }

    /// Resolve an object template by name, falling back to the default object template.
    func object(for name: String?) -> JSONSchemaFormObjectTemplate? {
        if let name, let template = objects[name] { return template }
        return defaultObject
    }

    /// Resolve a field template by name, falling back to the default field template.
    func field(for name: String?) -> JSONSchemaFormFieldTemplate? {
        if let name, let template = fields[name] { return template }
        return defaultField
    }
}

// MARK: - Environment

struct FormTemplatesKey: EnvironmentKey {
    static let defaultValue = JSONSchemaFormTemplates()
}

extension EnvironmentValues {
    /// Custom object/field templates injected by `JSONSchemaForm`.
    var formTemplates: JSONSchemaFormTemplates {
        get { self[FormTemplatesKey.self] }
        set { self[FormTemplatesKey.self] = newValue }
    }
}

// MARK: - Field template host

/// Wraps a leaf field's input widget, using a custom field template from the
/// environment when one is registered (by `ui:fieldTemplate` name or default),
/// otherwise the built-in `FieldTemplate`.
struct TemplatedField<Content: View>: View {
    @Environment(\.formTemplates) private var templates

    let id: String
    let label: String
    let description: String?
    let errors: [String]?
    let required: Bool
    let readonly: Bool
    let uiSchema: [String: Any]?
    @ViewBuilder var content: () -> Content

    init(
        id: String,
        label: String,
        description: String? = nil,
        errors: [String]? = nil,
        required: Bool = false,
        readonly: Bool = false,
        uiSchema: [String: Any]? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self.label = label
        self.description = description
        self.errors = errors
        self.required = required
        self.readonly = readonly
        self.uiSchema = uiSchema
        self.content = content
    }

    var body: some View {
        let name = uiSchema?["ui:fieldTemplate"] as? String
        if let template = templates.field(for: name) {
            template(
                JSONSchemaFormFieldTemplateContext(
                    id: id,
                    label: label,
                    description: description,
                    errors: errors,
                    required: required,
                    readonly: readonly,
                    uiSchema: uiSchema,
                    content: AnyView(content())
                ))
        } else {
            FieldTemplate(
                id: id,
                label: label,
                description: description,
                errors: errors,
                required: required,
                readonly: readonly
            ) {
                content()
            }
        }
    }
}
