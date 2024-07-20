// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BeMyHandsKit",
    platforms: [.macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Access",
            targets: ["Access"]
        ),
        .library( // NOTE: we may not want to surface Input Output and Element in the future
            name: "Input",
            targets: ["Input"]
        ),
        .library(
            name: "Output",
            targets: ["Output"]
        ),
        .library(
            name: "Element",
            targets: ["Element"]
        ),
        .library(
            name: "HandsBot",
            targets: ["HandsBot"]
        )
    ],
    targets: [
        .target(
            name: "HandsBot",
            dependencies: [
                .byName(name: "Access"),
                .byName(name: "Element")
            ]
        ),

        // CREDIT: João Santos, https://github.com/Xce-PT/Vosh/
        .target(
            name: "Access",
            dependencies: [
                .byName(name: "Input"),
                .byName(name: "Output"),
                .byName(name: "Element")
            ]
        ),
        .target(
            name: "Input",
            dependencies: [.byName(name: "Output")]
        ),
        .target(name: "Output"),
        .target(name: "Element")
    ]
)
