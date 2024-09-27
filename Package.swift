// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Ecsity",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Ecsity",
            targets: ["Ecsity"]),
    ],
    dependencies: [
        // Add your dependencies here
    ],
    targets: [
        .target(
            name: "Ecsity",
            dependencies: [],
            path: "Ecsity"
        ),
        .testTarget(
            name: "EcsityTests",
            dependencies: ["Ecsity"],
            path: "EcsityTests"
        )
    ]
)
