/// The set of UiSchema options that can be set globally and used as fallbacks at an individual template, field or
/// widget level when no field-level value of the option is provided.
public struct GlobalUISchemaOptions {
    /// Flag, if set to `false`, new items cannot be added to array fields, unless overridden (defaults to true)
    public var addable: Bool?

    /// Flag, if set to `true`, array items can be copied (defaults to false)
    public var copyable: Bool?

    /// Flag, if set to `false`, array items cannot be ordered (defaults to true)
    public var orderable: Bool?

    /// Flag, if set to `false`, array items will not be removable (defaults to true)
    public var removable: Bool?

    /// Field labels are rendered by default. Labels may be omitted by setting the `label` option to `false`
    public var label: Bool?

    /// When using `additionalProperties`, key collision is prevented by appending a unique integer to the duplicate key.
    /// This option allows you to change the separator between the original key name and the integer. Default is "-"
    public var duplicateKeySuffixSeparator: String?

    public init(
        addable: Bool? = nil,
        copyable: Bool? = nil,
        orderable: Bool? = nil,
        removable: Bool? = nil,
        label: Bool? = nil,
        duplicateKeySuffixSeparator: String? = nil
    ) {
        self.addable = addable
        self.copyable = copyable
        self.orderable = orderable
        self.removable = removable
        self.label = label
        self.duplicateKeySuffixSeparator = duplicateKeySuffixSeparator
    }
}
