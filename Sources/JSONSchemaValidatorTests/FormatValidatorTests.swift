import Testing
@testable import JSONSchemaValidator

@Suite("Format Validator Tests")
struct FormatValidatorTests {
    // MARK: - Email Format Tests

    @Test("Valid email format")
    func validEmailFormat() throws {
        let validEmails = [
            "user@example.com",
            "test.user@example.org",
            "user+tag@example.co.uk"
        ]
        for email in validEmails {
            try JSONSchemaValidator.validate(email, schema: [
                "type": "string",
                "format": "email"
            ])
        }
    }

    @Test("Invalid email format")
    func invalidEmailFormat() throws {
        let invalidEmails = [
            "not-an-email",
            "@example.com",
            "user@",
            "user@.com"
        ]
        for email in invalidEmails {
            #expect(throws: [ValidationError].self) {
                try JSONSchemaValidator.validate(email, schema: [
                    "type": "string",
                    "format": "email"
                ])
            }
        }
    }

    // MARK: - URI Format Tests

    @Test("Valid URI format")
    func validURIFormat() throws {
        let validURIs = [
            "https://example.com",
            "http://example.com/path",
            "ftp://files.example.com/file.txt"
        ]
        for uri in validURIs {
            try JSONSchemaValidator.validate(uri, schema: [
                "type": "string",
                "format": "uri"
            ])
        }
    }

    @Test("Invalid URI format")
    func invalidURIFormat() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("not a uri", schema: [
                "type": "string",
                "format": "uri"
            ])
        }
    }

    // MARK: - Date Format Tests

    @Test("Valid date format")
    func validDateFormat() throws {
        let validDates = [
            "2024-01-15",
            "2024-12-31",
            "2000-01-01"
        ]
        for date in validDates {
            try JSONSchemaValidator.validate(date, schema: [
                "type": "string",
                "format": "date"
            ])
        }
    }

    @Test("Invalid date format")
    func invalidDateFormat() throws {
        let invalidDates = [
            "01-15-2024",
            "2024/01/15",
            "not-a-date"
        ]
        for date in invalidDates {
            #expect(throws: [ValidationError].self) {
                try JSONSchemaValidator.validate(date, schema: [
                    "type": "string",
                    "format": "date"
                ])
            }
        }
    }

    // MARK: - Date-Time Format Tests

    @Test("Valid date-time format")
    func validDateTimeFormat() throws {
        let validDateTimes = [
            "2024-01-15T10:30:00Z",
            "2024-01-15T10:30:00+05:00"
        ]
        for dateTime in validDateTimes {
            try JSONSchemaValidator.validate(dateTime, schema: [
                "type": "string",
                "format": "date-time"
            ])
        }
    }

    @Test("Invalid date-time format")
    func invalidDateTimeFormat() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("2024-01-15 10:30:00", schema: [
                "type": "string",
                "format": "date-time"
            ])
        }
    }

    // MARK: - Time Format Tests

    @Test("Valid time format")
    func validTimeFormat() throws {
        let validTimes = [
            "10:30:00",
            "23:59:59Z",
            "10:30:00.123"
        ]
        for time in validTimes {
            try JSONSchemaValidator.validate(time, schema: [
                "type": "string",
                "format": "time"
            ])
        }
    }

    @Test("Invalid time format")
    func invalidTimeFormat() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("25:00:00", schema: [
                "type": "string",
                "format": "time"
            ])
        }
    }

    // MARK: - UUID Format Tests

    @Test("Valid UUID format")
    func validUUIDFormat() throws {
        let validUUIDs = [
            "550e8400-e29b-41d4-a716-446655440000",
            "F47AC10B-58CC-4372-A567-0E02B2C3D479"
        ]
        for uuid in validUUIDs {
            try JSONSchemaValidator.validate(uuid, schema: [
                "type": "string",
                "format": "uuid"
            ])
        }
    }

    @Test("Invalid UUID format")
    func invalidUUIDFormat() throws {
        let invalidUUIDs = [
            "not-a-uuid",
            "550e8400-e29b-41d4-a716",
            "550e8400e29b41d4a716446655440000"
        ]
        for uuid in invalidUUIDs {
            #expect(throws: [ValidationError].self) {
                try JSONSchemaValidator.validate(uuid, schema: [
                    "type": "string",
                    "format": "uuid"
                ])
            }
        }
    }

    // MARK: - IPv4 Format Tests

    @Test("Valid IPv4 format")
    func validIPv4Format() throws {
        let validIPs = [
            "192.168.1.1",
            "10.0.0.0",
            "255.255.255.255"
        ]
        for ip in validIPs {
            try JSONSchemaValidator.validate(ip, schema: [
                "type": "string",
                "format": "ipv4"
            ])
        }
    }

    @Test("Invalid IPv4 format")
    func invalidIPv4Format() throws {
        let invalidIPs = [
            "256.1.1.1",
            "192.168.1",
            "192.168.1.1.1"
        ]
        for ip in invalidIPs {
            #expect(throws: [ValidationError].self) {
                try JSONSchemaValidator.validate(ip, schema: [
                    "type": "string",
                    "format": "ipv4"
                ])
            }
        }
    }

    // MARK: - IPv6 Format Tests

    @Test("Valid IPv6 format")
    func validIPv6Format() throws {
        let validIPs = [
            "2001:0db8:85a3:0000:0000:8a2e:0370:7334",
            "::1"
        ]
        for ip in validIPs {
            try JSONSchemaValidator.validate(ip, schema: [
                "type": "string",
                "format": "ipv6"
            ])
        }
    }

    // MARK: - Hostname Format Tests

    @Test("Valid hostname format")
    func validHostnameFormat() throws {
        let validHostnames = [
            "example.com",
            "sub.example.com",
            "my-host"
        ]
        for hostname in validHostnames {
            try JSONSchemaValidator.validate(hostname, schema: [
                "type": "string",
                "format": "hostname"
            ])
        }
    }

    @Test("Invalid hostname format")
    func invalidHostnameFormat() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("-invalid.com", schema: [
                "type": "string",
                "format": "hostname"
            ])
        }
    }

    // MARK: - Regex Format Tests

    @Test("Valid regex format")
    func validRegexFormat() throws {
        let validPatterns = [
            "^[a-z]+$",
            "\\d{3}-\\d{4}",
            ".*"
        ]
        for pattern in validPatterns {
            try JSONSchemaValidator.validate(pattern, schema: [
                "type": "string",
                "format": "regex"
            ])
        }
    }

    @Test("Invalid regex format")
    func invalidRegexFormat() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("[invalid", schema: [
                "type": "string",
                "format": "regex"
            ])
        }
    }

    // MARK: - JSON Pointer Format Tests

    @Test("Valid JSON pointer format")
    func validJSONPointerFormat() throws {
        let validPointers = [
            "",
            "/foo",
            "/foo/bar/0"
        ]
        for pointer in validPointers {
            try JSONSchemaValidator.validate(pointer, schema: [
                "type": "string",
                "format": "json-pointer"
            ])
        }
    }

    @Test("Invalid JSON pointer format")
    func invalidJSONPointerFormat() throws {
        #expect(throws: [ValidationError].self) {
            try JSONSchemaValidator.validate("foo/bar", schema: [
                "type": "string",
                "format": "json-pointer"
            ])
        }
    }

    // MARK: - Duration Format Tests

    @Test("Valid duration format")
    func validDurationFormat() throws {
        let validDurations = [
            "P1Y",
            "P1M",
            "P1D",
            "PT1H",
            "PT1M",
            "PT1S",
            "P1Y2M3DT4H5M6S"
        ]
        for duration in validDurations {
            try JSONSchemaValidator.validate(duration, schema: [
                "type": "string",
                "format": "duration"
            ])
        }
    }

    @Test("Invalid duration format")
    func invalidDurationFormat() throws {
        let invalidDurations = [
            "P",
            "PT",
            "1Y"
        ]
        for duration in invalidDurations {
            #expect(throws: [ValidationError].self) {
                try JSONSchemaValidator.validate(duration, schema: [
                    "type": "string",
                    "format": "duration"
                ])
            }
        }
    }
}
