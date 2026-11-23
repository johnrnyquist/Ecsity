# Ecsity

Ecsity is an entity-component-system (ECS) library for small Swift games. To write gameplay code, you need three concepts. An **entity** identifies a game object. A **component** holds game data in a Swift struct or class that adopts the empty `Component` protocol. A **system** implements one method, `update(time:)`, and asks the engine for the entities it can act on.

## When Ecsity fits

- **An arcade game with shared behaviors.** Ships, projectiles, and drifting pickups can all use the same movement code. Give each a position and a velocity. The movement system can update all three without knowing which kind of object it received.
- **A game where abilities or states change during play.** A stunned enemy can lose its velocity while keeping its position, health, and sprite. Movement stops applying to that enemy. Drawing and damage continue to work.
- **A prototype inside an existing Swift game.** Start with one rule, such as expiring pickups after a few seconds. Your scene can keep handling touches, drawing, and the game clock. You can exercise the rule in a test by creating an engine and advancing it by a known amount of time.

Ecsity runs systems one at a time in the order you add them. For example, register movement before display so the renderer sees each ship's new position in the same frame.

## One movement rule

This system moves anything that has both a position and a velocity. Because `Position` is a struct, it writes the updated value back to the engine.

```swift
import Ecsity
import Foundation

struct Position: Component { var x: Double }
struct Velocity: Component { let pointsPerSecond: Double }

struct Movement: System {
    weak var engine: Engine?

    func update(time: TimeInterval) {
        guard let engine else { return }
        for entity in engine.findEntities(with: [Position.self, Velocity.self]) {
            guard var position = engine.find(componentType: Position.self, in: entity),
                  let velocity = engine.find(componentType: Velocity.self, in: entity)
            else { continue }

            position.x += velocity.pointsPerSecond * time
            engine.add(component: position, to: entity)
        }
    }
}
```

Adding the first component registers the ship. The game supplies elapsed seconds to `engine.update(deltaTime:)`.

```swift
let engine = Engine()
engine.add(system: Movement(engine: engine))

let ship = Entity()
let cruise = Velocity(pointsPerSecond: 80)
engine.add(component: Position(x: 0), to: ship)
engine.add(component: cruise, to: ship)
engine.update(deltaTime: 0.5) // x is now 40

engine.remove(componentType: Velocity.self, from: ship)
engine.update(deltaTime: 0.5) // x is still 40

engine.add(component: cruise, to: ship)
engine.update(deltaTime: 0.5) // x is now 80
```

In the SpriteKit example, a separate display system asks for `Position` and `Display`. A stopped ship still has both, so it stays on screen. The movement and display systems can each express their rule without checking a shared pause flag. [SpriteKit example](https://github.com/johnrnyquist/SimpleEcsityProject)

## Entity and component operations

- Use `engine.add(entity:)` when you need an empty entity. Calling it again preserves any attached components. Removing an entity's last component removes the entity from the engine.
- Calling `add(component:to:)` again with the same component type replaces that entity's value. If you previously used `add(entity:withComponents:)` to reserve types, attach the values directly.
- `findAllComponents(ofType:)` returns an array in unspecified order, with one value per attachment. Two entities at the same position contribute two positions. For a `Hashable` component, wrap the result in `Set(...)` when you want distinct values.
