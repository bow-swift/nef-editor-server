// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "nef-editor-server",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "NefEditorData", targets: ["NefEditorData"]),
        .library(name: "NefEditorUtils", targets: ["NefEditorUtils"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .exact("4.3.1")),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0-rc.1.4"),
        .package(name: "SwiftJWT", url: "https://github.com/IBM-Swift/Swift-JWT.git", .exact("3.6.1")),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .exact("0.9.11")),
        .package(url: "https://github.com/bow-swift/nef.git", .revision("194a2fde700c85981b8494110d784cbddf678e87")),
        .package(path: "./Sources/Clients/AppleSignIn"),
    ],
    targets: [
        .target(name: "NefEditorData"),
        .target(name: "NefEditorUtils", dependencies: [
            .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            .product(name: "nef", package: "nef"),
        ]),
        .target(name: "App", dependencies: [
            .target(name: "NefEditorData"),
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
