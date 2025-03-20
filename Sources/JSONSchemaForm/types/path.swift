/// Type describing a name used for a field in the `PathSchema`
struct FieldPath {
    /// The name of a field
    var name: String
}

/// Type describing a recursive structure of `FieldPath`s for an object with a non-empty set of keys
indirect enum PathSchema<T> {
    /// For arrays
    case array(FieldPath, [PathSchema<Any>])

    /// For objects/dictionaries
    case object(FieldPath, [String: PathSchema<Any>?])

    /// For primitive values
    case primitive(FieldPath)
}
