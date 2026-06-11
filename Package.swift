// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Fretboard",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "Fretboard",
            targets: ["Fretboard"]),
    ],
    dependencies: [
        .package(url: "https://www.github.com/cemolcay/MusicTheory", from: .init(2, 0, 0)),
    ],
    targets: [
        .target(
            name: "Fretboard",
            dependencies: ["MusicTheory"],
            path: "Sources"),
        .testTarget(
            name: "FretboardTests",
            dependencies: ["Fretboard"],
            path: "Tests/FretboardTests"),
    ]
)
