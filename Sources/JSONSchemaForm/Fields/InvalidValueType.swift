import SwiftUI

struct InvalidValueType<Value: Describable>: View {
    let valueType: Value
    let expectedType: Value

    var body: some View {
        Text(
            "Invalid value type: \(valueType.describe()). Expected type: \(expectedType.describe())"
        )
    }
}
