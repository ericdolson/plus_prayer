// swift-tools-version: 6.2
// PlusPrayerDomain: models and product rules as pure Swift (Foundation only).
// No SwiftUI, Firebase or connector imports — the compiler enforces it.
// Run the tests in seconds without a simulator:
//   swift test --package-path apps/ios/Packages/PlusPrayerDomain

import PackageDescription

let package = Package(
    name: "PlusPrayerDomain",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "PlusPrayerDomain", targets: ["PlusPrayerDomain"]),
    ],
    targets: [
        .target(name: "PlusPrayerDomain"),
        .testTarget(name: "PlusPrayerDomainTests", dependencies: ["PlusPrayerDomain"]),
    ]
)
