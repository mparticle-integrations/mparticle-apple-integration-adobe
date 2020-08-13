// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "mparticle-apple-integration-adobe",
    platforms: [.iOS(.v9)],
    // platforms: [.iOS("11.0")],
    products: [
        .library(name: "mParticle_Adobe", targets: ["mParticle_Adobe"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            .upToNextMajor(from: "7.0.0")),
    ],
    targets: [
        .target(
            name: "mParticle_Adobe",
            dependencies: [
                "mParticle-Apple-SDK"
            ],
            path: "mParticle-Adobe"
        )
    ]
)
