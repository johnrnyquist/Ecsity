import Foundation

open class Engine {
    let storage: ArchetypeStorage
    private(set) var systems: [System] = []
    var numEntities: Int { storage.numEntities }

    public init() {
        storage = ArchetypeStorage()
    }

    public func add(system: System) {
        systems.append(system)
    }

    public func update(deltaTime: TimeInterval) {
        for system in systems {
            system.update(deltaTime: deltaTime)
        }
    }

    public func remove(entity: Entity) {
        storage.remove(entity: entity)
    }
    
    public func remove(componentType: Component.Type, from entity: Entity) {
        storage.remove(componentType: componentType, from: entity)
    }
}
