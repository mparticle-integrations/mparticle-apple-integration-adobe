// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "mParticle-Adobe",
    platforms: [.iOS(.v10)],
    products: [
        .library(name: "mParticle-Adobe", targets: ["mParticle-Adobe"]),
        .library(name: "mParticle-Adobe-Media", targets: ["mParticle-Adobe-Media"])
    ],
    dependencies: [
        .package(
            name: "mParticle-Apple-SDK",
            url: "https://github.com/mParticle/mparticle-apple-sdk",
            .upToNextMajor(from: "8.0.0")),
        .package(
            name: "mParticle-Apple-Media-SDK",
            url: "https://github.com/mParticle/mparticle-apple-media-sdk",
            .upToNextMajor(from: "1.3.0")),
        .package(
            name: "AEPCore",
            url: "https://github.com/adobe/aepsdk-core-ios.git",
            .upToNextMajor(from: "3.2.0")),
        .package(name: "AEPUserProfile",
            url: "https://github.com/adobe/aepsdk-userprofile-ios.git",
            .upToNextMajor(from: "3.0.0")),
        .package(name: "AEPAnalytics",
            url: "https://github.com/adobe/aepsdk-analytics-ios.git",
            .upToNextMajor(from: "3.0.0")),
        .package(name: "AEPMedia",
            url: "https://github.com/adobe/aepsdk-media-ios.git",
            .upToNextMajor(from: "3.0.0"))

    ],
    targets: [
        .target(
            name: "mParticle-Adobe",
            dependencies: ["mParticle-Apple-SDK"],
            path: "mParticle-Adobe",
            publicHeadersPath: "."),
        .target(
            name: "mParticle-Adobe-Media",
            dependencies: [
                .byName(name: "mParticle-Apple-SDK"),
                .byName(name: "mParticle-Apple-Media-SDK"),
                .product(name: "AEPUserProfile", package: "AEPUserProfile"),
                .product(name: "AEPMedia", package: "AEPMedia"),
                .product(name: "AEPAnalytics", package: "AEPAnalytics"),
                .product(name: "AEPCore", package: "AEPCore"),
                .product(name: "AEPIdentity", package: "AEPCore"),
                .product(name: "AEPLifecycle", package: "AEPCore"),
                .product(name: "AEPSignal", package: "AEPCore"),
            ],
            path: "mParticle-Adobe-Media",
            exclude: ["Dummy.swift"],
            publicHeadersPath: "."),
    ]
)
