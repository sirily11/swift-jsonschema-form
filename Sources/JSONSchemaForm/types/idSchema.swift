/// Type describing an id used for a field in the `IdSchema`
public struct FieldId {
    /// The id for a field
    public var id: String

    public init(id: String) {
        self.id = id
    }
}

/// Type describing a recursive structure of `FieldId`s for an object with a non-empty set of keys
public struct IdSchema<T> {
    /// The id for the field
    public var id: String

    /// The set of ids for fields in the recursive object structure
    public var properties: [String: IdSchema<Any>?]

    public init(id: String, properties: [String: IdSchema<Any>?] = [:]) {
        self.id = id
        self.properties = properties
    }
}
