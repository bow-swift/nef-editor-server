// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "nef-editor-server",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "nef-editor-server", targets: ["App"]),
        .library(name: "NefEditorData", targets: ["NefEditorData"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/bow-swift/nef.git", .revision("c981b63840c42f472f53ac074bca76f5066e8ee8")),
    ],
    targets: [
        .target(name: "NefEditorData"),
        .target(name: "App", dependencies: [
            .target(name: "NefEditorData"),
            .product(name: "Vapor", package: "vapor"),
            .product(name: "nef", package: "nef"),
        ]),
        .target(name: "Run", dependencies: ["App"]),

        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ]),
    ]
)
