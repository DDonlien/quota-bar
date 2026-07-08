// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "QuotaBar",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "QuotaBar", targets: ["QuotaBar"])
    ],
    targets: [
        .executableTarget(
            name: "QuotaBar",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "QuotaBarTests",
            dependencies: ["QuotaBar"],
            path: "Tests/QuotaBarTests"
        )
    ]
)
