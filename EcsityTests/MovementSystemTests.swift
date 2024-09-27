import XCTest
@testable import Ecsity

class MovementSystemTests: XCTestCase {
    var storage: ArchetypeStorage!
    var movementSystem: MovementSystem!
    var entity1, entity2: Entity!

    override func setUp() {
        super.setUp()
        storage = ArchetypeStorage()
        movementSystem = MovementSystem(storage: storage)
        entity1 = Entity(id: "Entity_1")
        entity2 = Entity(id: "Entity_2")
    }

    func testUpdatePositionWithVelocity() {
        let position = Position(x: 0.0, y: 0.0)
        let velocity = Velocity(dx: 2.0, dy: 3.0)
        storage.add(component: position, to: entity1)
        storage.add(component: velocity, to: entity1)
        movementSystem.update(deltaTime: 1.0)
        let newPosition = storage.find(componentType: Position.self, in: entity1)
        XCTAssertEqual(newPosition?.x, 2.0)
        XCTAssertEqual(newPosition?.y, 3.0)
    }

    func testNoUpdateWithoutVelocity() {
        let position = Position(x: 0.0, y: 0.0)
        storage.add(component: position, to: entity1)
        movementSystem.update(deltaTime: 1.0)
        let newPosition = storage.find(componentType: Position.self, in: entity1)
        XCTAssertEqual(newPosition?.x, 0.0)
        XCTAssertEqual(newPosition?.y, 0.0)
    }

    func testUpdateWithZeroDeltaTime() {
        let position = Position(x: 0.0, y: 0.0)
        let velocity = Velocity(dx: 2.0, dy: 3.0)
        storage.add(component: position, to: entity1)
        storage.add(component: velocity, to: entity1)
        movementSystem.update(deltaTime: 0.0)
        let newPosition = storage.find(componentType: Position.self, in: entity1)
        XCTAssertEqual(newPosition?.x, 0.0)
        XCTAssertEqual(newPosition?.y, 0.0)
    }

    func testUpdateWithMultipleEntities() {
        let position1 = Position(x: 0.0, y: 0.0)
        let velocity1 = Velocity(dx: 1.0, dy: 1.0)
        let position2 = Position(x: 10.0, y: 10.0)
        let velocity2 = Velocity(dx: -2.0, dy: -2.0)
        storage.add(component: position1, to: entity1)
        storage.add(component: velocity1, to: entity1)
        storage.add(component: position2, to: entity2)
        storage.add(component: velocity2, to: entity2)
        movementSystem.update(deltaTime: 1.0)
        let newPosition1 = storage.find(componentType: Position.self, in: entity1)
        let newPosition2 = storage.find(componentType: Position.self, in: entity2)
        XCTAssertEqual(newPosition1?.x, 1.0)
        XCTAssertEqual(newPosition1?.y, 1.0)
        XCTAssertEqual(newPosition2?.x, 8.0)
        XCTAssertEqual(newPosition2?.y, 8.0)
    }

    func testNoUpdateIfNoMatchingEntities() {
        let position = Position(x: 0.0, y: 0.0)
        storage.add(component: position, to: entity1)
        movementSystem.update(deltaTime: 1.0)
        let newPosition = storage.find(componentType: Position.self, in: entity1)
        XCTAssertEqual(newPosition?.x, 0.0)
        XCTAssertEqual(newPosition?.y, 0.0)
    }

    func testNoMovementWithoutComponents() {
        movementSystem.update(deltaTime: 1.0)
        XCTAssertNil(storage.find(componentType: Position.self, in: entity1))
    }
}
