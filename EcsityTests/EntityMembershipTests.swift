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

    func testReservedTypesMatchOnlyAfterValuesAreWritten() {
        let signature = Set([ObjectIdentifier(Position.self), ObjectIdentifier(Velocity.self)])
        let archetype = engine.add(entity: entity, withComponents: signature)
        _ = engine.add(entity: neighbor, withComponents: signature)
        XCTAssertEqual(engine.findEntities(with: []), [entity, neighbor])
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [])
        engine.add(component: position, to: entity)
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [entity])
        XCTAssertEqual(engine.findEntities(with: [Position.self, Velocity.self]), [])
        engine.add(component: velocity, to: entity)
        XCTAssertTrue(engine.add(entity: entity, withComponents: signature) === archetype)
        XCTAssertTrue(engine.find(componentType: Position.self, in: entity) === position)
        XCTAssertEqual(engine.findEntities(with: [Position.self, Velocity.self]), [entity])
    }

    func testRemovingAnUnwrittenValuePreservesRegistration() {
        _ = engine.add(entity: entity, withComponents: [ObjectIdentifier(Position.self)])
        _ = engine.add(entity: neighbor, withComponents: [])
        engine.remove(componentType: Position.self, from: entity)
        engine.remove(componentType: Position.self, from: neighbor)
        XCTAssertEqual(engine.findEntities(with: []), [entity, neighbor])
        XCTAssertEqual(engine.numEntities, 2)
        engine.add(component: position, to: entity)
        engine.remove(componentType: Position.self, from: entity)
        XCTAssertEqual(engine.findEntities(with: []), [neighbor])
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

    func testReregistrationKeepsOnlyOverlappingValuesAndLeavesOtherMembersUntouched() {
        for member in [entity, neighbor] {
            engine.add(component: position, to: member)
            engine.add(component: velocity, to: member)
        }
        XCTAssertEqual(engine.findEntities(with: [Velocity.self]), [entity, neighbor])
        let signature = Set([ObjectIdentifier(Position.self), ObjectIdentifier(TestComponent.self)])
        _ = engine.add(entity: entity, withComponents: signature)
        XCTAssertTrue(engine.find(componentType: Position.self, in: entity) === position)
        XCTAssertNil(engine.find(componentType: Velocity.self, in: entity))
        XCTAssertEqual(engine.find(componentType: Velocity.self, in: neighbor)?.dx, 3)
        XCTAssertEqual(engine.findEntities(with: [Velocity.self]), [neighbor])
        XCTAssertEqual(engine.findEntities(with: [TestComponent.self]), [])
        _ = engine.add(entity: entity, withComponents: [])
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [neighbor])
        XCTAssertEqual(engine.findEntities(with: []), [entity, neighbor])
        engine.remove(entity: entity)
        XCTAssertEqual(engine.findEntities(with: [Position.self]), [neighbor])
    }
}
