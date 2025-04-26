import SwiftUI
import JSONSchema

/// A placeholder view for UnsupportedField, corresponding to the `UnsupportedField.tsx` component.
struct UnsupportedField: Field {
    var schema: JSONSchema = .null()
    var reason: String
    var propertyName: String?
    
    init(reason: String) {
        self.reason = reason
    }
    
    var body: some View {
        Text(reason)
            .foregroundColor(.red)
    }
} 
