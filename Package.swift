// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package


let package = Package(
    name: "RelaySDK",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "RelaySDK", targets: ["RelaySDK"])
    ],
    dependencies: [
//        .package(url: "https://github.com/nats-io/nats.swift.git", from: "0.4.0"),
//        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.33.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2")
    ],
    targets: [
        .target(
            name: "RelaySDK",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "RelaySDKTests",
            dependencies: [
                "RelaySDK",
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
    ]
)
