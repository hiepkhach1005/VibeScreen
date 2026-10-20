// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VibeScreen",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VibeScreenCore",
            targets: ["VibeScreenCore"]
        ),
        .executable(
            name: "VibeScreen",
            targets: ["VibeScreen"]
        )
    ],
    targets: [
        .target(
            name: "VibeScreenCore"
        ),
        .executableTarget(
            name: "VibeScreen",
            dependencies: ["VibeScreenCore"],
            exclude: [
                // Xcode app targets consume this file when packaging the app.
                // SwiftPM synthesizes executable metadata and forbids Info.plist
                // as a top-level resource in a resource bundle.
                "Resources/Info.plist",
                // App icon files are copied into the .app bundle by the local
                // packaging script rather than compiled as SwiftPM resources.
                "Resources/AppIcon-1024.png",
                "Resources/AppIcon.iconset",
                "Resources/VibeScreenIcon.icns"
            ]
        ),
        .testTarget(
            name: "VibeScreenCoreTests",
            dependencies: ["VibeScreenCore"]
        )
    ]
)
