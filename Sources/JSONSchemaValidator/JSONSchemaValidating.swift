import Foundation
import JSONSchema

/// Protocol defining JSON Schema validation capability.
/// Implementations validate data against JSON Schema dictionaries or JSONSchema objects.
public protocol JSONSchemaValidating: Sendable {
    /// Validate data against a JSON Schema dictionary.
    ///
    /// - Parameters:
    ///   - data: The data to validate (dictionary, array, or primitive value)
    ///   - schema: The JSON Schema as a dictionary
    /// - Throws: Array of `ValidationError` if validation fails
    func validate(_ data: Any?, schema: [String: Any]) throws([ValidationError])

    /// Validate data against a JSONSchema object.
    ///
    /// - Parameters:
    ///   - data: The data to validate (dictionary, array, or primitive value)
    ///   - schema: The JSONSchema object from swift-json-schema
    /// - Throws: Array of `ValidationError` if validation fails
    func validate(_ data: Any?, schema: JSONSchema) throws([ValidationError])
}
