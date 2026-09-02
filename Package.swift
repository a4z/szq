// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
import Foundation

#if os(Linux)
  let zmqDependency: Target.Dependency = .target(name: "ZeroMQ")
  let zmqTargets: [Target] = [
    .systemLibrary(
      name: "ZeroMQ",
      pkgConfig: "libzmq",
      providers: [
        .apt(["libzmq3-dev", "libsodium-dev"])
      ]
    )
  ]
#elseif os(Windows)
  let vcpkgRoots = [
    Context.environment["VCPKG_ROOT"],
    Context.environment["VCPKG_INSTALLATION_ROOT"],
    Context.environment["USERPROFILE"].map { "\($0)/vcpkg" },
    Context.environment["HOME"].map { "\($0)/vcpkg" },
    "C:/vcpkg",
  ].compactMap { $0 }
  let vcpkgTriplets = [
    Context.environment["VCPKG_DEFAULT_TRIPLET"],
    "x64-windows-static-md",
    "x64-windows",
  ].compactMap { $0 }
  let vcpkgPkgConfigs = vcpkgRoots.flatMap { root in
    vcpkgTriplets.map { triplet in
      "\(root)/installed/\(triplet)/lib/pkgconfig/libzmq.pc"
    }
  }
  let zmqPkgConfig =
    vcpkgPkgConfigs
      .first { FileManager.default.fileExists(atPath: $0) }
      ?? "libzmq"

  let zmqDependency: Target.Dependency = .target(name: "ZeroMQ")
  let zmqTargets: [Target] = [
    .systemLibrary(
      name: "ZeroMQ",
      pkgConfig: zmqPkgConfig
    )
  ]
#else
  let zmqDependency: Target.Dependency = .target(name: "zmq")
  let zmqTargets: [Target] = [
    .binaryTarget(
      name: "zmq",
      url:
        "https://github.com/a4z/libzmq-xcf/releases/download/v4.3.5-250103_1/libzmq.xcframework.zip",
      checksum: "34bf6c91c7151bfd9e0bea70fdea3b375246520677e0b6aa9b36184315aa0ec9"
    )
  ]
#endif

let package = Package(
  name: "szq",
  // other/older might be possible, but not tested
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .watchOS(.v10),
    .tvOS(.v16),
  ],
  products: [
    .library(
      name: "szq",
      targets: ["szq"])
  ],
  targets: zmqTargets + [
    .target(
      name: "szq",
      dependencies: [zmqDependency],
      cxxSettings: [],
      linkerSettings: [
        .linkedLibrary("c++", .when(platforms: [.macOS, .iOS, .watchOS, .tvOS])),
        .linkedLibrary("stdc++", .when(platforms: [.linux])),
      ]
    ),
    .testTarget(
      name: "szqTests",
      dependencies: ["szq"]
    ),
  ]
)
