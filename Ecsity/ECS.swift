import Foundation

public protocol Component {}

public protocol System {
    func update(deltaTime: TimeInterval)
}

public struct Entity: Hashable, CustomStringConvertible {
    static public var count = 0
    public let id: String
    public var description: String { id }

    public init(id: String) {
        Entity.count += 1
        self.id = id
    }
}
