import Foundation

open class MovementSystem: System {
    let storage: ArchetypeStorage

    public init(storage: ArchetypeStorage) {
        self.storage = storage
    }

    public func update(deltaTime: TimeInterval) {
        let entities = storage.findEntities(with: [Position.self, Velocity.self])
        for entity in entities {
            guard let position: Position = storage.find(componentType: Position.self, in: entity),
                  let velocity: Velocity = storage.find(componentType: Velocity.self, in: entity) else {
                continue
            }
            // If position were value type, copy it via assignment and change to var
            let newPosition = position
            newPosition.x += velocity.dx * deltaTime
            newPosition.y += velocity.dy * deltaTime
            // Then update the position in the entity only if it has changed in the storage, not necessary for classes
            if newPosition != position {
                storage.add(component: newPosition, to: entity)
            }
        }
    }
}
// If we were only dealing with classes, the below would work. 
// However, we are dealing with structs, so we need to update the component in the archetypeStorage.
//        for entity in archetype.entities {
//            if let velocity = archetype.find(componentType: Velocity.self, in: entity),
//               let position = archetype.find(componentType: Position.self, in: entity) {
//                position.x += velocity.dx
//                position.y += velocity.dy
//                // Mutating `position` directly within the archetype
//            }
//        }
