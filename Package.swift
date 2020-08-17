// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "nef-editor-server",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v10)
    ],
    products: [
        .library(name: "NefEditorData", targets: ["NefEditorData"]),
        .library(name: "NefEditorError", targets: ["NefEditorError"]),
        .library(name: "NefEditorUtils", targets: ["NefEditorUtils"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .exact("4.26.0")),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0-rc.1.4"),
        .package(name: "SwiftJWT", url: "https://github.com/IBM-Swift/Swift-JWT.git", .exact("3.6.1")),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .exact("0.9.11")),
        .package(url: "https://github.com/bow-swift/nef.git", .branch("master")),
        .package(name: "Bow", url: "https://github.com/bow-swift/bow.git", .branch("master")),
        .package(path: "./Sources/Clients/AppleSignIn"),
    ],
    targets: [
        .target(name: "NefEditorData"),
        .target(name: "NefEditorError"),
        .target(name: "NefEditorUtils", dependencies: [
            .product(name: "Bow", package: "Bow"),
            .product(name: "BowEffects", package: "Bow"),
            .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        ]),
        .target(name: "App", dependencies: [
            .target(name: "NefEditorData"),
            .target(name: "NefEditorError"),
            .target(name: "NefEditorUtils"),
            .product(name: "AppleSignIn", package: "AppleSignIn"),
            .product(name: "Vapor", package: "vapor"),
            .product(name: "JWTKit", package: "jwt-kit"),
            .product(name: "SwiftJWT", package: "SwiftJWT"),
            .product(name: "nef", package: "nef"),
        ]),
        .target(name: "Run", dependencies: ["App"]),

        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ]),
    ]
)
