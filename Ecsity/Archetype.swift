import Foundation

/*
Archtypes--------------------
Archetype_1
    Velocity

Archetype_3
    Velocity
    Position

Archetype_5
    Position
    Velocity
    Display

Archtypes and Components--------------------
Archetype_1
    Velocity:
        Entity_1: Velocity(dx: 3.0, dy: 4.0)

Archetype_3
    Velocity:
        Entity_2: Velocity(dx: 3.0, dy: 4.0)
        Entity_4: Velocity(dx: 3.0, dy: 4.0)
    Position:
        Entity_4: Position(x: 10.0, y: 10.0)
        Entity_2: Position(x: 10.0, y: 10.0)

Archetype_5
    Position:
        Entity_3: Position(x: 20.0, y: 20.0)
    Velocity:
        Entity_3: Velocity(dx: 2.0, dy: 1.0)
    Display:
        Entity_3: Display Sprite_1

Entities--------------------
Entity: Entity_4
Entity: Entity_2
Entity: Entity_3
 */

open class Archetype {
    static private(set) var count = 0
    let name: String
    /// The set of component types that this archetype contains ie [Position, Velocity]
    /// would be a set of ObjectIdentifiers for those Components
    let componentTypes: Set<ObjectIdentifier>
    /// The set of entities that this archetype contains
    private(set) var entities: Set<Entity>
    /// A dictionary of component types to a dictionary of entity to component
    /// ie [Position: [Entity_1: Position(x: 1.0, y: 1.0)]]
    /// where Position is an ObjectIdentifier of the Position component
    var components: [ObjectIdentifier: [Entity: Component]]

    public init(componentTypes: Set<ObjectIdentifier>, name: String? = nil) {
        self.componentTypes = componentTypes
        entities = []
        components = [:]
        Self.count += 1
        self.name = name ?? "\(Self.self)_\(Self.count)"
    }

    func add<T: Component>(component: T, to entity: Entity) {
        let componentType = ObjectIdentifier(T.self)
        /// ie [Position: [Entity_1: Position(x: 1.0, y: 1.0)]]
        /// where Position is an ObjectIdentifier of the Position component
        components[componentType, default: [:]][entity] = component // overwrites existing component
        entities.insert(entity)
    }

    func add(_ entity: Entity) {
        guard !entities.contains(entity) else { return }
        entities.insert(entity)
        for componentType in componentTypes {
            components[componentType, default: [:]][entity] = nil
        }
    }

    func contains(componentType: ObjectIdentifier) -> Bool {
        componentTypes.contains(componentType)
    }

    func remove(_ entity: Entity) {
        entities.remove(entity)
        components.forEach { componentType, _ in
            components[componentType]?[entity] = nil
        }
    }

    func remove<T: Component>(componentType: T.Type, from entity: Entity) {
        let componentTypeID = ObjectIdentifier(componentType)
        components[componentTypeID]?[entity] = nil
        if components[componentTypeID]?.isEmpty ?? true {
            components[componentTypeID] = nil
        }
        if !components.values.contains(where: { $0.keys.contains(entity) }) {
            entities.remove(entity)
        }
    }

    func find<T: Component>(componentType: T.Type, in entity: Entity) -> T? {
        let componentTypeID = ObjectIdentifier(componentType)
        return components[componentTypeID]?[entity] as? T
    }

    func updateComponent<T: Component>(_ component: T, for entity: Entity) {
        let componentType = ObjectIdentifier(T.self)
        if components[componentType] == nil {
            components[componentType] = [:]
        }
        components[componentType]?[entity] = component
    }

    func getAllComponents(for entity: Entity) -> [Component] {
        var componentsList: [Component] = []
        for componentType in componentTypes {
            if let component = components[componentType]?[entity] {
                componentsList.append(component)
            }
        }
        return componentsList
    }
}

// MARK: - Equatable
extension Archetype: Equatable {
    static public func == (lhs: Archetype, rhs: Archetype) -> Bool {
        lhs.name == rhs.name
    }
}

// MARK: - CustomStringConvertible
extension Archetype: CustomStringConvertible {
    public var description: String {
        var description = "\(name)\n"
        for (componentType, components) in components {
            description += "    \(componentType)\n"
            for (entity, component) in components {
                description += "        \(entity): \(component)\n"
            }
        }
        return description
    }
}
