import SwiftUI
import JSONSchema

struct BaseInputTemplateProps {
    let id: String
    let schema: JSONSchema
    let type: String
    let value: Any?
    let required: Bool
    let disabled: Bool
    let readonly: Bool
    let autofocus: Bool
    let onChange: (Any?) -> Void
    let onBlur: (String, Any?) -> Void
    let onFocus: (String, Any?) -> Void
    let placeholder: String?
    let uiSchema: [String: Any]?
    let registry: Registry
}

struct ErrorListTemplateProps {
    let errors: [FormValidationError]
    let errorSchema: [String: Any]?
}

struct FieldHelpTemplateProps {
    let help: String?
    let idSchema: [String: Any]
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let hasErrors: Bool
    let registry: Registry
}

struct TitleFieldTemplateProps {
    let id: String
    let title: String
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let required: Bool?
    let registry: Registry
}


struct UnsupportedFieldTemplateProps {
    let id: String
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let registry: Registry
}

struct WrapIfAdditionalTemplateProps {
    let children: AnyView
    let id: String
    let classNames: String?
    let style: [String: Any]?
    let label: String
    let required: Bool
    let readonly: Bool
    let disabled: Bool
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let onKeyChange: (String) -> () -> Void
    let onDropPropertyClick: (String) -> () -> Void
    let registry: Registry
}



/// Props for ArrayFieldDescriptionTemplate
struct ArrayFieldDescriptionTemplateProps {
    let idSchema: [String: Any]
    let description: String?
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let registry: Registry
}

/// Props for ArrayFieldItemTemplate
struct ArrayFieldItemTemplateProps {
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
}

/// Props for ArrayFieldTemplate
struct ArrayFieldTemplateProps {
    let canAdd: Bool
    let className: String
    let disabled: Bool
    let idSchema: [String: Any]
    let description: String?
    let items: [ArrayFieldItem]
    let onAddClick: () -> Void
    let readonly: Bool
    let required: Bool
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let title: String
    let formContext: [String: Any]?
    let formData: Any?
    let registry: Registry
    let addButton: () ->  AnyView
}

/// Props for ArrayFieldTitleTemplate
struct ArrayFieldTitleTemplateProps {
    let idSchema: [String: Any]
    let title: String?
    let required: Bool
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let registry: Registry
}

/// Props for FieldTemplateProps
struct FieldTemplateProps {
    let id: String
    let classNames: String?
    let label: String
    let description: String?
    let rawDescription: String?
    let children: AnyView
    let errors: [String]?
    let rawErrors: [String]?
    let help: String?
    let rawHelp: String?
    let hidden: Bool
    let required: Bool
    let readonly: Bool
    let disabled: Bool
    let displayLabel: Bool
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let formContext: [String: Any]?
    let formData: Any?
    let registry: Registry
    let content: () -> AnyView
}

/// Props for ObjectFieldTemplate
struct ObjectFieldTemplateProps {
    let title: String
    let description: String?
    let disabled: Bool
    let properties: [ObjectFieldProperty]
    let onAddClick: (() -> Void)?
    let readonly: Bool
    let required: Bool
    let schema: JSONSchema
    let uiSchema: [String: Any]?
    let idSchema: [String: Any]
    let formData: Any?
    let formContext: [String: Any]?
    let registry: Registry
    let addButton: () ->  AnyView
}

/// Type for ObjectFieldTemplate properties
struct ObjectFieldTemplatePropertyType {
    let content: AnyView
    let name: String
    let disabled: Bool
    let readonly: Bool
    let hidden: Bool
}

/// Props for ButtonTemplates
struct ButtonTemplateProps {
    let uiSchema: [String: Any]?
    let registry: Registry
}