import Foundation

struct Display: Component, CustomStringConvertible {
    var sprite: String

    init(sprite: String) {
        self.sprite = sprite
    }

    var description: String {
        return "Display \(sprite)"
    }
}

class Position: Component, CustomStringConvertible, Equatable {
    var x: Double
    var y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    var description: String {
        "Position(x: \(x), y: \(y))"
    }

    static func ==(lhs: Position, rhs: Position) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

struct Velocity: Component {
    var dx: Double
    var dy: Double

    init(dx: Double, dy: Double) {
        self.dx = dx
        self.dy = dy
    }
}