# Ecsity

Ecsity is a lightweight entity-component-system package written in native Swift. It’s built for small games, with a compact API that’s easy to learn so you can get straight to writing gameplay code.

## What is an ECS?

An ECS organizes a game through composition. An **entity** identifies a game object. A **component** holds data. A **system** implements a behavior by working with entities that have the components it needs.

To design a feature, start with the behavior you want and ask, “What data does it need?” Put that data in components, and the same system can work with any entity that has them.

For example, `MovementSystem` uses `Velocity` to update `Position`. `DisplaySystem` uses `Position` and `Display` to draw each entity at its current location. A ship with all three components moves and appears on screen. Remove its `Velocity`, and the ship stops moving while `DisplaySystem` keeps drawing it.

## Writing gameplay

Define your components as Swift structs. Adding the first component registers the entity.

```swift
import Ecsity

struct Position: Component { var x, y: Double }
struct Velocity: Component { var dx, dy: Double }

let engine = Engine()
let ship = Entity()

engine.add(component: Position(x: 0, y: 0), to: ship)
engine.add(component: Velocity(dx: 80, dy: 0), to: ship)
```

Each system implements `update(time:)` and queries for the components it needs. When a system changes a struct component, it writes the updated value back with `engine.add(component:to:)`.

Call `engine.update(deltaTime:)` from your game loop to run the systems in the order you added them. In the SpriteKit example, movement runs before display so each ship is drawn at its new position in the same frame. [Explore the SpriteKit example](https://github.com/johnrnyquist/SimpleEcsityProject)

## Installation

In Xcode, add `https://github.com/johnrnyquist/Ecsity.git` as a package dependency. Choose **Up to Next Major Version** starting at `1.0.0`, and add the `Ecsity` product to your game target.
