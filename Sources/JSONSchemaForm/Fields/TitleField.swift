import SwiftUI
import JSONSchema

/// TitleField renders a field title with appropriate styling
struct TitleField: View {
    var id: String
    var title: String
    var required: Bool
    
    var body: some View {
        if !title.isEmpty {
            HStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                
                if required {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.headline)
                }
            }
            .id(id)
            .padding(.bottom, 4)
        }
    }
} 