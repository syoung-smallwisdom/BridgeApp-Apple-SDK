// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgeApp",
    defaultLocalization: "en",
    platforms: [
        // Add support for all platforms starting from a specific version.
        .macOS(.v10_15),
        .iOS(.v11),
        .watchOS(.v4),
        .tvOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BridgeApp",
            targets: ["BridgeApp"]),
//        .library(
//            name: "BridgeAppUI",
//            targets: ["BridgeAppUI"]),
//        .library(
//            name: "DataTracking",
//            targets: ["DataTracking"]),

    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "SageResearch",
                 url: "https://github.com/Sage-Bionetworks/SageResearch.git",
                 from: "3.14"),
        .package(name: "BridgeSDK",
                 url: "https://github.com/syoung-smallwisdom/BridgeSDK.git",
                 .branch("swiftPM")),
        .package(name: "JsonModel",
                 url: "https://github.com/Sage-Bionetworks/JsonModel-Swift.git",
                 from: "1.0.2"),
    ],
    targets: [

        // Research is the main target included in this repo. The "Formatters" and
        // "ExceptionHandler" targets are developed in Obj-c so they require a
        // separate target.
        .target(
            name: "BridgeApp",
            dependencies: ["SageResearch",
                           "BridgeSDK",
                           "JsonModel",
            ],
            path: "BridgeApp/BridgeApp/",
            exclude: ["Info-iOS.plist"],
            resources: [
                .process("Localization"),
            ]
            ),
        
//        // ResearchUI currently only supports iOS devices. This includes views and view
//        // controllers and references UIKit.
//        .target(
//            name: "ResearchUI",
//            dependencies: [
//                "Research",
//            ],
//            path: "Research/ResearchUI/",
//            exclude: ["Info-iOS.plist"],
//            resources: [
//                .process("PlatformContext/Resources"),
//                .process("iOS/Resources"),
//            ]),
//
//        // ResearchAudioRecorder is used to allow recording dbFS level.
//        .target(
//            name: "ResearchAudioRecorder",
//            dependencies: [
//                "Research",
//            ],
//            path: "Research/ResearchAudioRecorder/",
//            exclude: ["Info.plist"]),
//
//        // ResearchMotion is used to allow recording motion sensors.
//        .target(
//            name: "ResearchMotion",
//            dependencies: [
//                "Research",
//            ],
//            path: "Research/ResearchMotion/",
//            exclude: ["Info.plist"],
//            resources: [
//                .process("Resources"),
//            ]),
//
//        // ResearchLocation is used to allow location authorization and record distance
//        // travelled.
//        .target(
//            name: "ResearchLocation",
//            dependencies: [
//                "Research",
//                "ResearchMotion",
//            ],
//            path: "Research/ResearchLocation/",
//            exclude: ["Info.plist"]),
//
//        // The following targets are set up for unit testing.
//        .target(
//            name: "Research_UnitTest",
//            dependencies: ["Research",
//                           "ResearchUI",
//            ],
//            path: "Research/Research_UnitTest/",
//            exclude: ["Info.plist"]),
//        .target(name: "NSLocaleSwizzle",
//                dependencies: [],
//                path: "Research/NSLocaleSwizzle/",
//                exclude: ["Info.plist"]),
//        .testTarget(
//            name: "ResearchTests",
//            dependencies: [
//                "Research",
//                "Research_UnitTest",
//                "NSLocaleSwizzle",
//            ],
//            path: "Research/ResearchTests/",
//            exclude: ["Info-iOS.plist"],
//            resources: [
//                .process("Resources"),
//            ]),
//        .testTarget(
//            name: "ResearchUITests",
//            dependencies: ["ResearchUI"],
//            path: "Research/ResearchUITests/",
//            exclude: ["Info.plist"]),
//        .testTarget(
//            name: "ResearchMotionTests",
//            dependencies: [
//                "ResearchMotion",
//                "Research_UnitTest",
//            ],
//            path: "Research/ResearchMotionTests/",
//            exclude: ["Info.plist"]),
//        .testTarget(
//            name: "ResearchLocationTests",
//            dependencies: [
//                "ResearchLocation",
//                "Research_UnitTest",
//            ],
//            path: "Research/ResearchLocationTests/",
//            exclude: ["Info.plist"]),
        
    ]
)
