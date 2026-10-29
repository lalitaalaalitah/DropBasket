// swift-tools-version: 6.0
// Author: lalitaalaalitah
// Website: https://www.lalitaalaalitah.com
// GitHub Profile: https://github.com/lalitaalaalitah

import PackageDescription

let package = Package(
    name: "DropBasket",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DropBasket", targets: ["DropBasket"])
    ],
    targets: [
        .executableTarget(
            name: "DropBasket",
            path: "Sources/DropBasket"
        ),
        .testTarget(
            name: "DropBasketTests",
            dependencies: ["DropBasket"],
            path: "Tests/DropBasketTests"
        ),
    ]
)
