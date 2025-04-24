import Foundation

public struct EnumValue: Identifiable, Hashable {
    public let id = UUID()
    public let value: Any
    public let displayName: String

    public init(value: Any, displayName: String) {
        self.value = value
        self.displayName = displayName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(displayName)
        // Note: we can't hash 'value' directly as it's Any
    }

    public static func == (lhs: EnumValue, rhs: EnumValue) -> Bool {
        return lhs.id == rhs.id
    }
}
