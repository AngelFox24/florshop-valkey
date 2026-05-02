// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "florshop-valkey",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FlorShopValkey",
            targets: ["FlorShopValkey"]
        ),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🔵 Valkey Swift
        .package(url: "https://github.com/valkey-io/valkey-swift", from: "1.3.2"),
        // 🔵 Valkey Vapor
        .package(url: "https://github.com/vapor-community/valkey.git", from: "1.2.0"),
        // 🔵 Shared DTOs
//        .package(url: "https://github.com/AngelFox24/florshop-dtos.git", exact: "1.0.27")
//            .package(path: "../florshop-dtos")
            .package(url: "https://github.com/AngelFox24/florshop-dtos.git", branch: "feature/add-valkey")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FlorShopValkey",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Valkey", package: "valkey-swift"),
                .product(name: "VaporValkey", package: "valkey"),
                .product(name: "FlorShopDTOs", package: "florshop-dtos"),
            ]
        ),
        .testTarget(
            name: "FlorShopValkeyTests",
            dependencies: ["FlorShopValkey"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
