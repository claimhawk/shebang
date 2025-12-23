// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ShebangApp",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ShebangApp", targets: ["ShebangApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/claimhawk/SwiftTerm.git", branch: "add-currentDirectory-parameter")
    ],
    targets: [
        .executableTarget(
            name: "ShebangApp",
            dependencies: ["SwiftTerm"]
        )
    ]
)
