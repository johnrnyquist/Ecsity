import XCTest
@testable import Ecsity

// Define the ArchetypeTests class
class ArchetypeTests: XCTestCase {
    var archetype: Archetype!
    var entity1: Entity!
    var entity2: Entity!
    var position: Position!

    override func setUp() {
        super.setUp()
        position = Position(x: 1.0, y: 1.0)
        let componentTypes = Set([ObjectIdentifier(Position.self), ObjectIdentifier(Velocity.self)])
        archetype = Archetype(componentTypes: componentTypes)
        entity1 = Entity(id: "Entity_1")
        entity2 = Entity(id: "Entity_2")
    }

    func testAddEntity() {
        archetype.add(entity1)
        XCTAssertTrue(archetype.entities.contains(entity1))
    }

    func testAddSameEntityTwice() {
        archetype.add(entity1)
        archetype.add(entity1)
        XCTAssertEqual(archetype.entities.count, 1)
    }

    func testAddMultipleEntities() {
        archetype.add(entity1)
        archetype.add(entity2)
        XCTAssertTrue(archetype.entities.contains(entity1))
        XCTAssertTrue(archetype.entities.contains(entity2))
    }

    func testInit() {
        XCTAssertEqual(archetype.componentTypes.count, 2)
        XCTAssertEqual(archetype.entities.count, 0)
        XCTAssertEqual(archetype.components.count, 0)
    }

    func testAddComponentType() {
        let component = TestComponent(value: 42)
        archetype.add(component: component, to: entity1)
        XCTAssertTrue(archetype.entities.contains(entity1))
        let retrievedComponent = archetype.find(componentType: TestComponent.self, in: entity1)
        XCTAssertEqual(retrievedComponent?.value, component.value)
    }

    func testAddComponent() {
        let position = Position(x: 1.0, y: 1.0)
        archetype.add(component: position, to: entity1)
        let retrievedPosition = archetype.find(componentType: Position.self, in: entity1)
        XCTAssertEqual(retrievedPosition?.x, position.x)
        XCTAssertEqual(retrievedPosition?.y, position.y)
    }

    func testContainsComponentType() {
        XCTAssertTrue(archetype.contains(componentType: ObjectIdentifier(Position.self)))
        XCTAssertTrue(archetype.contains(componentType: ObjectIdentifier(Velocity.self)))
    }

    func testRemoveEntity() {
        archetype.add(component: position, to: entity1)
        archetype.add(component: position, to: entity2)
        XCTAssertTrue(archetype.entities.contains(entity1))
        XCTAssertTrue(archetype.entities.contains(entity2))
        archetype.remove(entity1)
        XCTAssertFalse(archetype.entities.contains(entity1))
        XCTAssertTrue(archetype.entities.contains(entity2))
        archetype.remove(entity2)
        XCTAssertFalse(archetype.entities.contains(entity2))
    }

    func testRemoveComponentFromEntity() {
        let entity = Entity(id: "Entity_1")
        let component = TestComponent(value: 42)
        let archetype = Archetype(componentTypes: [ObjectIdentifier(TestComponent.self)])
        archetype.add(component: component, to: entity)
        XCTAssertTrue(archetype.entities.contains(entity))
        archetype.remove(componentType: TestComponent.self, from: entity)
        XCTAssertFalse(archetype.entities.contains(entity))
        XCTAssertNil(archetype.find(componentType: TestComponent.self, in: entity))
    }

    func testRemoveComponentTypeNotInArchetype() {
        let entity = Entity(id: "Entity_1")
        let archetype = Archetype(componentTypes: [ObjectIdentifier(TestComponent.self)])
        archetype.remove(componentType: TestComponent.self, from: entity)
        XCTAssertFalse(archetype.entities.contains(entity))
    }

    func testRemoveComponentFromEntityWithMultipleComponents() {
        let entity = Entity(id: "Entity_1")
        let component1 = TestComponent(value: 42)
        let component2 = AnotherComponent(value: "test")
        let archetype = Archetype(componentTypes: [ObjectIdentifier(TestComponent.self), ObjectIdentifier(AnotherComponent.self)])
        archetype.add(component: component1, to: entity)
        archetype.add(component: component2, to: entity)
        XCTAssertTrue(archetype.entities.contains(entity))
        archetype.remove(componentType: TestComponent.self, from: entity)
        XCTAssertTrue(archetype.entities.contains(entity))
        XCTAssertNil(archetype.find(componentType: TestComponent.self, in: entity))
        XCTAssertNotNil(archetype.find(componentType: AnotherComponent.self, in: entity))
    }

