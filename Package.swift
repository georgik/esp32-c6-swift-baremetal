// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ESP32Blink",
    platforms: [.macOS(.v11)],
    products: [
        .executable(name: "MainApp", targets: ["MainApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-mmio.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "MainApp",
            dependencies: ["Registers"]
        ),
        .target(
            name: "Registers",
            dependencies: [
                .product(name: "MMIO", package: "swift-mmio")
            ],
            path: "Sources/Registers"
        ),
    ]
)

