import Foundation

public struct EnumValue: Identifiable, Hashable {
    public let value: Any?
    public let displayName: String
    
    public init(value: Any?, displayName: String) {
        self.value = value
        self.displayName = displayName
    }
    
    public static var emptyEnum: EnumValue {
        EnumValue(value: nil, displayName: "")
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(displayName)
    }
    
    public static func == (lhs: EnumValue, rhs: EnumValue) -> Bool {
        return lhs.displayName == rhs.displayName
    }
    
    public var id: String {
        return "\(displayName)"
    }
}
