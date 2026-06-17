// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "CodingPlanMenu",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "CodingPlanMenu", targets: ["CodingPlanMenu"])
    ],
    targets: [
        .executableTarget(
            name: "CodingPlanMenu",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
