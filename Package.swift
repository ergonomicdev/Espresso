// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Espresso",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Espresso", targets: ["Espresso"])
    ],
    targets: [
        .target(
            name: "EspressoCore",
            linkerSettings: [.linkedFramework("IOKit")]
        ),
        .executableTarget(
            name: "Espresso",
            dependencies: ["EspressoCore"],
            linkerSettings: [.linkedFramework("ServiceManagement")]
        ),
        .testTarget(
            name: "EspressoCoreTests",
            dependencies: ["EspressoCore"]
        ),
    ]
)
