// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PegexBuilder",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "PegexBuilder", targets: ["PegexBuilder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.14.1"),
    ],
    targets: [
        .target(
            name: "PegexBuilder",
            dependencies: [
                .product(name: "Parsing", package: "swift-parsing"),
            ],
            path: "Sources",
            swiftSettings: []
        ),
        .testTarget(
            name: "PegexBuilderTests",
            dependencies: ["PegexBuilder"],
            path: "Tests"
        ),
    ]
)
