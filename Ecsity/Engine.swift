import Foundation

class Engine {
    let storage: ArchetypeStorage
    private(set) var systems: [System] = []
    var numEntities: Int { storage.numEntities }

    init() {
        storage = ArchetypeStorage()
    }

    func add(system: System) {
        systems.append(system)
    }

    func update(deltaTime: TimeInterval) {
        for system in systems {
            system.update(deltaTime: deltaTime)
        }
    }

    func remove(entity: Entity) {
        storage.remove(entity: entity)
    }
    
    func remove(componentType: Component.Type, from entity: Entity) {
        storage.remove(componentType: componentType, from: entity)
    }
}
