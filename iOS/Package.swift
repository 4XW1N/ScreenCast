// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenCast",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(name: "ScreenCast", targets: ["ScreenCast"])
    ],
    targets: [
        .executableTarget(
            name: "ScreenCast",
            path: "Sources/ScreenCast",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)
