// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "QuotaBar",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "QuotaBar", targets: ["QuotaBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/steipete/SweetCookieKit.git", from: "0.4.0")
    ],
    targets: [
        .executableTarget(
            name: "QuotaBar",
            dependencies: [
                .product(name: "SweetCookieKit", package: "SweetCookieKit")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
