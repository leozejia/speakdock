// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SpeakDock",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "SpeakDockCore",
            targets: ["SpeakDockCore"]
        ),
        .executable(
            name: "SpeakDockMac",
            targets: ["SpeakDockMac"]
        ),
    ],
    targets: [
        .target(
            name: "SpeakDockCore",
            path: "Sources/SpeakDockCore"
        ),
        .executableTarget(
            name: "SpeakDockMac",
            dependencies: ["SpeakDockCore"],
            path: "Sources/SpeakDockMac",
            exclude: [
                "Resources/Info.plist",
            ],
            resources: [
                .process("Resources/Localization"),
            ]
        ),
        .testTarget(
            name: "SpeakDockCoreTests",
            dependencies: ["SpeakDockCore"],
            path: "Tests/SpeakDockCoreTests"
        ),
        .testTarget(
            name: "SpeakDockMacTests",
            dependencies: ["SpeakDockMac"],
            path: "Tests/SpeakDockMacTests"
        ),
    ]
)
