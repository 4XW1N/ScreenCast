// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenCast",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "ScreenCast", targets: ["ScreenCast"])
    ],
    dependencies: [
        .package(url: "https://github.com/stasel/WebRTC.git", from: "120.0.0")
    ],
    targets: [
        .target(
            name: "ScreenCast",
            dependencies: [
                .product(name: "WebRTC", package: "WebRTC")
            ],
            path: "ScreenCast",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)