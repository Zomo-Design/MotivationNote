// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MotivationNote",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MotivationNote", targets: ["MotivationNote"])
    ],
    targets: [
        .executableTarget(
            name: "MotivationNote",
            path: "Sources/MotivationNote"
        )
    ]
)
