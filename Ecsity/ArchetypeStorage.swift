import Foundation

open class ArchetypeStorage {
    // Properties
    private var archetypes: [Archetype] = []
    private var entityToArchetype: [Entity: Archetype] = [:]
    private var componentTypesToArchetype: [Set<ObjectIdentifier>: Archetype] = [:]
    private var memoizedResults: [Set<ObjectIdentifier>: Set<Entity>] = [:]

    // Initializer
    public init() {
    }

    // Computed properties
    var allComponentTypesToArchetype: [Set<ObjectIdentifier>: Archetype] {
        componentTypesToArchetype
    }
    var allArchetypes: [Archetype] {
        archetypes
    }
    var numEntities: Int {
        entities.count
    }
    private var entities: Set<Entity> {
        Set(entityToArchetype.keys)
    }

    // MARK: - Archetype Management
    func createNewArchetype(for entity: Entity, addingComponentType objectIdentifier: ObjectIdentifier) -> Archetype? {
        clearCache(for: [objectIdentifier])
        guard let oldArchetype = entityToArchetype[entity] 
        else {
            return nil
        }
        let newComponentTypes = oldArchetype.componentTypes.union([objectIdentifier])
        if newComponentTypes == oldArchetype.componentTypes {
            return oldArchetype
        }
        if let existingArchetype = componentTypesToArchetype[newComponentTypes] {
            migrateEntity(entity, from: oldArchetype, to: existingArchetype)
            return existingArchetype
        } else {
            let newArchetype = addArchetype(for: newComponentTypes)
            migrateEntity(entity, from: oldArchetype, to: newArchetype)
            return newArchetype
        }
    }

    func archetype(for entity: Entity) -> Archetype? {
        entityToArchetype[entity]
    }

    @discardableResult
    func addArchetype(for componentTypes: Set<ObjectIdentifier>) -> Archetype {
        let newArchetype = Archetype(componentTypes: componentTypes)
        archetypes.append(newArchetype)
        componentTypesToArchetype[componentTypes] = newArchetype
        return newArchetype
    }

    func updateArchetypeWithComponent<T: Component>(_ archetype: Archetype, _ component: T, _ entity: Entity) {
        clearCache(for: [ObjectIdentifier(T.self)])
        archetype.add(component: component, to: entity)
    }

    func removeEmptyArchetypes() {
        // Identify and remove archetypes without entities
        for archetype in archetypes {
            if archetype.entities.isEmpty {
                archetypes.removeAll { $0 === archetype }
                componentTypesToArchetype.removeValue(forKey: archetype.componentTypes)
            }
        }
    }

    // MARK: - Entity Management
    public func findEntities(with componentTypes: [Component.Type]) -> Set<Entity> {
        // Early exit if no component types are provided
        guard !componentTypes.isEmpty 
        else {
            return entities
        }
        let queryTypes = Set(componentTypes.map { componentType in ObjectIdentifier(componentType) })
        // Check if the result is already memoized
        if let cachedResult = memoizedResults[queryTypes] {
            return cachedResult
        }
        // Compute the result if not memoized
        let result = Set(archetypes.lazy
                                   .filter { archetype in 
                                       archetype.componentTypes.isSuperset(of: queryTypes) }
                                   .flatMap { archetype in 
                                       archetype.entities })
        // Memoize the result
        memoizedResults[queryTypes] = result
        return result
    }

    @discardableResult
    func add(entity: Entity, withComponents componentTypes: Set<ObjectIdentifier>) -> Archetype {
        clearCache(for: componentTypes)
        if let archetype = componentTypesToArchetype[componentTypes] {
            archetype.add(entity)
            entityToArchetype[entity] = archetype
            return archetype
        } else {
            let newArchetype = addArchetype(for: componentTypes)
            newArchetype.add(entity)
            entityToArchetype[entity] = newArchetype
            return newArchetype
        }
    }

    func migrateEntity(_ entity: Entity, from oldArchetype: Archetype, to newArchetype: Archetype) {
        clearCache(for: oldArchetype.componentTypes.union(newArchetype.componentTypes))
        newArchetype.add(entity)
        entityToArchetype[entity] = newArchetype
        // Copy existing components to the new archetype
        for componentType in oldArchetype.componentTypes {
            if let component = oldArchetype.components[componentType]?[entity] {
                newArchetype.components[componentType, default: [:]][entity] = component
            }
        }
        // Remove entity from old archetype
        oldArchetype.remove(entity)
        if oldArchetype.entities.isEmpty {
            archetypes.removeAll { $0 === oldArchetype }
            componentTypesToArchetype.removeValue(forKey: oldArchetype.componentTypes)
        }
    }

    func remove(entity: Entity) {
        guard let archetype = entityToArchetype[entity] 
        else {
            return
        }
        clearCache(for: archetype.componentTypes)
        // Remove entity from archetype and disassociate components
        archetype.remove(entity)
        entityToArchetype[entity] = nil
        for objectIdentifier in archetype.componentTypes {
            if var componentGroup = archetype.components[objectIdentifier] {
                componentGroup[entity] = nil
                // Remove the component type itself if empty
                if componentGroup.isEmpty {
                    archetype.components.removeValue(forKey: objectIdentifier)
                }
            }
        }
        // Remove empty archetype
        removeEmptyArchetypes()
    }

    func clearCache(for componentTypes: Set<ObjectIdentifier>) {
        for key in memoizedResults.keys {
            if !key.isDisjoint(with: componentTypes) {
                memoizedResults.removeValue(forKey: key)
            }
        }
    }

    // MARK: - Component Management
    public func find<T: Component>(componentType: T.Type, in entity: Entity) -> T? {
        guard let archetype = entityToArchetype[entity]
        else {
            return nil
        }
        return archetype.find(componentType: componentType, in: entity)
    }

    func add<T: Component>(component: T, to entity: Entity) {
        clearCache(for: [ObjectIdentifier(T.self)])
        let objectIdentifier = ObjectIdentifier(T.self)
        // Check if the entity already has an associated archetype
        guard let archetype = entityToArchetype[entity] else {
            // Create a new archetype for the entity with the given component
            let newArchetype = add(entity: entity, withComponents: [objectIdentifier])
            newArchetype.updateComponent(component, for: entity)
            entityToArchetype[entity] = newArchetype
            return
        }
        // Check if the archetype already contains the component type
        guard archetype.contains(componentType: objectIdentifier) else {
            // Create a new archetype to include the new component type
            guard let updatedArchetype = createNewArchetype(for: entity, addingComponentType: objectIdentifier) else { return }
            updatedArchetype.updateComponent(component, for: entity)
            return
        }
        // Update the component in the existing archetype
        archetype.updateComponent(component, for: entity)
    }

    func remove<T: Component>(componentType: T.Type, from entity: Entity) {
        clearCache(for: [ObjectIdentifier(T.self)])
        guard let archetype = entityToArchetype[entity] 
        else {
            return
        }
        archetype.remove(componentType: componentType, from: entity)
        // If the entity has no more components, remove it from the archetype
        if archetype.getAllComponents(for: entity).isEmpty {
            archetype.remove(entity)
            entityToArchetype[entity] = nil
        }
    }
}

extension ArchetypeStorage {
    func printArchetypes() {
        archetypes.forEach { archetype in
            print(archetype)
        }
    }

    var numArchetypes: Int {
        archetypes.count
    }
}
