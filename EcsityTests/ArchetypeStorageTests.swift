import XCTest
@testable import Ecsity

class ArchetypeStorageTests: XCTestCase {
    var storage: ArchetypeStorage!
    var entity1, entity2, entity3: Entity!

    override func setUp() {
        super.setUp()
        storage = ArchetypeStorage()
        entity1 = Entity(id: "Entity_1")
        entity2 = Entity(id: "Entity_2")
        entity3 = Entity(id: "Entity_3")
    }

    func testAddComponentToEntityWithDifferentArchetype() {
        storage.add(component: Position(x: 1.0, y: 1.0), to: entity1)
        guard let archetype1 = storage.archetype(for: entity1)
        else {
            XCTFail("Archetype not created for entity")
            return
        }
        XCTAssertTrue(archetype1.contains(componentType: ObjectIdentifier(Position.self)))
        storage.add(component: Velocity(dx: 1.0, dy: 1.0), to: entity1)
        guard let archetype2 = storage.archetype(for: entity1)
        else {
            XCTFail("Archetype not updated for entity")
            return
        }
        XCTAssertFalse(storage.allArchetypes.contains(archetype1))
        XCTAssertNotNil(archetype2)
        XCTAssertTrue(archetype2.contains(componentType: ObjectIdentifier(Position.self)))
        XCTAssertTrue(archetype2.contains(componentType: ObjectIdentifier(Velocity.self)))
    }

    func testAddComponentToEntityWithExistingArchetype() {
        let initialPosition = Position(x: 0.0, y: 0.0)
        storage.add(component: initialPosition, to: entity1)
        // Add another Position component to trigger the innermost else branch in add(component:to:)
        let newPosition = Position(x: 1.0, y: 1.0)
        storage.add(component: newPosition, to: entity1)
        if let updatedPosition = storage.find(componentType: Position.self, in: entity1) {
            XCTAssertEqual(updatedPosition.x, 1.0)
            XCTAssertEqual(updatedPosition.y, 1.0)
        } else {
            XCTFail("Position component not updated correctly in entity's archetype")
        }
    }

    func testAddComponentToEntityWithoutArchetype() {
        // Ensuring the entity has no archetype associated
        XCTAssertNil(storage.archetype(for: entity1))
        // Adding a component to the entity
        let position = Position(x: 0.0, y: 0.0)
        storage.add(component: position, to: entity1)
        // Verifying that a new archetype is created and associated with the entity
        XCTAssertNotNil(storage.archetype(for: entity1))
        let newArchetype = storage.archetype(for: entity1)
        XCTAssertTrue(newArchetype?.componentTypes.contains(ObjectIdentifier(Position.self)) ?? false)
        XCTAssertEqual(storage.numArchetypes, 1)
    }

    func testAddComponent() {
        storage.add(component: Position(x: 1.0, y: 1.0), to: entity1)
        XCTAssertNotNil(storage.find(componentType: Position.self, in: entity1))
    }

    func testAddingDifferentComponents() {
        storage.add(component: Position(x: 1.0, y: 1.0), to: entity1)
        storage.add(component: Velocity(dx: 1.0, dy: 1.0), to: entity1)
        XCTAssertNotNil(storage.find(componentType: Position.self, in: entity1))
        XCTAssertNotNil(storage.find(componentType: Velocity.self, in: entity1))
    }

    func testUpdateComponent() {
        storage.add(component: Position(x: 1.0, y: 1.0), to: entity1)
        storage.add(component: Position(x: 2.0, y: 2.0), to: entity1)
        let position = storage.find(componentType: Position.self, in: entity1)!
        XCTAssertEqual(position.x, 2.0)
        XCTAssertEqual(position.y, 2.0)
    }

