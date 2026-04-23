// swift-tools-version: 6.0
// Package.swift — SwiftSonic
//
// Declares the SwiftSonic library target and its test target.
// No external dependencies: only Apple's built-in frameworks are used.

import PackageDescription

let package = Package(
    name: "swiftsonic",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        /// The SwiftSonic library. Add this product to your package dependencies.
        .library(name: "SwiftSonic", targets: ["SwiftSonic"]),
    ],
    targets: [
        .target(
            name: "SwiftSonic",
            path: "Sources/SwiftSonic",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "SwiftSonicTests",
            dependencies: ["SwiftSonic"],
            path: "Tests/SwiftSonicTests",
            resources: [
                .copy("Fixtures"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
