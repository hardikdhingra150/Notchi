// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Notchi",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "NotchiApp", targets: ["NotchiApp"]),
        .executable(name: "notchi", targets: ["notchi"]),
        .library(name: "NotchiCore", targets: ["NotchiCore"]),
        .library(name: "NotchiNotch", targets: ["NotchiNotch"]),
    ],
    targets: [
        .target(name: "NotchiCore", path: "Packages/NotchiCore/Sources/NotchiCore"),
        .target(name: "NotchiNotch", dependencies: ["NotchiCore"], path: "Packages/NotchiNotch/Sources/NotchiNotch"),
        .executableTarget(name: "NotchiApp", dependencies: ["NotchiCore", "NotchiNotch"], path: "App/Sources/NotchiApp"),
        .executableTarget(name: "notchi", dependencies: ["NotchiCore"], path: "CLI/notchi/Sources"),
        .testTarget(name: "NotchiCoreTests", dependencies: ["NotchiCore"], path: "Tests/NotchiCoreTests"),
    ]
)
