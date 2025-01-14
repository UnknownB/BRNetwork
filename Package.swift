// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BRNetwork",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_14)
    ],
    products: [
        .library(name: "BRNetwork", targets: ["BRNetwork"]),
    ],
    targets: [
        .target(name: "BRNetwork"),
        .testTarget(name: "BRNetworkTests", dependencies: ["BRNetwork"]),
    ]
)
