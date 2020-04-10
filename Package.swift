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
        .library(name: "NefEditorCrypto", targets: ["NefEditorCrypto"]),
    ],
    dependencies: [
        .package(name: "Vapor", url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(name: "Auth", url: "https://github.com/vapor/auth.git", from: "2.0.0"),
        .package(name: "nef", url: "https://github.com/bow-swift/nef.git", .revision("c981b63840c42f472f53ac074bca76f5066e8ee8")),
        .package(name: "SwiftCheck", url: "https://github.com/typelift/SwiftCheck.git", from: "0.8.1")
    ],
    targets: [
        .target(name: "NefEditorData"),
        .target(name: "NefEditorCrypto", dependencies: [.product(name: "Authentication", package: "Auth")]),
        .target(name: "App", dependencies: ["NefEditorData",
                                            "NefEditorCrypto",
                                            "Vapor",
                                            "nef",
                                            .product(name: "Authentication", package: "Auth")]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
        .testTarget(name: "NefEditorCryptoTests", dependencies: ["NefEditorCrypto", "SwiftCheck"])
    ]
)
