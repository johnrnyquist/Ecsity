import Foundation

open class Engine {
    let storage: ArchetypeStorage
    private(set) var systems: [System] = []
    public var numEntities: Int { storage.numEntities }

    public init() {
        storage = ArchetypeStorage()
    }

    public func findAllComponents<T: Component>(ofType componentType: T.Type) -> Set<T> {
        storage.findAllComponents(ofType: componentType)
    }

    public func findEntities(with componentTypes: [Component.Type]) -> Set<Entity> {
        storage.findEntities(with: componentTypes)
    }

    public func find<T: Component>(componentType: T.Type, in entity: Entity) -> T? {
        storage.find(componentType: componentType, in: entity)
    }

    public func add(entity: Entity, withComponents componentTypes: Set<ObjectIdentifier>) -> Archetype {
        storage.add(entity: entity, withComponents: componentTypes)
    }

    public func add<T: Component>(component: T, to entity: Entity) {
        storage.add(component: component, to: entity)
    }

    public func add(system: System) {
        systems.append(system)
    }

    public func update(deltaTime: TimeInterval) {
        for system in systems {
            system.update(time: deltaTime)
        }
    }

    public func remove(entity: Entity) {
        storage.remove(entity: entity)
    }

    public func remove<T: Component>(componentType: T.Type, from entity: Entity) {
        storage.remove(componentType: componentType, from: entity)
    }
}
