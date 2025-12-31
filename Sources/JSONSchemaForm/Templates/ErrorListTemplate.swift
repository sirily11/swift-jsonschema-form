import JSONSchema
import JSONSchemaValidator
import SwiftUI

/// Represents a form-level validation error for display purposes.
///
/// This struct is used internally for legacy compatibility and error display.
/// For programmatic access to validation errors, use `JSONSchemaValidator.ValidationError`.
public struct FormValidationError: Identifiable {
    public var id: String { stack }
    public var name: String
    public var message: String
    public var stack: String
    public var property: String?
    public var schemaPath: String?

    public init(
        name: String,
        message: String,
        stack: String,
        property: String? = nil,
        schemaPath: String? = nil
    ) {
        self.name = name
        self.message = message
        self.stack = stack
        self.property = property
        self.schemaPath = schemaPath
    }
}


/// ErrorListTemplate displays a list of validation errors at the form level
struct ErrorListTemplate: View {
    var errors: [FormValidationError]
    var errorSchema: [String: Any]?

    init(props: ErrorListTemplateProps) {
        self.errors = props.errors
        self.errorSchema = props.errorSchema
    }

    var body: some View {
        if !errors.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Errors")
                    .font(.headline)
                    .foregroundColor(.red)

                ForEach(errors) { error in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)

                        VStack(alignment: .leading, spacing: 2) {
                            if !error.property.isNilOrEmpty {
                                Text("Property: \(error.property!)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(error.message)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.red.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
            .padding(.bottom, 16)
        }
    }
}

// Helper extension to check if optional string is nil or empty
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self == nil || self!.isEmpty
    }
}
