import JSONSchema
import SwiftUI

public protocol Field: View {
    associatedtype T
    associatedtype S: JSONSchema
    associatedtype F
}
