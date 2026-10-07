// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("MemberImportVisibility")
]

/// Models, networking and caching shared by the iOS app, the widget and the watch app.
let package = Package(
    name: "NewsKit",
    platforms: [.iOS(.v18), .watchOS(.v11), .macOS(.v15)],
    products: [
        .library(name: "NewsKit", targets: ["NewsKit"])
    ],
    targets: [
        .target(name: "NewsKit", swiftSettings: swiftSettings),
        .testTarget(name: "NewsKitTests", dependencies: ["NewsKit"], swiftSettings: swiftSettings)
    ]
)
