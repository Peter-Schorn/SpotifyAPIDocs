// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SpotifyAPIDocs",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "Run", targets: ["Run"]),
        .library(name: "VaporDocC", targets: ["VaporDocC"]),
    ],
    dependencies: [
        .package(name: "vapor", url: "https://github.com/vapor/Vapor.git", from: "4.54.1"),
    ],
    targets: [
        .executableTarget(
            name: "Run",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                "VaporDocC",
            ]
        ),
        .target(
            name: "VaporDocC",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
            ],
            resources: [
                .copy("SpotifyWebAPI.doccarchive")
            ]
        ),
        .testTarget(
            name: "VaporDocCTests",
            dependencies: ["VaporDocC"]
        ),
    ]
)
