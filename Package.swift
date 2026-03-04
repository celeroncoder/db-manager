// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DBManager",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "DBManager",
            path: "DBManager",
            exclude: ["Assets.xcassets"]
        )
    ]
)
