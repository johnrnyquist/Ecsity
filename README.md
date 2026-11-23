# Ecsity

A simple Swift entity-component-system library.

```swift
import Ecsity

struct Score: Component {
    let value: Int
}

let engine = Engine()
engine.add(component: Score(value: 10), to: Entity())
engine.add(component: Score(value: 10), to: Entity())
let scores = engine.findAllComponents(ofType: Score.self)
print(scores.count) // 2
```

`findAllComponents(ofType:)` returns an array with one value per attachment
stored under the supplied component type, in unspecified order. Equal values
on different entities appear separately. Component types need only conform to
`Component`. For a `Hashable` component type, wrap the returned array in
`Set(...)` to get the previous unique-value behavior.

See the [SimpleEcsityProject example](https://github.com/johnrnyquist/SimpleEcsityProject)
for a complete project.
