import JSONSchema
import SwiftUI

public protocol Widget: View {
    associatedtype T
    associatedtype S: JSONSchema
    associatedtype F

    var id: String { get }
    var name: String { get }
    var schema: S { get }
}
