import Foundation

typealias ComponentTypeSet = Set<ObjectIdentifier>

open class ArchetypeStorage {
    // Properties
    private var archetypes: [Archetype] = []
    private var entityToArchetype: [Entity: Archetype] = [:]
    private var componentTypesToArchetype: [ComponentTypeSet: Archetype] = [:]
    private var memoizedResults: [ComponentTypeSet: Set<Entity>] = [:]
    // Computed properties
    var allComponentTypesToArchetype: [Set<ObjectIdentifier>: Archetype] {
        componentTypesToArchetype
    }
    var allArchetypes: [Archetype] {
        archetypes
    }
    var numEntities: Int {
        entityToArchetype.count
    }
    // MARK: - Archetype Management
    func archetype(for entity: Entity) -> Archetype? {
        entityToArchetype[entity]
    }

    private func addArchetype(for componentTypes: Set<ObjectIdentifier>) -> Archetype {
        let newArchetype = Archetype(componentTypes: componentTypes)
        archetypes.append(newArchetype)
        componentTypesToArchetype[componentTypes] = newArchetype
        return newArchetype
    }

    private func detach(_ entity: Entity, from archetype: Archetype) {
        archetype.remove(entity)
        if archetype.entities.isEmpty {
            archetypes.removeAll { $0 === archetype }
            componentTypesToArchetype.removeValue(forKey: archetype.componentTypes)
        }
    }

    // MARK: - Entity Management
    public func findEntities(with componentTypes: [Component.Type]) -> Set<Entity> {
        guard !componentTypes.isEmpty else {
            return Set(entityToArchetype.keys)
        }
        let queryTypes = Set(componentTypes.map { componentType in ObjectIdentifier(componentType) })
        // Check if the result is already memoized
        if let cachedResult = memoizedResults[queryTypes] {
            return cachedResult
        }
        var result = Set<Entity>()
        for archetype in archetypes where archetype.componentTypes.isSuperset(of: queryTypes) {
            // A registered type may still have unwritten values.
            if queryTypes.allSatisfy({ archetype.components[$0]?.count == archetype.entities.count }) {
                result.formUnion(archetype.entities)
            } else {
                for entity in archetype.entities where queryTypes.allSatisfy({ archetype.components[$0]?[entity] != nil }) {
                    result.insert(entity)
                }
            }
        }
        // Memoize the result
        memoizedResults[queryTypes] = result
        return result
    }

    @discardableResult
    public func add(entity: Entity, withComponents componentTypes: Set<ObjectIdentifier>) -> Archetype {
        let source = entityToArchetype[entity]
        if let source, source.componentTypes == componentTypes {
            return source
        }
        let destination = componentTypesToArchetype[componentTypes] ?? addArchetype(for: componentTypes)
        if let source {
            for type in source.componentTypes where componentTypes.contains(type) {
                if let component = source.components[type]?[entity] {
                    destination.components[type, default: [:]][entity] = component
                }
            }
            clearCache(for: source.componentTypes.subtracting(componentTypes))
            detach(entity, from: source)
        }
        destination.add(entity)
        entityToArchetype[entity] = destination
        return destination
    }

    public func remove(entity: Entity) {
        guard let archetype = entityToArchetype.removeValue(forKey: entity) else {
            return
        }
        clearCache(for: archetype.componentTypes)
        detach(entity, from: archetype)
    }

    private func clearCache(for componentTypes: Set<ObjectIdentifier>) {
        guard !componentTypes.isEmpty else { return }
        for key in memoizedResults.keys.filter({ !$0.isDisjoint(with: componentTypes) }) {
            memoizedResults.removeValue(forKey: key)
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
        let type = ObjectIdentifier(T.self)
        let current = entityToArchetype[entity]
        let destination: Archetype
        if let current, current.contains(componentType: type) {
            destination = current
        } else {
            let signature = (current?.componentTypes ?? []).union([type])
            destination = add(entity: entity, withComponents: signature)
        }
        if destination.components[type]?[entity] == nil {
            clearCache(for: [type])
        }
        destination.add(component: component, to: entity)
    }

    public func remove<T: Component>(componentType: T.Type, from entity: Entity) {
        let type = ObjectIdentifier(componentType)
        guard let archetype = entityToArchetype[entity], archetype.components[type]?[entity] != nil else {
            return
        }
        let remaining = archetype.componentTypes.subtracting([type])
        if remaining.contains(where: { archetype.components[$0]?[entity] != nil }) {
            add(entity: entity, withComponents: remaining)
        } else {
            remove(entity: entity)
        }
    }

    public func findAllComponents<T: Component>(ofType componentType: T.Type) -> [T] {
        let componentTypeID = ObjectIdentifier(componentType)
        return archetypes.flatMap { archetype in
            archetype.components[componentTypeID]?.values.compactMap { $0 as? T } ?? []
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
