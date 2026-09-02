# szq: Swift ZeroMQ Bindings - An Opinionated Approach

**szq** is an opinionated Swift library for using [ZeroMQ](https://zeromq.org), also known as ZMQ.
It draws inspiration from its [C++ equivalent, zq](https://github.com/a4z/zq), adhering to a shared philosophy:
Provide essential functionality that covers most use cases while remaining flexible and extendable for project-specific needs.

Please note: **szq requires Swift 6**

---

## About

While several ZeroMQ Swift bindings already exist, none met my expectations.

Most bindings aim to wrap the entire ZMQ interface, which I find unnecessary for many applications.
In real-world projects, developers often know which patterns and ZMQ features they need to use.

**szq** takes a different approach:

- It demonstrates how to "fish" 🐠 instead of handing you pre-caught fishes 😉.
- It provides a streamlined interface for most, if not all, common use cases.
- When advanced functionality is needed, it doesn’t stand in your way.

The result is a library that simplifies usage without sacrificing flexibility.

---

## Consuming ZeroMQ

**szq** depends on ZeroMQ.

For convenience, it uses the ZeroMQ XCFramework available at [libzmq-xcf](https://github.com/a4z/libzmq-xcf).

---

## Platform Support

- **Apple Platforms**: Fully supported.
- **Linux**: Tested on Ubuntu 24.04, see CI for details
- **Windows**: Supported with ZeroMQ from vcpkg.

Recommended Windows setup:

```powershell
# Optional if vcpkg is not installed in $HOME\vcpkg or C:\vcpkg:
$env:VCPKG_ROOT = "C:\path\to\vcpkg"
$env:VCPKG_DEFAULT_TRIPLET = "x64-windows-static-md"
vcpkg install "zeromq:$env:VCPKG_DEFAULT_TRIPLET"
swift test
```

The package checks `VCPKG_ROOT`, `VCPKG_INSTALLATION_ROOT`, `$HOME\vcpkg`,
`%USERPROFILE%\vcpkg`, and `C:\vcpkg`.
Plain `vcpkg install zeromq` uses the dynamic `x64-windows` triplet; that
builds, but executables also need the vcpkg `bin` directory on `PATH` at
runtime.
