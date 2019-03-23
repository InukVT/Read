// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Dependencies",
    products: [
        .library(name: "Dependencies", type: .dynamic, targets: ["Dependencies"]),
        ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // MARK: - unzipper
        .package(url: "https://github.com/weichsel/ZIPFoundation/", .upToNextMajor(from: "0.9.0")),
        .package(url: "https://github.com/ShawnMoore/XMLParsing.git", from: "0.0.3")
        ],
    targets: [
        .target(name: "Dependencies", dependencies: ["ZIPFoundation", "XMLParsing"], path: "." )
    ]
)
