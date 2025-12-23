// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ShebangApp",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ShebangApp", targets: ["ShebangApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "ShebangApp",
            dependencies: ["SwiftTerm"]
        )
    ]
)
