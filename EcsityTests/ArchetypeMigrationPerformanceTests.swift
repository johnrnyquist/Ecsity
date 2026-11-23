import Ecsity
import XCTest

final class ArchetypeMigrationPerformanceTests: XCTestCase {
    private struct Position: Component { let x: Int }
    private struct Velocity: Component { let dx: Int }

    func testAddingAComponentToAnEntireArchetype() {
        let entities = (0..<4096).map { Entity(id: "ship-\($0)") }
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let engine = Engine()
            for (index, entity) in entities.enumerated() {
                engine.add(component: Position(x: index), to: entity)
            }

            startMeasuring()
            for (index, entity) in entities.enumerated() {
                engine.add(component: Velocity(dx: -index), to: entity)
            }
            stopMeasuring()

            XCTAssertEqual(engine.findEntities(with: [Position.self, Velocity.self]), Set(entities))
            XCTAssertTrue(entities.enumerated().allSatisfy { index, entity in
                engine.find(componentType: Position.self, in: entity)?.x == index &&
                    engine.find(componentType: Velocity.self, in: entity)?.dx == -index
            })
        }
    }
}
