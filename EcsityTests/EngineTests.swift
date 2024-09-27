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
        let movementSystem = MovementSystem(storage: engine.storage)
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
        let movementSystem = MovementSystem(storage: engine.storage)
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
        let movementSystem = MovementSystem(storage: engine.storage)
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
