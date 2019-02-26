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
        ],
    targets: [
        .target(name: "Dependencies", dependencies: , path: "." )
    ]
)
