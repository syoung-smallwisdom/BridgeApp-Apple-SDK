// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgeApp",
    defaultLocalization: "en",
    platforms: [
        // Add support for all platforms starting from a specific version.
        .iOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BridgeApp",
            targets: ["BridgeApp"]),
        .library(
            name: "BridgeAppUI",
            targets: ["BridgeAppUI"]),
        .library(
            name: "DataTracking",
            targets: ["DataTracking"]),

    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            name: "SageResearch",
            url: "https://github.com/Sage-Bionetworks/SageResearch.git",
            from: "3.14.0"),
        .package(
            name: "BridgeSDK",
            url: "https://github.com/Sage-Bionetworks/Bridge-iOS-SDK.git",
            from: "4.4.83"),
        .package(
            name: "JsonModel",
            url: "https://github.com/Sage-Bionetworks/JsonModel-Swift.git",
            from: "1.0.2"),
    ],
    targets: [

        .target(
            name: "BridgeApp",
            dependencies: [
                .product(name: "Research", package: "SageResearch"),
                .product(name: "ResearchUI", package: "SageResearch"),
                "BridgeSDK",
                "JsonModel",
            ],
            path: "BridgeApp/BridgeApp/iOS",
            resources: [
                .process("Localization"),
            ]
            ),
        
        .target(
            name: "BridgeAppUI",
            dependencies: [
                .product(name: "Research", package: "SageResearch"),
                .product(name: "ResearchUI", package: "SageResearch"),
                "BridgeApp",
                "BridgeSDK",
            ],
            path: "BridgeApp/BridgeAppUI/iOS",
            resources: [
                .process("Resources"),
            ]
            ),
        
        .target(
            name: "DataTracking",
            dependencies: [
                .product(name: "Research", package: "SageResearch"),
                .product(name: "ResearchUI", package: "SageResearch"),
                "BridgeApp",
                "BridgeAppUI",
                "BridgeSDK",
                "JsonModel",
            ],
            path: "BridgeApp/DataTracking/iOS",
            resources: [
                .process("Resources"),
            ]
            ),
        
    ]
)
