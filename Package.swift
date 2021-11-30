// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MetallicImage",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_11),
        .tvOS(.v9)
    ],
    products: [
        .library(
            name: "MetallicImage",
            type: .dynamic,
            targets: ["MetallicImage"]),
    ],
    targets: [
        .target(
            name: "MetallicImage",
            dependencies: [],
            path: "framework/MetallicImage",
            resources: [
                .process("Resources/")
            ])
    ]
)
