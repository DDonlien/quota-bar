// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "CodingPlanMenu",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "CodingPlanMenu", targets: ["CodingPlanMenu"])
    ],
    dependencies: [
        .package(url: "https://github.com/steipete/SweetCookieKit.git", from: "0.4.0")
    ],
    targets: [
        .executableTarget(
            name: "CodingPlanMenu",
            dependencies: [
                .product(name: "SweetCookieKit", package: "SweetCookieKit")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