    func testFindComponent() {
        let velocity = Velocity(dx: 0.5, dy: 0.75)
        archetype.add(component: velocity, to: entity1)
        let retrievedVelocity = archetype.find(componentType: Velocity.self, in: entity1)
        XCTAssertEqual(retrievedVelocity?.dx, velocity.dx)
        XCTAssertEqual(retrievedVelocity?.dy, velocity.dy)
    }

    func testDescription() {
        let position = Position(x: 2.0, y: 2.0)
        archetype.add(component: position, to: entity1)
        let description = archetype.description
        print(description)
        XCTAssertTrue(description.contains("Archetype"))
        XCTAssertTrue(description.contains("Position"))
    }

    func testAddMultipleComponents() {
        let position = Position(x: 0.0, y: 0.0)
        let velocity = Velocity(dx: 1.0, dy: 1.0)
        archetype.add(component: position, to: entity1)
        archetype.add(component: velocity, to: entity1)
        let retrievedPosition = archetype.find(componentType: Position.self, in: entity1)
        let retrievedVelocity = archetype.find(componentType: Velocity.self, in: entity1)
        XCTAssertEqual(retrievedPosition?.x, position.x)
        XCTAssertEqual(retrievedPosition?.y, position.y)
        XCTAssertEqual(retrievedVelocity?.dx, velocity.dx)
        XCTAssertEqual(retrievedVelocity?.dy, velocity.dy)
    }

    func testComponentNotFound() {
        let retrievedPosition = archetype.find(componentType: Position.self, in: entity2)
        XCTAssertNil(retrievedPosition)
    }

    func testEntitiesContainment() {
        let position = Position(x: 1.0, y: 1.0)
        archetype.add(component: position, to: entity1)
        archetype.add(component: position, to: entity2)
        XCTAssertTrue(archetype.entities.contains(entity1))
        XCTAssertTrue(archetype.entities.contains(entity2))
    }

    // Swift
    func testAddSameComponentTypeTwice() {
        let position = Position(x: 1.0, y: 1.0)
        archetype.add(component: position, to: entity1)
        archetype.add(component: position, to: entity1)
        let foundPosition = archetype.find(componentType: Position.self, in: entity1)
        XCTAssertEqual(foundPosition?.x, 1.0)
        XCTAssertEqual(foundPosition?.y, 1.0)
    }

    func testRemoveComponentNotInEntity() {
        let entity = Entity(id: "Entity_1")
        archetype.remove(componentType: Position.self, from: entity)
        XCTAssertFalse(archetype.entities.contains(entity))
    }

    func testGetAllComponentsForEntityWithNoComponents() {
        let components = archetype.getAllComponents(for: entity1)
        XCTAssertTrue(components.isEmpty, "Components should be empty for an entity with no components")
    }

    func testGetAllComponentsForEntityWithOneComponent() {
        let position = Position(x: 1.0, y: 1.0)
        archetype.add(component: position, to: entity1)
        let components = archetype.getAllComponents(for: entity1)
        XCTAssertEqual(components.count, 1, "There should be one component for the entity")
        XCTAssertTrue(components.first is Position, "The component should be of type Position")
    }

    func testGetAllComponentsForEntityWithMultipleComponents() {
        let position = Position(x: 1.0, y: 1.0)
        let velocity = Velocity(dx: 1.0, dy: 1.0)
        archetype.add(component: position, to: entity1)
        archetype.add(component: velocity, to: entity1)
        let components = archetype.getAllComponents(for: entity1)
        XCTAssertEqual(components.count, 2, "There should be two components for the entity")
        XCTAssertTrue(components.contains { $0 is Position }, "Components should contain Position")
        XCTAssertTrue(components.contains { $0 is Velocity }, "Components should contain Velocity")
    }

    func testGetAllComponentsForEntityWithDifferentComponents() {
        let position = Position(x: 1.0, y: 1.0)
        let velocity = Velocity(dx: 1.0, dy: 1.0)
        archetype.add(component: position, to: entity1)
        archetype.add(component: velocity, to: entity2)
        let componentsEntity1 = archetype.getAllComponents(for: entity1)
        let componentsEntity2 = archetype.getAllComponents(for: entity2)
        XCTAssertEqual(componentsEntity1.count, 1, "Entity1 should have one component")
        XCTAssertEqual(componentsEntity2.count, 1, "Entity2 should have one component")
        XCTAssertTrue(componentsEntity1.first is Position, "Entity1's component should be of type Position")
        XCTAssertTrue(componentsEntity2.first is Velocity, "Entity2's component should be of type Velocity")
    }
}

// Mock components for testing
struct TestComponent: Component {
    let value: Int
}

struct AnotherComponent: Component {
    let value: String
}
