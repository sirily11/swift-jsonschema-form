import SwiftUI

struct InvalidValueType: View {
    let valueType: String
    let expectedType: String

    var body: some View {
        Text("Invalid value type: \(valueType). Expected type: \(expectedType)")
    }
}
