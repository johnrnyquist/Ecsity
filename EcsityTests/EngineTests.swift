import XCTest
@testable import Ecsity

class EngineTests: XCTestCase {
    var engine: Engine!

    override func setUp() {
        super.setUp()
        engine = Engine()
    }

    func testAddComponentToEntity() {
        let entity = Entity(id: "Entity_1")
        let position = Position(x: 1.0, y: 1.0)
        engine.storage.add(component: position, to: entity)
        let retrievedPosition = engine.storage.find(componentType: Position.self, in: entity)
        XCTAssertEqual(retrievedPosition?.x, 1.0)
        XCTAssertEqual(retrievedPosition?.y, 1.0)
    }

    func testAddSystem() {
        let movementSystem = MovementSystem(engine: engine)
        engine.add(system: movementSystem)
        XCTAssertEqual(engine.systems.count, 1)
        XCTAssertTrue(engine.systems.first is MovementSystem)
    }

    func testUpdateSystems() {
        let entity = Entity(id: "Entity_1")
        let position = Position(x: 0.0, y: 0.0)
        let velocity = Velocity(dx: 1.0, dy: 1.0)
        engine.storage.add(component: position, to: entity)
        engine.storage.add(component: velocity, to: entity)
        let movementSystem = MovementSystem(engine: engine)
        engine.add(system: movementSystem)
        engine.update(deltaTime: 1.0)
        let newPosition = engine.storage.find(componentType: Position.self, in: entity)
        XCTAssertEqual(newPosition?.x, 1.0)
        XCTAssertEqual(newPosition?.y, 1.0)
    }

    func testRemoveEntity() {
        let entity = Entity(id: "Entity_1")
        let position = Position(x: 1.0, y: 1.0)
        engine.storage.add(component: position, to: entity)
        XCTAssertEqual(engine.numEntities, 1)
        engine.storage.remove(entity: entity)
        XCTAssertEqual(engine.numEntities, 0)
        XCTAssertNil(engine.storage.find(componentType: Position.self, in: entity))
    }

    func testUpdateDoesNotAffectEntitiesWithoutVelocity() {
        let entity = Entity(id: "Entity_1")
        let position = Position(x: 0.0, y: 0.0)
        engine.storage.add(component: position, to: entity)
        let movementSystem = MovementSystem(engine: engine)
        engine.add(system: movementSystem)
        engine.update(deltaTime: 1.0)
        let newPosition = engine.storage.find(componentType: Position.self, in: entity)
        XCTAssertEqual(newPosition?.x, 0.0)
        XCTAssertEqual(newPosition?.y, 0.0)
    }

    func testNoUpdateIfNoSystems() {
        let entity = Entity(id: "Entity_1")
        let position = Position(x: 0.0, y: 0.0)
        let velocity = Velocity(dx: 2.0, dy: 2.0)
        engine.storage.add(component: position, to: entity)
        engine.storage.add(component: velocity, to: entity)
        engine.update(deltaTime: 1.0)
        let newPosition = engine.storage.find(componentType: Position.self, in: entity)
        XCTAssertEqual(newPosition?.x, 0.0)
        XCTAssertEqual(newPosition?.y, 0.0)
    }
}

open class MovementSystem: System {
    weak var engine: Engine!

    public init(engine: Engine) {
        self.engine = engine
    }

    public func update(time: TimeInterval) {
        let entities = engine.findEntities(with: [Position.self, Velocity.self])
        for entity in entities {
            guard let position: Position = engine.find(componentType: Position.self, in: entity),
                  let velocity: Velocity = engine.find(componentType: Velocity.self, in: entity) else {
                continue
            }
            // If position were value type, copy it via assignment and change to var
            let newPosition = position
            newPosition.x += velocity.dx * time
            newPosition.y += velocity.dy * time
            // Then update the position in the entity only if it has changed in the storage, not necessary for classes
            if newPosition != position {
                engine.add(component: newPosition, to: entity)
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
