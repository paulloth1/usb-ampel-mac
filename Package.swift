// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "UsbAmpel",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "UsbAmpel",
            path: "Sources/UsbAmpel",
            linkerSettings: [.linkedFramework("IOKit")]
        )
    ]
)
