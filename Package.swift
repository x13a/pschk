// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pschk",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/x13a/codesign-swift", from: "0.1.0"),
        .package(url: "https://github.com/x13a/libproc-swift", from: "0.1.0"),
        .package(url: "https://github.com/x13a/syscall-swift", from: "0.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "pschk",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CodeSign", package: "codesign-swift"),
                .product(name: "Proc", package: "libproc-swift"),
                .product(name: "ProcUtils", package: "libproc-swift"),
                .product(name: "SysCall", package: "syscall-swift"),
            ]),
        .testTarget(
            name: "pschkTests",
            dependencies: ["pschk"]),
    ]
)
