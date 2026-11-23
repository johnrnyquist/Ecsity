import XCTest
import Ecsity

final class EntityMembershipTests: XCTestCase {
    private let engine = Engine()
    private let entity = Entity()
    private let neighbor = Entity()
    private let position = Position(x: 1, y: 2)
    private let velocity = Velocity(dx: 3, dy: 4)

    func testReplacingAndDeletingAComponentReleasesEachValue() {
        weak var replaced: Position?
        do {
            let first = Position(x: 1, y: 0)
            engine.add(component: first, to: entity)
            replaced = first
        }
        XCTAssertNotNil(replaced)
        weak var deleted: Position?
        do {
            let second = Position(x: 2, y: 0)
            engine.add(component: second, to: entity)
            deleted = second
        }
        XCTAssertNil(replaced)
        XCTAssertNotNil(deleted)
        engine.remove(entity: entity)
        XCTAssertNil(deleted)
    }

    func testAddingAnEmptyEntityIsIdempotent() {
        let addEntity: (Entity) -> Void = engine.add(entity:)
        addEntity(entity)
        engine.add(entity: entity)

        XCTAssertEqual(engine.numEntities, 1)
        XCTAssertEqual(engine.findEntities(with: []), [entity])
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [])
        XCTAssertNil(engine.find(componentType: Position.self, in: entity))

        engine.remove(entity: entity)
        XCTAssertEqual(engine.numEntities, 0)
        XCTAssertEqual(engine.findEntities(with: []), [])
    }

    func testFirstComponentRegistersAnEntity() {
        XCTAssertEqual(engine.findEntities(with: []), [])
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [])
        XCTAssertEqual(engine.findEntities(with: [Position.self, Velocity.self]), [])

        engine.add(component: position, to: entity)
        XCTAssertEqual(engine.numEntities, 1)
        XCTAssertEqual(engine.findEntities(with: []), [entity])
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [entity])
        XCTAssertEqual(engine.findEntities(with: [Position.self, Velocity.self]), [])

        engine.add(component: velocity, to: entity)
        XCTAssertTrue(engine.find(componentType: Position.self, in: entity) === position)
        XCTAssertEqual(engine.findEntities(with: [Position.self, Velocity.self]), [entity])
    }

    func testRemovingTheLastComponentUnregistersAnExplicitlyAddedEntity() {
        engine.add(entity: entity)
        engine.add(entity: neighbor)

        engine.remove(componentType: Position.self, from: entity)
        XCTAssertEqual(engine.findEntities(with: []), [entity, neighbor])
        XCTAssertEqual(engine.numEntities, 2)
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [])

        engine.add(component: position, to: entity)
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [entity])

        engine.remove(componentType: Position.self, from: entity)
        XCTAssertEqual(engine.findEntities(with: []), [neighbor])
        XCTAssertEqual(engine.numEntities, 1)
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [])
        XCTAssertNil(engine.find(componentType: Position.self, in: entity))

        engine.add(component: position, to: entity)
        XCTAssertEqual(engine.findEntities(with: []), [entity, neighbor])
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [entity])
    }

    func testRemovingAndReaddingAComponentUpdatesCachedMembership() {
        for member in [entity, neighbor] {
            engine.add(component: position, to: member)
            engine.add(component: velocity, to: member)
        }
        XCTAssertEqual(engine.findEntities(with: [Velocity.self]), [entity, neighbor])
        XCTAssertEqual(engine.findEntities(with: [Position.self, Velocity.self]), [entity, neighbor])
        engine.remove(componentType: Velocity.self, from: entity)
        XCTAssertEqual(engine.findEntities(with: [Velocity.self]), [neighbor])
        XCTAssertEqual(engine.findEntities(with: [Position.self, Velocity.self]), [neighbor])
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [entity, neighbor])
        XCTAssertTrue(engine.find(componentType: Position.self, in: entity) === position)
        engine.add(component: velocity, to: entity)
        XCTAssertEqual(engine.findEntities(with: [Position.self, Velocity.self]), [entity, neighbor])
    }

    func testQueriesFromAReleasedComponentSeeTheCompletedMove() {
        final class OnRemoval: Component {
            let callback: () -> Void
            init(_ callback: @escaping () -> Void) { self.callback = callback }
            deinit { callback() }
        }

        let entity = self.entity
        let engine = self.engine
        var released = false
        engine.add(component: position, to: entity)
        engine.add(component: OnRemoval { [weak engine] in
            released = true
            XCTAssertEqual(engine?.findEntities(with: [Position.self]), [entity])
            XCTAssertEqual(engine?.findEntities(with: [OnRemoval.self]), [])
        }, to: entity)
        XCTAssertEqual(engine.findEntities(with: [OnRemoval.self]), [entity])

        engine.remove(componentType: OnRemoval.self, from: entity)

        XCTAssertTrue(released)
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [entity])
    }

    func testAddingAPopulatedEntityPreservesItsComponents() {
        let neighborPosition = Position(x: 5, y: 6)
        let neighborVelocity = Velocity(dx: 7, dy: 8)
        engine.add(component: position, to: entity)
        engine.add(component: velocity, to: entity)
        engine.add(component: neighborPosition, to: neighbor)
        engine.add(component: neighborVelocity, to: neighbor)
        XCTAssertEqual(engine.findEntities(with: [Position.self, Velocity.self]), [entity, neighbor])

        engine.add(entity: entity)

        XCTAssertEqual(engine.numEntities, 2)
        XCTAssertEqual(engine.findEntities(with: []), [entity, neighbor])
        XCTAssertEqual(engine.findEntities(with: [Position.self, Velocity.self]), [entity, neighbor])
        XCTAssertTrue(engine.find(componentType: Position.self, in: entity) === position)
        let storedVelocity = engine.find(componentType: Velocity.self, in: entity)
        XCTAssertEqual(storedVelocity?.dx, velocity.dx)
        XCTAssertEqual(storedVelocity?.dy, velocity.dy)
        XCTAssertTrue(engine.find(componentType: Position.self, in: neighbor) === neighborPosition)
        let storedNeighborVelocity = engine.find(componentType: Velocity.self, in: neighbor)
        XCTAssertEqual(storedNeighborVelocity?.dx, neighborVelocity.dx)
        XCTAssertEqual(storedNeighborVelocity?.dy, neighborVelocity.dy)

        engine.remove(entity: entity)
        XCTAssertEqual(engine.findEntities(with: [Position.self, Velocity.self]), [neighbor])
    }
}
