// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "raytracing",
    targets: [
        .target(
            name: "Lib"
            ),
        .executableTarget(
            name: "raytracing",
            dependencies: [ .target(name: "Lib") ],
            linkerSettings:[.unsafeFlags(["-lm"])]
        ),
        .testTarget(
            name : "Tests",
            dependencies: [ .target(name: "Lib") ]
        )
    ]
)
