// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpellCaster",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SpellCaster",
            targets: ["SpellCaster"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SpellCaster",
            dependencies: [],
            path: "SpellCaster",
            resources: [
                .copy("Resources/ShellIntegration")
            ]
        )
    ]
)
