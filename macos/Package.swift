// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Transkrito",
    platforms: [.macOS("26.0")],
    dependencies: [
        // sherpa-onnx: Whisper-tiny spoken-language ID for Auto mode and the Nemotron fallback when Apple has no
        // Arabic speech asset. Official SwiftPM package with prebuilt macOS xcframeworks.
        .package(url: "https://github.com/k2-fsa/sherpa-onnx", exact: "1.13.8"),
    ],
    targets: [
        .executableTarget(
            name: "Transkrito",
            path: "Sources/Transkrito",
            dependencies: [.product(name: "sherpa-onnx", package: "sherpa-onnx")],
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
