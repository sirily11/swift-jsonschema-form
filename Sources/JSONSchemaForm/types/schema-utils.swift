import Foundation
import JSONSchema

/// The `SchemaUtilsType` protocol provides a wrapper around the publicly exported APIs in the schema
/// utilities such that one does not have to explicitly pass the `validator` or `rootSchema` to each method. Since both
/// the `validator` and `rootSchema` generally does not change across a `Form`, this allows for providing a simplified
/// set of APIs to the core components and the various themes as well.
protocol SchemaUtilsType {
    associatedtype T
    associatedtype S: JSONSchema
    associatedtype F

    /// Returns the `ValidatorType` in the `SchemaUtilsType`
    ///
    /// - Returns: The `ValidatorType`
    func getValidator() -> any ValidatorType<T, S, F>

    /// Determines whether either the `validator` and `rootSchema` differ from the ones associated with this instance of
    /// the `SchemaUtilsType`. If either `validator` or `rootSchema` are falsy, then return false to prevent the creation
    /// of a new `SchemaUtilsType` with incomplete properties.
    ///
    /// - Parameters:
    ///   - validator: An implementation of the `ValidatorType` protocol that will be compared against the current one
    ///   - rootSchema: The root schema that will be compared against the current one
    ///   - experimental_defaultFormStateBehavior: Optional configuration object, if provided, allows users to override default form state behavior
    ///   - experimental_customMergeAllOf: Optional function that allows for custom merging of `allOf` schemas
    /// - Returns: True if the `SchemaUtilsType` differs from the given `validator` or `rootSchema`
    func doesSchemaUtilsDiffer(
        validator: any ValidatorType<T, S, F>,
        rootSchema: S
    ) -> Bool

    /// Returns the superset of `formData` that includes the given set updated to include any missing fields that have
    /// computed to have defaults provided in the `schema`.
    ///
    /// - Parameters:
    ///   - schema: The schema for which the default state is desired
    ///   - formData: The current formData, if any, onto which to provide any missing defaults
    ///   - includeUndefinedValues: Optional flag, if true, cause undefined values to be added as defaults.
    ///        If "excludeObjectChildren", cause undefined values for this object and pass `includeUndefinedValues` as
    ///        false when computing defaults for any nested object properties.
    /// - Returns: The resulting `formData` with all the defaults provided
    func getDefaultFormState(
        schema: S,
        formData: T?,
        includeUndefinedValues: IncludeUndefinedValues
    ) -> T?

    /// Determines whether the combination of `schema` and `uiSchema` properties indicates that the label for the `schema`
    /// should be displayed in a UI.
    ///
    /// - Parameters:
    ///   - schema: The schema for which the display label flag is desired
    ///   - uiSchema: The UI schema from which to derive potentially displayable information
    ///   - globalOptions: The Global UI Schema from which to get any fallback options
    /// - Returns: True if the label should be displayed or false if it should not
    func getDisplayLabel(
        schema: S,
        uiSchema: UISchema<T, S, F>?,
        globalOptions: GlobalUISchemaOptions
    ) -> Bool

    /// Determines which of the given `options` provided most closely matches the `formData`.
    /// Returns the index of the option that is valid and is the closest match, or 0 if there is no match.
    ///
    /// The closest match is determined using the number of matching properties, and more heavily favors options with
    /// matching readOnly, default, or const values.
    ///
    /// - Parameters:
    ///   - formData: The form data associated with the schema
    ///   - options: The list of options that can be selected from
    ///   - selectedOption: The index of the currently selected option, defaulted to -1 if not specified
    ///   - discriminatorField: The optional name of the field within the options object whose value is used to
    ///        determine which option is selected
    /// - Returns: The index of the option that is the closest match to the `formData` or the `selectedOption` if no match
    func getClosestMatchingOption(
        formData: T?,
        options: [S],
        selectedOption: Int?,
        discriminatorField: String?
    ) -> Int

    /// Given the `formData` and list of `options`, attempts to find the index of the first option that matches the data.
    /// Always returns the first option if there is nothing that matches.
    ///
    /// - Parameters:
    ///   - formData: The current formData, if any, used to figure out a match
    ///   - options: The list of options to find a matching options from
    ///   - discriminatorField: The optional name of the field within the options object whose value is used to
    ///        determine which option is selected
    /// - Returns: The first index of the matched option or 0 if none is available
    func getFirstMatchingOption(
        formData: T?,
        options: [S],
        discriminatorField: String?
    ) -> Int

