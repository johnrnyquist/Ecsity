import Foundation

open class Engine {
    let storage: ArchetypeStorage
    private(set) var systems: [System] = []
    public var numEntities: Int { storage.numEntities }

    public init() {
        storage = ArchetypeStorage()
    }

    /// Returns all attached values stored under the supplied component type.
    /// Each attachment contributes one result, including equal values on different entities.
    /// The order of results is unspecified.
    public func findAllComponents<T: Component>(ofType componentType: T.Type) -> [T] {
        storage.findAllComponents(ofType: componentType)
    }

    public func findEntities(with componentTypes: [Component.Type]) -> Set<Entity> {
        storage.findEntities(with: componentTypes)
    }

    public func find<T: Component>(componentType: T.Type, in entity: Entity) -> T? {
        storage.find(componentType: componentType, in: entity)
    }

    /// Registers an empty entity. Calling this again preserves its components.
    public func add(entity: Entity) {
        storage.add(entity: entity)
    }

    /// Attaches or replaces a component, registering the entity on its first attachment.
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

    /// Removing an entity's last component also removes the entity from this engine.
    public func remove<T: Component>(componentType: T.Type, from entity: Entity) {
        storage.remove(componentType: componentType, from: entity)
    }
}
