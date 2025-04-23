import SwiftUI
import JSONSchema


/// Represents a validation error
struct ValidationError: Identifiable {
    var id: String { stack }
    var name: String
    var message: String
    var stack: String
    var property: String?
    var schemaPath: String?
}

/// ErrorListTemplate displays a list of validation errors at the form level
struct ErrorListTemplate: View {
    var errors: [ValidationError]
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