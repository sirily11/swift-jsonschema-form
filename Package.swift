// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSONSchemaForm",
    platforms: [
        .macOS(.v15),
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "JSONSchemaForm",
            targets: ["JSONSchemaForm"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/sirily11/swift-json-schema", branch: "main"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "JSONSchemaForm", dependencies: [
                .product(name: "JSONSchema", package: "swift-json-schema"),
                .product(name: "Collections", package: "swift-collections"),
            ]
        ),
        .testTarget(
            name: "JSONSchemaFormTests",
            dependencies: ["JSONSchemaForm"]
        ),
    ]
)
