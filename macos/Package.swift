// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Transkrito",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "Transkrito",
            path: "Sources/Transkrito",
            resources: [.copy("Resources/common-words.txt")],
            swiftSettings: [.swiftLanguageMode(.v5)],
            linkerSettings: [
                .linkedFramework("Speech"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .testTarget(
            name: "TranskritoTests",
            dependencies: ["Transkrito"],
            path: "Tests/TranskritoTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
