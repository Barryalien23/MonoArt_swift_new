// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AsciiCameraKit",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "AsciiCameraKit",
            targets: ["AsciiCameraKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pocketsvg/PocketSVG.git", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "AsciiSupport"
        ),
        .target(
            name: "AsciiDomain",
            dependencies: [
                .target(name: "AsciiSupport")
            ]
        ),
        .target(
            name: "AsciiEngine",
            dependencies: [
                .target(name: "AsciiDomain"),
                .target(name: "AsciiSupport")
            ]
        ),
        .target(
            name: "AsciiCamera",
            dependencies: [
                .target(name: "AsciiSupport"),
                .target(name: "AsciiDomain")
            ]
        ),
        .target(
            name: "AsciiUI",
            dependencies: [
                .target(name: "AsciiDomain"),
                .target(name: "AsciiEngine"),
                .target(name: "AsciiCamera"),
                .target(name: "AsciiSupport"),
                .product(name: "PocketSVG", package: "PocketSVG")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "AsciiCameraKit",
            dependencies: [
                .target(name: "AsciiDomain"),
                .target(name: "AsciiEngine"),
                .target(name: "AsciiCamera"),
                .target(name: "AsciiUI"),
                .target(name: "AsciiSupport")
            ]
        ),
        .testTarget(
            name: "AsciiCameraKitTests",
            dependencies: ["AsciiCameraKit"],
            path: ".packageTests/AsciiCameraKitTests",
            resources: []
        )
    ]
)
