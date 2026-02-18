import Foundation

/// Extracts property key ordering from a raw JSON schema string.
///
/// Since `JSONSchema` stores properties as `[String: JSONSchema]` (unordered),
/// this utility parses the raw JSON string directly to preserve the
/// original key ordering defined in the JSON source.
///
/// `JSONSerialization` and `NSDictionary` do NOT preserve key insertion order,
/// so this utility scans the JSON text to extract keys in their original order.
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
        var result: [String: [String]] = [:]
        let chars = Array(jsonString.unicodeScalars)
        extractFromObject(chars: chars, start: 0, path: idPrefix, separator: idSeparator, result: &result)
        return result.isEmpty ? nil : result
    }

    // MARK: - JSON Scanner

    /// Scans for a JSON object starting at `start`, extracts property order,
    /// and recurses into nested objects.
    @discardableResult
    private static func extractFromObject(
        chars: [Unicode.Scalar],
        start: Int,
        path: String,
        separator: String,
        result: inout [String: [String]]
    ) -> Int {
        var i = start

        // Find opening '{'
        i = skipWhitespace(chars: chars, from: i)
        guard i < chars.count, chars[i] == "{" else { return i }
        i += 1

        // Scan key-value pairs at this object level, looking for "properties"
        while i < chars.count {
            i = skipWhitespace(chars: chars, from: i)
            if i >= chars.count { break }

            if chars[i] == "}" {
                return i + 1
            }

            if chars[i] == "," {
                i += 1
                continue
            }

            // Parse key
            guard chars[i] == "\"" else { return i }
            let (key, afterKey) = parseString(chars: chars, from: i)
            i = afterKey

            // Skip ':'
            i = skipWhitespace(chars: chars, from: i)
            guard i < chars.count, chars[i] == ":" else { return i }
            i += 1
            i = skipWhitespace(chars: chars, from: i)

            if key == "properties" {
                // This is the "properties" object - extract its keys in order
                i = extractPropertiesKeys(
                    chars: chars, start: i, path: path, separator: separator, result: &result)
            } else {
                // Skip this value
                i = skipValue(chars: chars, from: i)
            }
        }

        return i
    }

    /// Parses the "properties" object value, extracting keys in order and recursing into children.
    private static func extractPropertiesKeys(
        chars: [Unicode.Scalar],
        start: Int,
        path: String,
        separator: String,
        result: inout [String: [String]]
    ) -> Int {
        var i = start
        i = skipWhitespace(chars: chars, from: i)
        guard i < chars.count, chars[i] == "{" else { return skipValue(chars: chars, from: i) }
        i += 1

        var keys: [String] = []

        while i < chars.count {
            i = skipWhitespace(chars: chars, from: i)
            if i >= chars.count { break }

            if chars[i] == "}" {
                i += 1
                break
            }

            if chars[i] == "," {
                i += 1
                continue
            }

            // Parse property key
            guard chars[i] == "\"" else { break }
            let (propKey, afterKey) = parseString(chars: chars, from: i)
            i = afterKey
            keys.append(propKey)

            // Skip ':'
            i = skipWhitespace(chars: chars, from: i)
            guard i < chars.count, chars[i] == ":" else { break }
            i += 1
            i = skipWhitespace(chars: chars, from: i)

            // The value is a child schema - recurse to find nested "properties"
            let childPath = "\(path)\(separator)\(propKey)"
            if i < chars.count, chars[i] == "{" {
                i = extractFromObject(
                    chars: chars, start: i, path: childPath, separator: separator, result: &result)
            } else {
                i = skipValue(chars: chars, from: i)
            }
        }

        result[path] = keys
        return i
    }

    // MARK: - JSON Primitives

    /// Parses a JSON string starting at the opening quote. Returns (string content, index after closing quote).
    private static func parseString(chars: [Unicode.Scalar], from start: Int) -> (String, Int) {
        var i = start + 1  // skip opening quote
        var result = ""
        while i < chars.count {
            if chars[i] == "\\" {
                i += 2  // skip escape sequence
                continue
            }
            if chars[i] == "\"" {
                return (result, i + 1)
            }
            result.append(Character(chars[i]))
            i += 1
        }
        return (result, i)
    }

    /// Skips a JSON value (string, number, boolean, null, array, or object).
    private static func skipValue(chars: [Unicode.Scalar], from start: Int) -> Int {
        var i = start
        i = skipWhitespace(chars: chars, from: i)
        guard i < chars.count else { return i }

        switch chars[i] {
        case "\"":
            // String
            let (_, end) = parseString(chars: chars, from: i)
            return end
        case "{":
            // Object - skip balanced braces
            return skipBalanced(chars: chars, from: i, open: "{", close: "}")
        case "[":
            // Array - skip balanced brackets
            return skipBalanced(chars: chars, from: i, open: "[", close: "]")
        default:
            // Number, boolean, null - skip to next delimiter
            while i < chars.count {
                let c = chars[i]
                if c == "," || c == "}" || c == "]" || c == " " || c == "\n" || c == "\r"
                    || c == "\t"
                {
                    break
                }
                i += 1
            }
            return i
        }
    }

    /// Skips a balanced pair of delimiters (e.g., `{}` or `[]`), respecting strings.
    private static func skipBalanced(
        chars: [Unicode.Scalar], from start: Int, open: Unicode.Scalar, close: Unicode.Scalar
    ) -> Int {
        var i = start + 1  // skip opening delimiter
        var depth = 1
        while i < chars.count, depth > 0 {
            if chars[i] == "\"" {
                let (_, end) = parseString(chars: chars, from: i)
                i = end
                continue
            }
            if chars[i] == open { depth += 1 }
            if chars[i] == close { depth -= 1 }
            i += 1
        }
        return i
    }

    /// Skips whitespace characters.
    private static func skipWhitespace(chars: [Unicode.Scalar], from start: Int) -> Int {
        var i = start
        while i < chars.count {
            let c = chars[i]
            if c == " " || c == "\n" || c == "\r" || c == "\t" {
                i += 1
            } else {
                break
            }
        }
        return i
    }
}
