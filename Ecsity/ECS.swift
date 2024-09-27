import Foundation

protocol Component {}

protocol System {
    func update(deltaTime: TimeInterval)
}

struct Entity: Hashable, CustomStringConvertible {
    static var count = 0
    let id: String
    var description: String { id }

    init(id: String) {
        Entity.count += 1
        self.id = id
    }
}
