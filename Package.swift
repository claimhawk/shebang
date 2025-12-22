// swift-tools-version: 5.9
// Shebang IDE - Automated Development Environment

import PackageDescription

let package = Package(
    name: "ShebangApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Shebang", targets: ["ShebangApp"])
    ],
    dependencies: [
        // Terminal emulation - MIT licensed, battle-tested
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.0.0"),
        // File tree navigation - Apache-2.0 licensed
        .package(url: "https://github.com/mchakravarty/ProjectNavigator", from: "1.7.0")
    ],
    targets: [
        .executableTarget(
            name: "ShebangApp",
            dependencies: [
                "SwiftTerm",
                .product(name: "Files", package: "ProjectNavigator"),
                .product(name: "ProjectNavigator", package: "ProjectNavigator")
            ],
            path: "Sources/ShebangApp",
            resources: [
                .copy("Resources/shebang.zip")
            ]
        ),
        .testTarget(
            name: "ShebangAppTests",
            dependencies: ["ShebangApp"],
            path: "Tests/ShebangAppTests"
        )
    ]
)
