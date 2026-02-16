// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TraRead",
    platforms: [
        .macOS(.v15), // Required for TranslationSession API
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "TraRead",
            targets: ["TraRead"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package.
        .target(
            name: "TraRead",
            dependencies: [],
            path: "TraRead",
            exclude: ["TraReadApp.swift", "ContentView.swift", "Assets.xcassets"], // Exclude App entry point and View for now to focus on logic tests
            sources: ["FileHandler.swift", "TraReadViewModel.swift", "Color+Hex.swift"]
        ),
        .testTarget(
            name: "TraReadTests",
            dependencies: ["TraRead"],
            path: "TraReadTests",
            // exclude: ["sample.pdf"] - Removed to allow resource processing
            resources: [
                .process("sample.pdf")
            ]
        ),
    ]
)
