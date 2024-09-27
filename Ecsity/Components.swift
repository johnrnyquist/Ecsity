import Foundation

public class Position: Component, CustomStringConvertible, Equatable {
    public var x: Double
    public var y: Double
    public var point: CGPoint {
        get {
            CGPoint(x: x, y: y)
        }
        set {
            x = Double(newValue.x)
            y = Double(newValue.y)
        }
    }

    public init(point: CGPoint) {
        x = Double(point.x)
        y = Double(point.y)
    }

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public var description: String {
        "Position(x: \(x), y: \(y))"
    }

    public static func ==(lhs: Position, rhs: Position) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
}

public struct Velocity: Component {
    public var dx: Double
    public var dy: Double

    public init(dx: Double, dy: Double) {
        self.dx = dx
        self.dy = dy
    }
}

import SpriteKit

class Display: Component, Hashable, Equatable {
    var node: SKNode

    init(node: SKNode) {
        self.node = node
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    static func ==(lhs: Display, rhs: Display) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
