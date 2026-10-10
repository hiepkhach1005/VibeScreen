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
            exclude: [
                // Xcode app targets consume this file when packaging the app.
                // SwiftPM synthesizes executable metadata and forbids Info.plist
                // as a top-level resource in a resource bundle.
                "Resources/Info.plist",
                // App icon files are copied into the .app bundle by the local
                // packaging script rather than compiled as SwiftPM resources.
                "Resources/AppIcon-1024.png",
                "Resources/AppIcon.iconset",
                "Resources/ColorControlIcon.icns"
            ]
        ),
        .testTarget(
            name: "ColorControlCoreTests",
            dependencies: ["ColorControlCore"]
        )
    ]
)
