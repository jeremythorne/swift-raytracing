// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "raytracing",
    // dependencies: [
    //     .package(url: "https://github.com/twostraws/SwiftGD.git", from: "2.0.0")
    // ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "raytracing",
            // dependencies: ["SwiftGD"],
            linkerSettings:[.unsafeFlags(["-lm"])]
        )
    ]
)
