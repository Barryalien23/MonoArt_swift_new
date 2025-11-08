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
                .target(name: "AsciiSupport")
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
