// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "taquilla",
    platforms: [
        .iOS(.v17),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "taquilla",
            targets: ["taquilla"]
        )
    ],
    dependencies: [
        // Aquí puedes agregar dependencias si las necesitas en el futuro
    ],
    targets: [
        .target(
            name: "taquilla",
            dependencies: []
        ),
    ]
)
