# szq Documentation

This documentation provides a comprehensive overview of the szq library, a Swift wrapper for ZeroMQ that offers all the functionality of ZeroMQ with a Swift-friendly API.

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [Core Concepts](#core-concepts)
- [Basic Patterns](#basic-patterns)
- [Socket Types](#socket-types)
- [Advanced Features](#advanced-features)
- [API Reference](#api-reference)
- [Examples](#examples)

## Introduction

szq is a Swift wrapper for ZeroMQ (ØMQ), a high-performance asynchronous messaging library. It provides an elegant Swift API for working with ZeroMQ sockets, making it easy to implement various messaging patterns such as request-reply, publish-subscribe, pipeline, and more.

## Installation

### Swift Package Manager

Add szq to your package dependencies in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/szq.git", from: "1.0.0")
]
```

Then add szq to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["szq"]
    )
]
```

## Core Concepts

ZeroMQ provides socket-based messaging with patterns that go beyond traditional network sockets. The szq library wraps these concepts with Swift-friendly APIs.

### Context

A `Context` represents a ZeroMQ context, which is the container for all sockets in a ZeroMQ application. You typically create one context per application:

```swift
import szq

let context = Context()
```

### Sockets

Sockets are created from a context and can be bound to addresses or connected to endpoints:

```swift
// Create a socket of type REQ
let socket = try context.connect(type: .req, url: "tcp://localhost:5555")

// Or bind a socket to an address
let server = try context.bind(type: .rep, url: "tcp://*:5555")
```

### Messages

Messages in szq are represented by the `Message` class, which wraps ZeroMQ messages:

```swift
// Create a message from a string
let message = try Message(string: "Hello")

// Or from bytes
let data: [UInt8] = [1, 2, 3, 4]
let binaryMessage = try Message(bytes: data)
```

## Basic Patterns

See the [Basic Patterns](./basic-patterns.md) documentation for detailed examples of:

- Request-Reply
- Publish-Subscribe
- Push-Pull (Pipeline)
- Exclusive Pair

## Socket Types

See the [Socket Types](./socket-types.md) documentation for details on each socket type and how to use them:

- REQ/REP
- DEALER/ROUTER
- PUB/SUB/XPUB/XSUB
- PUSH/PULL
- PAIR
- STREAM

## Advanced Features

See the [Advanced Features](./advanced-features.md) documentation for details on:

- Proxy Devices
- Socket Options
- Identity Management
- CURVE Security
- Multipart Messages

## API Reference

See the [API Reference](./api-reference.md) for detailed documentation of all classes and methods.

## Examples

See the [Examples](./examples/) directory for complete, working examples of various patterns and features.