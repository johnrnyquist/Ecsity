# Ecsity

A Swift entity-component-system library for small games.

```swift
import Ecsity

struct Score: Component {
    let value: Int
}

let engine = Engine()
let player = Entity()
engine.add(component: Score(value: 10), to: player)
engine.add(component: Score(value: 10), to: Entity())
let scores = engine.findAllComponents(ofType: Score.self)
print(scores.count) // 2
```

Adding the first component registers the entity with the engine. If you need
to register an empty entity, call `engine.add(entity:)`. Calling it again for
a registered entity leaves its components in place. Removing an entity's last
component removes the entity from the engine.

If you used `add(entity:withComponents:)` to reserve component types, attach
the component values directly with `add(component:to:)`.

`findAllComponents(ofType:)` returns an array with one value per attachment
stored under the supplied component type, in unspecified order. Equal values
on different entities appear separately. Component types need only conform to
`Component`. For a `Hashable` component type, wrap the returned array in
`Set(...)` to get the previous unique-value behavior.

See the [SimpleEcsityProject example](https://github.com/johnrnyquist/SimpleEcsityProject)
for a complete project.
