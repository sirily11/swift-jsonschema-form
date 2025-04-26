import SwiftUI
import JSONSchema

/// Registry maintains references to all fields, widgets, and templates
/// used by JSONSchemaForm, allowing for customization and extension.
struct RegistryUtils {
    /// Custom fields dictionary keyed by field type
    var fields: [FieldType: any Field]
    
    /// Custom widgets dictionary keyed by name
    var widgets: [String: AnyView]
    
    /// Root schema for resolving references
    var rootSchema: JSONSchema
    
    /// Form context for sharing data between fields
    var formContext: [String: Any]?
    
    /// Utility for schema operations
    var schemaUtils: SchemaUtilsType
    
    /// Global UI options that apply to the entire form
    var globalUiOptions: [String: Any]?
    
    init(
        fields: [FieldType: any Field] = [:],
        widgets: [String: AnyView] = [:],
        rootSchema: JSONSchema,
        formContext: [String: Any]? = nil,
        globalUiOptions: [String: Any]? = nil
    ) {
        self.fields = fields
        self.widgets = widgets
        self.rootSchema = rootSchema
        self.formContext = formContext
        self.globalUiOptions = globalUiOptions
        
        // Initialize schema utils with the root schema
        self.schemaUtils = SchemaUtilsType(schema: rootSchema)
    }
    
    /// Get default fields for the form
    func getDefaultFields() -> [FieldType: any Field] {
        // TODO: Implement properly with actual default fields
        return [:]
    }
    
    /// Get a field by type, falling back to default fields if not found
    @MainActor
    func getField(for type: FieldType) ->  AnyView {
        if let field = fields[type] {
            return AnyView(field)
        }
        
        // Fall back to default fields
        let defaultFields = getDefaultFields()
        if let field = defaultFields[type] {
            return  AnyView(field)
        } else {
            return AnyView(UnsupportedField(reason: "Unsupported field type: \(type)"))
        }
    }
    
    /// Get a widget by name
    func getWidget(name: String) -> AnyView? {
        return widgets[name]
    }
}

/// Schema utilities for resolving references, handling defaults, etc.
struct SchemaUtilsType {
    let schema: JSONSchema
    
    /// Retrieve the schema for a field, resolving any $refs
    func retrieveSchema(_ fieldSchema: JSONSchema, formData: Any? = nil) -> JSONSchema {
        // In a real implementation, this would handle $ref resolution
        // and schema dependencies based on formData
        return fieldSchema
    }
    
    /// Convert a schema to an IdSchema tree
    func toIdSchema(_ schema: JSONSchema, rootId: String?, formData: Any?, idPrefix: String? = nil, idSeparator: String? = nil) -> [String: Any] {
        // In a real implementation, this would create a tree of ids for all fields
        return ["$id": rootId ?? "root"]
    }
    
    /// Get default form state based on schema
    func getDefaultFormState(_ schema: JSONSchema, formData: Any? = nil) -> Any? {
        // In a real implementation, this would create default values based on the schema
        return formData
    }
} 