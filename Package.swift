// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "nef-editor-server",
    products: [
        .library(name: "nef-editor-server", targets: ["App"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

