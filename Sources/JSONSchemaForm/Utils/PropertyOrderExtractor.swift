import Foundation

/// Extracts property key ordering from a raw JSON schema string.
///
/// Since `JSONSchema` stores properties as `[String: JSONSchema]` (unordered),
/// this utility parses the raw JSON using `JSONSerialization` to preserve the
/// original key ordering defined in the JSON source.
///
/// On Apple platforms, `JSONSerialization` returns `NSDictionary` subclasses
/// that preserve the key insertion order from the JSON source.
enum PropertyOrderExtractor {

    /// Extracts a mapping of field ID paths to ordered property key arrays.
    ///
    /// - Parameters:
    ///   - jsonString: The raw JSON schema string
    ///   - idPrefix: The root field ID prefix (default: "root")
    ///   - idSeparator: The separator used in field IDs (default: "_")
    /// - Returns: A dictionary mapping field ID paths to their ordered property keys,
    ///   or `nil` if the JSON cannot be parsed.
    static func extractPropertyOrder(
        from jsonString: String,
        idPrefix: String = "root",
        idSeparator: String = "_"
    ) -> [String: [String]]? {
        guard let data = jsonString.data(using: .utf8),
            let jsonObj = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        else {
            return nil
        }

        var result: [String: [String]] = [:]
        extractOrderRecursive(
            from: jsonObj, path: idPrefix, separator: idSeparator, result: &result)
        return result.isEmpty ? nil : result
    }

    private static func extractOrderRecursive(
        from jsonObj: Any,
        path: String,
        separator: String,
        result: inout [String: [String]]
    ) {
        // Work with NSDictionary to preserve key ordering from JSONSerialization
        guard let dict = jsonObj as? NSDictionary,
            let properties = dict["properties"] as? NSDictionary
        else {
            return
        }

        // NSDictionary.allKeys preserves insertion order for JSONSerialization results
        // on Apple platforms (macOS/iOS)
        let orderedKeys = properties.allKeys.compactMap { $0 as? String }
        result[path] = orderedKeys

        // Recurse into child object schemas
        for key in orderedKeys {
            if let childSchema = properties[key] {
                let childPath = "\(path)\(separator)\(key)"
                extractOrderRecursive(
                    from: childSchema, path: childPath, separator: separator, result: &result)
            }
        }
    }
}
