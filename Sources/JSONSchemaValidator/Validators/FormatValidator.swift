import Foundation

/// Validates format constraints for JSON Schema.
enum FormatValidator {
    /// Validate a string against a format constraint.
    /// Returns true if valid, false if invalid.
    static func validate(_ value: String, format: String) -> Bool {
        switch format {
        // Date and Time formats
        case "date":
            return isValidDate(value)
        case "time":
            return isValidTime(value)
        case "date-time":
            return isValidDateTime(value)
        case "duration":
            return isValidDuration(value)

        // Email and hostname
        case "email":
            return isValidEmail(value)
        case "idn-email":
            return isValidEmail(value) // Simplified: same as email
        case "hostname":
            return isValidHostname(value)
        case "idn-hostname":
            return isValidHostname(value) // Simplified: same as hostname

        // IP addresses
        case "ipv4":
            return isValidIPv4(value)
        case "ipv6":
            return isValidIPv6(value)

        // URIs
        case "uri":
            return isValidURI(value)
        case "uri-reference":
            return isValidURIReference(value)
        case "uri-template":
            return isValidURITemplate(value)
        case "iri":
            return isValidURI(value) // Simplified: same as URI
        case "iri-reference":
            return isValidURIReference(value) // Simplified

        // UUID
        case "uuid":
            return isValidUUID(value)

        // JSON Pointer
        case "json-pointer":
            return isValidJSONPointer(value)
        case "relative-json-pointer":
            return isValidRelativeJSONPointer(value)

        // Regex
        case "regex":
            return isValidRegex(value)

        default:
            // Unknown formats are considered valid (as per JSON Schema spec)
            return true
        }
    }

    // MARK: - Date/Time Validation

    private static func isValidDate(_ value: String) -> Bool {
        // Format: YYYY-MM-DD
        let pattern = #"^\d{4}-\d{2}-\d{2}$"#
        guard matchesPattern(value, pattern: pattern) else { return false }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: value) != nil
    }

    private static func isValidTime(_ value: String) -> Bool {
        // Format: HH:MM:SS or HH:MM:SS.sss with optional timezone
        let pattern = #"^(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|[+-]\d{2}:\d{2})?$"#
        guard matchesPattern(value, pattern: pattern) else { return false }

        // Extract and validate hour, minute, second values
        let components = value.prefix(8).split(separator: ":")
        guard components.count >= 3,
              let hour = Int(components[0]), hour >= 0 && hour <= 23,
              let minute = Int(components[1]), minute >= 0 && minute <= 59,
              let second = Int(components[2].prefix(2)), second >= 0 && second <= 59 else {
            return false
        }
        return true
    }

    private static func isValidDateTime(_ value: String) -> Bool {
        // ISO 8601 date-time
        let pattern = #"^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?$"#
        guard matchesPattern(value, pattern: pattern) else { return false }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if formatter.date(from: value) != nil { return true }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value) != nil
    }

    private static func isValidDuration(_ value: String) -> Bool {
        // ISO 8601 duration: P[n]Y[n]M[n]DT[n]H[n]M[n]S
        let pattern = #"^P(\d+Y)?(\d+M)?(\d+W)?(\d+D)?(T(\d+H)?(\d+M)?(\d+(\.\d+)?S)?)?$"#
        return matchesPattern(value, pattern: pattern) && value != "P" && value != "PT"
    }

    // MARK: - Email Validation

    private static func isValidEmail(_ value: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return matchesPattern(value, pattern: pattern)
    }

    // MARK: - Hostname Validation

    private static func isValidHostname(_ value: String) -> Bool {
        // RFC 1123 hostname
        guard value.count <= 253 else { return false }

        let labels = value.split(separator: ".")
        for label in labels {
            guard label.count >= 1 && label.count <= 63 else { return false }
            let pattern = #"^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$"#
            guard matchesPattern(String(label), pattern: pattern) else { return false }
        }
        return true
    }

    // MARK: - IP Address Validation

    private static func isValidIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".")
        guard parts.count == 4 else { return false }

        for part in parts {
            guard let num = Int(part), num >= 0 && num <= 255 else { return false }
            // Check for leading zeros (e.g., "01" is invalid)
            if part.count > 1 && part.hasPrefix("0") { return false }
        }
        return true
    }

    private static func isValidIPv6(_ value: String) -> Bool {
        // Basic IPv6 validation
        let pattern = #"^([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}$|^([0-9A-Fa-f]{1,4}:){1,7}:$|^([0-9A-Fa-f]{1,4}:){1,6}:[0-9A-Fa-f]{1,4}$|^([0-9A-Fa-f]{1,4}:){1,5}(:[0-9A-Fa-f]{1,4}){1,2}$|^([0-9A-Fa-f]{1,4}:){1,4}(:[0-9A-Fa-f]{1,4}){1,3}$|^([0-9A-Fa-f]{1,4}:){1,3}(:[0-9A-Fa-f]{1,4}){1,4}$|^([0-9A-Fa-f]{1,4}:){1,2}(:[0-9A-Fa-f]{1,4}){1,5}$|^[0-9A-Fa-f]{1,4}:(:[0-9A-Fa-f]{1,4}){1,6}$|^:(:[0-9A-Fa-f]{1,4}){1,7}$|^::$"#
        return matchesPattern(value, pattern: pattern)
    }

    // MARK: - URI Validation

    private static func isValidURI(_ value: String) -> Bool {
        guard let url = URL(string: value) else { return false }
        return url.scheme != nil
    }

    private static func isValidURIReference(_ value: String) -> Bool {
        // URI-reference can be a URI or a relative reference
        if value.isEmpty { return true }
        return URL(string: value) != nil
    }

    private static func isValidURITemplate(_ value: String) -> Bool {
        // Basic URI template validation (RFC 6570)
        // Check for balanced braces
        var depth = 0
        for char in value {
            if char == "{" { depth += 1 }
            if char == "}" { depth -= 1 }
            if depth < 0 { return false }
        }
        return depth == 0
    }

    // MARK: - UUID Validation

    private static func isValidUUID(_ value: String) -> Bool {
        let pattern = #"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"#
        return matchesPattern(value, pattern: pattern)
    }

    // MARK: - JSON Pointer Validation

    private static func isValidJSONPointer(_ value: String) -> Bool {
        // JSON Pointer must be empty or start with /
        if value.isEmpty { return true }
        return value.hasPrefix("/")
    }

    private static func isValidRelativeJSONPointer(_ value: String) -> Bool {
        // Relative JSON Pointer starts with non-negative integer
        let pattern = #"^(0|[1-9][0-9]*)(#|(/[^/]*)*)?$"#
        return matchesPattern(value, pattern: pattern)
    }

    // MARK: - Regex Validation

    private static func isValidRegex(_ value: String) -> Bool {
        do {
            _ = try NSRegularExpression(pattern: value, options: [])
            return true
        } catch {
            return false
        }
    }

    // MARK: - Helper

    private static func matchesPattern(_ value: String, pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: value.utf16.count)
            return regex.firstMatch(in: value, options: [], range: range) != nil
        } catch {
            return false
        }
    }
}
