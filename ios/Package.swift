// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CoreHapticsFFI",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "CoreHapticsFFI",
            type: .dynamic,
            targets: ["CoreHapticsFFI"]
        )
    ],
    targets: [
        .target(
            name: "CoreHapticsFFI",
            dependencies: [],
            path: "Sources/CoreHapticsFFI",
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "CoreHapticsFFITests",
            dependencies: ["CoreHapticsFFI"],
            path: "Tests/CoreHapticsFFITests"
        )
    ]
)

