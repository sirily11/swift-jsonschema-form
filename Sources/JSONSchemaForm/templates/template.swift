import JSONSchema
import SwiftUI

public protocol Template: View {
    var schemaType: JSONSchema { get }
}
