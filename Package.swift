// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "nef-editor-server",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .library(name: "nef-editor-server", targets: ["App"]),
    ],
    dependencies: [
        .package(name: "Vapor", url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(name: "nef", url: "https://github.com/bow-swift/nef.git", .branch("develop"))
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor", "nef"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