    /// Given the `formData` and list of `options`, attempts to find the index of the option that best matches the data.
    /// Deprecated, use `getFirstMatchingOption()` instead.
    ///
    /// - Parameters:
    ///   - formData: The current formData, if any, onto which to provide any missing defaults
    ///   - options: The list of options to find a matching options from
    ///   - discriminatorField: The optional name of the field within the options object whose value is used to
    ///        determine which option is selected
    /// - Returns: The index of the matched option or 0 if none is available
    @available(*, deprecated, message: "Use getFirstMatchingOption() instead")
    func getMatchingOption(
        formData: T?,
        options: [S],
        discriminatorField: String?
    ) -> Int

    /// Checks to see if the `schema` and `uiSchema` combination represents an array of files
    ///
    /// - Parameters:
    ///   - schema: The schema for which check for array of files flag is desired
    ///   - uiSchema: The UI schema from which to check the widget
    /// - Returns: True if schema/uiSchema contains an array of files, otherwise false
    func isFilesArray(schema: S, uiSchema: UISchema<T, S, F>?) -> Bool

    /// Checks to see if the `schema` combination represents a multi-select
    ///
    /// - Parameter schema: The schema for which check for a multi-select flag is desired
    /// - Returns: True if schema contains a multi-select, otherwise false
    func isMultiSelect(schema: S) -> Bool

    /// Checks to see if the `schema` combination represents a select
    ///
    /// - Parameter schema: The schema for which check for a select flag is desired
    /// - Returns: True if schema contains a select, otherwise false
    func isSelect(schema: S) -> Bool

    /// Merges the errors in `additionalErrorSchema` into the existing `validationData` by combining the hierarchies in
    /// the two `ErrorSchema`s and then appending the error list from the `additionalErrorSchema` obtained by calling
    /// `validator.toErrorList()` onto the `errors` in the `validationData`. If no `additionalErrorSchema` is passed, then
    /// `validationData` is returned.
    ///
    /// - Parameters:
    ///   - validationData: The current `ValidationData` into which to merge the additional errors
    ///   - additionalErrorSchema: The additional set of errors
    /// - Returns: The `validationData` with the additional errors from `additionalErrorSchema` merged into it, if provided
    @available(*, deprecated, message: "Use the validationDataMerge() function instead.")
    func mergeValidationData(
        validationData: ValidationData<T>,
        additionalErrorSchema: ErrorSchema<T>?
    ) -> ValidationData<T>

    /// Retrieves an expanded schema that has had all of its conditions, additional properties, references and
    /// dependencies resolved and merged into the `schema` given a `rawFormData` that is used to do the potentially
    /// recursive resolution.
    ///
    /// - Parameters:
    ///   - schema: The schema for which retrieving a schema is desired
    ///   - formData: The current formData, if any, to assist retrieving a schema
    /// - Returns: The schema having its conditions, additional properties, references and dependencies resolved
    func retrieveSchema(schema: S, formData: T?) -> S

    /// Sanitize the `data` associated with the `oldSchema` so it is considered appropriate for the `newSchema`. If the
    /// new schema does not contain any properties, then `nil` is returned to clear all the form data. Due to the
    /// nature of schemas, this sanitization happens recursively for nested objects of data. Also, any properties in the
    /// old schema that are non-existent in the new schema are set to `nil`.
    ///
    /// - Parameters:
    ///   - newSchema: The new schema for which the data is being sanitized
    ///   - oldSchema: The old schema from which the data originated
    ///   - data: The form data associated with the schema, defaulting to an empty object when nil
    /// - Returns: The new form data, with all of the fields uniquely associated with the old schema set
    ///       to `nil`. Will return `nil` if the new schema is not an object containing properties.
    func sanitizeDataForNewSchema(newSchema: S?, oldSchema: S?, data: Any?) -> T?

    /// Generates an `IdSchema` object for the `schema`, recursively
    ///
    /// - Parameters:
    ///   - schema: The schema for which the display label flag is desired
    ///   - id: The base id for the schema
    ///   - formData: The current formData, if any, onto which to provide any missing defaults
    ///   - idPrefix: The prefix to use for the id, defaults to "root"
    ///   - idSeparator: The separator to use for the path segments in the id, defaults to "_"
    /// - Returns: The `IdSchema` object for the `schema`
    func toIdSchema(
        schema: S,
        id: String?,
        formData: T?,
        idPrefix: String?,
        idSeparator: String?
    ) -> IdSchema<T>

    /// Generates an `PathSchema` object for the `schema`, recursively
    ///
    /// - Parameters:
    ///   - schema: The schema for which the display label flag is desired
    ///   - name: The base name for the schema
    ///   - formData: The current formData, if any, onto which to provide any missing defaults
    /// - Returns: The `PathSchema` object for the `schema`
    func toPathSchema(schema: S, name: String?, formData: T?) -> PathSchema<T>
}

/// Enumeration representing the choices for undefined values inclusion
enum IncludeUndefinedValues {
    case exclude
    case include
    case excludeObjectChildren
}
