// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "rpi-5-blink",
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
      ]),
  ])

