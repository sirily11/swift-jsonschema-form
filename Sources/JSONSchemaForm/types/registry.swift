import JSONSchema

/// The set of `Fields` stored in the `Registry`
public typealias RegistryFieldsType<T, S: JSONSchema, F> = [String: any Field]

/// The set of `Templates` stored in the `Registry`
public typealias RegistryTemplatesType<T, S: JSONSchema, F> = [String: any Template]

/// The set of `Widgets` stored in the `Registry`
public typealias RegistryWidgetsType<T, S: JSONSchema, F> = [String: any Widget]

/// The object containing the registered core, theme and custom fields and widgets as well as the root schema, form
/// context, schema utils and templates.
public struct Registry<T, S: JSONSchema, F> {
    /// The set of all fields used by the `Form`. Includes fields from `core`, theme-specific fields and any custom
    /// registered fields
    public var fields: RegistryFieldsType<T, S, F>

    /// The set of templates used by the `Form`. Includes templates from `core`, theme-specific fields and any custom
    /// registered templates
    public var templates: RegistryTemplatesType<T, S, F>

    /// The set of all widgets used by the `Form`. Includes widgets from `core`, theme-specific widgets and any custom
    /// registered widgets
    public var widgets: RegistryWidgetsType<T, S, F>

    /// The `formContext` object that was passed to `Form`
    public var formContext: F

    /// The root schema, as passed to the `Form`, which can contain referenced definitions
    public var rootSchema: S

    /// The current implementation of the `SchemaUtilsType` (from `@rjsf/utils`) in use by the `Form`.  Used to call any
    /// of the validation-schema-based utility functions
    var schemaUtils: any SchemaUtilsType

    /// The string translation function to use when displaying any of the RJSF strings in templates, fields or widgets
    public var translateString: (_ stringKey: String, _ params: [String]?) -> String

    /// The optional global UI Options that are available for all templates, fields and widgets to access
    public var globalUiOptions: GlobalUISchemaOptions?
}
