// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "esp32-c6-blink",
  platforms: [.macOS(.v10_15)], // Only needed for macro tools, not the embedded target
  products: [
    .executable(name: "Application", targets: ["Application"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-mmio.git", branch: "main")
  ],
  targets: [
    .target(
      name: "Registers",
      dependencies: [
        .product(name: "MMIO", package: "swift-mmio")
      ],
      path: "Sources/Registers"
    ),
    .target(
      name: "Support",
      dependencies: [],
      path: "Sources/Support",
      publicHeadersPath: "include"
    ),
    .executableTarget(
      name: "Application",
      dependencies: [
        .product(name: "MMIO", package: "swift-mmio"),
        "Registers",
        "Support",
      ],
      swiftSettings: [
        .enableExperimentalFeature("Embedded")
      ]
    ),
  ]
)