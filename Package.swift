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
        .library(name: "NotchiWallpaper", targets: ["NotchiWallpaper"]),
        .library(name: "NotchiIcons", targets: ["NotchiIcons"]),
    ],
    targets: [
        .target(name: "NotchiCore", path: "Packages/NotchiCore/Sources/NotchiCore"),
        .target(name: "NotchiNotch", dependencies: ["NotchiCore"], path: "Packages/NotchiNotch/Sources/NotchiNotch"),
        .target(name: "NotchiWallpaper", dependencies: ["NotchiCore"], path: "Packages/NotchiWallpaper/Sources/NotchiWallpaper"),
        .target(name: "NotchiIcons", dependencies: ["NotchiCore"], path: "Packages/NotchiIcons/Sources/NotchiIcons"),
        .executableTarget(name: "NotchiApp", dependencies: ["NotchiCore", "NotchiNotch", "NotchiWallpaper", "NotchiIcons"], path: "App/Sources/NotchiApp"),
        .executableTarget(name: "notchi", dependencies: ["NotchiCore", "NotchiIcons"], path: "CLI/notchi/Sources"),
        .testTarget(name: "NotchiCoreTests", dependencies: ["NotchiCore"], path: "Tests/NotchiCoreTests"),
        .testTarget(name: "NotchiIconsTests", dependencies: ["NotchiIcons"], path: "Tests/NotchiIconsTests"),
    ]
)
