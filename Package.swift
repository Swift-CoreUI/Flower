// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Flower",
    platforms: [.iOS(.v11)],
    products: [
        .library(name: "Flower", targets: ["Flower"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Flower",
            dependencies: []),
        .testTarget(
            name: "FlowerTests",
            dependencies: ["Flower"]),
    ]
)
