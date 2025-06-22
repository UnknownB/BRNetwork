// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BRNetwork",
    products: [
        .library(name: "BRNetwork", targets: ["BRNetwork"]),
    ],
    dependencies: [
        .package(url: "https://github.com/UnknownB/BRFoundation", branch: "main")
    ],
    targets: [
        .target(name: "BRNetwork", dependencies: ["BRFoundation"]),
        .testTarget(name: "BRNetworkTests", dependencies: ["BRNetwork"]),
    ]
)
