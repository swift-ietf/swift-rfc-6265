// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-6265",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "RFC 6265",
            targets: ["RFC 6265"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-ietf/swift-rfc-3986.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-domain-standard.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RFC 6265",
            dependencies: [
                .product(name: "Domain Standard", package: "swift-domain-standard"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
                .product(name: "RFC 3986 Foundation Integration", package: "swift-rfc-3986"),
            ]
        ),
        .testTarget(
            name: "RFC 6265 Tests",
            dependencies: [
                .target(name: "RFC 6265"),
                .product(name: "Domain Standard", package: "swift-domain-standard"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
