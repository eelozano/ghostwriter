// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Ghostwriter",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Ghostwriter", targets: ["Ghostwriter"]),
    ],
    targets: [
        .executableTarget(
            name: "Ghostwriter",
            path: "Sources"
        ),
        .testTarget(
            name: "GhostwriterTests",
            dependencies: ["Ghostwriter"],
            path: "Tests/GhostwriterTests"
        )
    ]
)