    func testRemoveEntity() {
        storage.add(component: Position(x: 1.0, y: 1.0), to: entity1)
        storage.remove(entity: entity1)
        XCTAssertNil(storage.archetype(for: entity1))
        XCTAssertNil(storage.find(componentType: Position.self, in: entity1))
        XCTAssertTrue(storage.allArchetypes.isEmpty, "Archetypes should be empty after removing the only entity")
        XCTAssertTrue(storage.allComponentTypesToArchetype.isEmpty,
                      "Component types to archetype mapping should be empty after removing the only entity")
    }

    func testArchetypeManagement() {
        storage.add(component: Position(x: 1.0, y: 1.0), to: entity1)
        storage.add(component: Velocity(dx: 1.0, dy: 1.0), to: entity1)
        storage.remove(entity: entity1)
        XCTAssertNil(storage.archetype(for: entity1))
        XCTAssertTrue(storage.allArchetypes.isEmpty, "Archetypes should be empty after removing the only entity")
    }

    func testFindEntitiesWithComponents() {
        storage.add(component: Position(x: 1.0, y: 1.0), to: entity1)
        storage.add(component: Velocity(dx: 1.0, dy: 1.0), to: entity2)
        let entitiesWithPosition = storage.findEntities(with: [Position.self])
        let entitiesWithVelocity = storage.findEntities(with: [Velocity.self])
        XCTAssertTrue(entitiesWithPosition.contains(entity1), "Entities with Position should contain Entity_1")
        XCTAssertTrue(entitiesWithVelocity.contains(entity2), "Entities with Velocity should contain Entity_2")
    }

    func testFindEntitiesUsingMultipleComponentTypes() {
        storage.add(component: Position(x: 1.0, y: 1.0), to: entity1)
        storage.add(component: Velocity(dx: 1.0, dy: 1.0), to: entity1)
        storage.add(component: Position(x: 2.0, y: 2.0), to: entity2)
        storage.add(component: Velocity(dx: 2.0, dy: 2.0), to: entity2)
        storage.add(component: Velocity(dx: 3.0, dy: 3.0), to: entity3)
        let entitiesWithVelocity = storage.findEntities(with: [Velocity.self])
        XCTAssertEqual(entitiesWithVelocity.count, 3, "Entities with Velocity should contain 3 entities")
        let entitiesWithPositionAndVelocity = storage.findEntities(with: [Position.self, Velocity.self])
        XCTAssertEqual(entitiesWithPositionAndVelocity.count, 2, "Entities with Position and Velocity should contain 2 entities")
        XCTAssertTrue(entitiesWithPositionAndVelocity.contains(entity1), "Entities with Position and Velocity should contain Entity_1")
        XCTAssertTrue(entitiesWithPositionAndVelocity.contains(entity2), "Entities with Position and Velocity should contain Entity_2")
    }

    func testRemoveComponentTypeFromArchetype() {
        storage.add(component: Position(x: 1.0, y: 1.0), to: entity1)
        storage.add(component: Velocity(dx: 1.0, dy: 1.0), to: entity1)
        storage.remove(entity: entity1)
        XCTAssertNil(storage.find(componentType: Position.self, in: entity1))
        XCTAssertNil(storage.find(componentType: Velocity.self, in: entity1))
    }

    func testGlobalArchetypeCleanup() {
        storage.add(component: Position(x: 1.0, y: 1.0), to: entity1)
        storage.add(component: Position(x: 2.0, y: 2.0), to: entity2)
        storage.remove(entity: entity1)
        storage.remove(entity: entity2)
        XCTAssertTrue(storage.allArchetypes.isEmpty)
        XCTAssertTrue(storage.allComponentTypesToArchetype.isEmpty)
    }

    func testAddSameComponentTypeTwice() {
        let position = Position(x: 1.0, y: 1.0)
        storage.add(component: position, to: entity1)
        storage.add(component: position, to: entity1)
        let foundPosition = storage.find(componentType: Position.self, in: entity1)
        XCTAssertEqual(foundPosition?.x, 1.0)
        XCTAssertEqual(foundPosition?.y, 1.0)
    }

    func testRemoveNonExistentEntity() {
        storage.remove(entity: entity1)
        XCTAssertNil(storage.archetype(for: entity1))
    }
}
