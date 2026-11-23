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

    /// Registers an entity with the given component types. Registering it again keeps
    /// stored values for types present in both registrations and drops the others.
    /// A type starts matching queries once its value has been added.
    @discardableResult
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
