// swift-tools-version: 6.0

import PackageDescription

private let settings: [SwiftSetting] = [
    .unsafeFlags(["-warnings-as-errors"]),
    .enableExperimentalFeature("ExistentialAny")
]

let package = Package(
    name: "Accounts",
    platforms: [
        .macOS(.v10_15), .iOS(.v15)
    ],
    products: [
        .library(
            name: "Accounts",
            targets: ["Accounts"]),
        .library(
            name: "AccountsMock",
            targets: ["AccountsMock"])
    ],
    dependencies: [
        .package(path: "../../../Domain/MEGADomain"),
        .package(path: "../../../Localization/MEGAL10n"),
        .package(path: "../../MEGAPresentation"),
        .package(path: "../../../UI/MEGASwiftUI"),
        .package(path: "../../Repository/MEGASDKRepo"),
        .package(path: "../../../Infrastracture/MEGATest"),
        .package(path: "../../../MEGAAssets"),
        .package(path: "../MEGAUI"),
        .package(path: "../Settings"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "11.10.0")
    ],
    targets: [
        .target(
            name: "Accounts",
            dependencies: ["MEGADomain",
                           "MEGAL10n",
                           "MEGAPresentation",
                           "MEGASwiftUI",
                           "MEGAAssets",
                           "MEGAUI",
                           "Settings"],
            swiftSettings: settings
        ),
        .target(
            name: "AccountsMock",
            dependencies: ["Accounts"],
            swiftSettings: settings
        ),
        .testTarget(
            name: "AccountsTests",
            dependencies: ["Accounts",
                           "AccountsMock",
                           "MEGADomain",
                           "MEGAPresentation",
                           "MEGATest",
                           .product(name: "MEGAPresentationMock", package: "MEGAPresentation"),
                           .product(name: "MEGADomainMock", package: "MEGADomain"),
                           .product(name: "MEGASDKRepoMock", package: "MEGASDKRepo"),
                           .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")],
            swiftSettings: settings
        )
    ],
    swiftLanguageModes: [.v6]
)
