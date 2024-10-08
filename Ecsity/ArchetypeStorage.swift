import Foundation

typealias ComponentTypeSet = Set<ObjectIdentifier>

open class ArchetypeStorage {
    // Properties
    private var archetypes: [Archetype] = []
    private var entityToArchetype: [Entity: Archetype] = [:]
    private var componentTypesToArchetype: [ComponentTypeSet: Archetype] = [:]
    private var memoizedResults: [ComponentTypeSet: Set<Entity>] = [:]
    private(set) var entityToComponents: [Entity: [Component]] = [:]
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
                                       archetype.componentTypes.isSuperset(of: queryTypes)
                                   }
                                   .flatMap { archetype in
                                       archetype.entities
                                   })
        // Memoize the result
        memoizedResults[queryTypes] = result
        return result
    }

    @discardableResult
    public func add(entity: Entity, withComponents componentTypes: Set<ObjectIdentifier>) -> Archetype {
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

    public func remove(entity: Entity) {
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

    public func add<T: Component>(component: T, to entity: Entity) {
        clearCache(for: [ObjectIdentifier(T.self)])
        let objectIdentifier = ObjectIdentifier(T.self)
        guard let archetype = entityToArchetype[entity] else {
            let newArchetype = add(entity: entity, withComponents: [objectIdentifier])
            newArchetype.updateComponent(component, for: entity)
            entityToArchetype[entity] = newArchetype
            entityToComponents[entity, default: []].append(component)
            return
        }
        guard archetype.contains(componentType: objectIdentifier) else {
            guard let updatedArchetype = createNewArchetype(for: entity, addingComponentType: objectIdentifier) else { return }
            updatedArchetype.updateComponent(component, for: entity)
            entityToComponents[entity, default: []].append(component)
            return
        }
        archetype.updateComponent(component, for: entity)
        entityToComponents[entity, default: []].append(component)
    }

    public func remove<T: Component>(componentType: T.Type, from entity: Entity) {
        clearCache(for: [ObjectIdentifier(T.self)])
        guard let archetype = entityToArchetype[entity] else {
            return
        }
        archetype.remove(componentType: componentType, from: entity)
        entityToComponents[entity]?.removeAll { $0 is T }
        if archetype.getAllComponents(for: entity).isEmpty {
            archetype.remove(entity)
            entityToArchetype[entity] = nil
            entityToComponents[entity] = nil
        }
    }

    public func findAllComponents<T: Component>(ofType componentType: T.Type) -> Set<T> {
        let objectIdentifier = ObjectIdentifier(T.self)
        return Set(archetypes.flatMap { archetype in
            archetype.components[objectIdentifier]?.compactMap { $0.value as? T } ?? []
        })
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

// In `ArchetypeStorage.swift`
extension ArchetypeStorage {
    public func getAllComponentsGroupedByEntities() -> [Entity: [Component]] {
        var entityToComponents: [Entity: [Component]] = [:]
        for archetype in archetypes {
            for (_, entityComponents) in archetype.components {
                for (entity, component) in entityComponents {
                    entityToComponents[entity, default: []].append(component)
                }
            }
        }
        return entityToComponents
    }
}
