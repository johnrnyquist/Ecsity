import XCTest
import Ecsity

final class BulkComponentTests: XCTestCase {
    private struct Score: Component, Hashable {
        let value: Int
    }

    private struct Label: Component {
        let text: String
    }

    private class BaseComponent: Component {}
    private final class DerivedComponent: BaseComponent {}

    func testEqualValuesRemainSeparateAcrossSharedAndDistinctArchetypes() {
        let engine = Engine()
        let first = Entity(id: "first")
        let second = Entity(id: "second")
        let third = Entity(id: "third")
        let empty = Entity(id: "empty")

        engine.add(component: Score(value: 8), to: first)
        engine.add(component: Score(value: 8), to: second)
        engine.add(component: Score(value: 8), to: third)
        engine.add(component: Label(text: "third"), to: third)
        engine.add(entity: empty)

        let result = engine.findAllComponents(ofType: Score.self)

        XCTAssertEqual(result.map(\.value), [8, 8, 8])
    }

    func testNonHashableQueryReflectsOverwritesAndRemovals() {
        let engine = Engine()
        let first = Entity(id: "first")
        let second = Entity(id: "second")
        engine.add(component: Label(text: "previous"), to: first)
        engine.add(component: Label(text: "second"), to: second)
        engine.add(component: Score(value: 1), to: first)

        let initial: [Label] = engine.findAllComponents(ofType: Label.self)
        XCTAssertEqual(initial.map(\.text).sorted(), ["previous", "second"])

        engine.add(component: Label(text: "current"), to: first)
        XCTAssertEqual(engine.findAllComponents(ofType: Label.self).map(\.text).sorted(),
                       ["current", "second"])

        engine.remove(componentType: Label.self, from: first)
        XCTAssertEqual(engine.findAllComponents(ofType: Label.self).map(\.text), ["second"])

        engine.remove(entity: second)
        XCTAssertTrue(engine.findAllComponents(ofType: Label.self).isEmpty)
        XCTAssertEqual(engine.findAllComponents(ofType: Score.self).map(\.value), [1])
    }

    func testQueryUsesTheSuppliedMetatypeWhenTheGenericTypeIsABaseClass() {
        let engine = Engine()
        let base = BaseComponent()
        let derived = DerivedComponent()
        engine.add(component: base, to: Entity(id: "base"))
        engine.add(component: derived, to: Entity(id: "derived"))
        let derivedType: BaseComponent.Type = DerivedComponent.self

        let derivedResults: [BaseComponent] = engine.findAllComponents(ofType: derivedType)
        let baseResults = engine.findAllComponents(ofType: BaseComponent.self)

        XCTAssertEqual(derivedResults.map(ObjectIdentifier.init), [ObjectIdentifier(derived)])
        XCTAssertEqual(baseResults.map(ObjectIdentifier.init), [ObjectIdentifier(base)])
    }
}
