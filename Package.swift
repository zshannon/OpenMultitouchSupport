// swift-tools-version: 5.4

import PackageDescription

let package = Package(
    name: "OpenMultitouchSupport",
    products: [
        .library(
            name: "OpenMultitouchSupport",
            targets: ["OpenMultitouchSupport"]),
    ],
    targets: [
        .target(
            name: "OpenMultitouchSupport",
            path: "OpenMultitouchSupport",
            publicHeadersPath: ".",
            linkerSettings: [
                .linkedFramework("MultitouchSupport"),
                .unsafeFlags(["-F", "/System/Library/PrivateFrameworks"]),
                .linkedFramework("Cocoa"),
            ]
        ),
    ]
)
