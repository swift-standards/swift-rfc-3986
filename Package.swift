// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-3986",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "RFC 3986",
            targets: ["RFC 3986"]
        )
    ],
    dependencies: [
        .package(path: "../swift-standards")
    ],
    targets: [
        .target(
            name: "RFC 3986",
            dependencies: [
                .product(name: "Standards", package: "swift-standards")
            ]
        ),
        .testTarget(
            name: "RFC 3986 Tests",
            dependencies: ["RFC 3986"]
        )
    ]
)

for target in package.targets {
    target.swiftSettings?.append(
        contentsOf: [
            .enableUpcomingFeature("MemberImportVisibility")
        ]
    )
}
