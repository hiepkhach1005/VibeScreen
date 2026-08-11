// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ColorControlMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ColorControlCore",
            targets: ["ColorControlCore"]
        ),
        .executable(
            name: "ColorControlMac",
            targets: ["ColorControlMac"]
        )
    ],
    targets: [
        .target(
            name: "ColorControlCore"
        ),
        .executableTarget(
            name: "ColorControlMac",
            dependencies: ["ColorControlCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ColorControlCoreTests",
            dependencies: ["ColorControlCore"]
        )
    ]
)
