# szq: Swift ZeroMQ Bindings - An Opinionated Approach

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

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
- When advanced functionality is needed, it doesn't stand in your way.

The result is a library that simplifies usage without sacrificing flexibility.

## defmacro-jam Update 

I've (at least attempted to) fill in everything that was missing.

## Features

- **Complete ZeroMQ Pattern Support**: REQ/REP, DEALER/ROUTER, PUB/SUB, PUSH/PULL, PAIR, and STREAM
- **Type-Safe Message Handling**: Simple and safe message creation and handling
- **Comprehensive Socket Options**: Control all aspects of ZeroMQ behavior
- **Proxy Device Support**: Create intermediary devices for various messaging patterns
- **Security**: CURVE encryption for secure communication
- **Multipart Messages**: First-class support for multipart message handling
- **Thread-Safe**: Safe for concurrent use across threads

## Quick Start

### Simple Request-Reply Example

```swift
import szq

// Create a context
let context = Context()

// Server
let server = try context.bind(type: .rep, url: "tcp://*:5555")

// Client
let client = try context.connect(type: .req, url: "tcp://localhost:5555")

// Client sends a request
try client.send(Message(string: "Hello"))

// Server receives and replies
if let request = try server.recv(), let requestString = request.string {
    print("Server received: \(requestString)")
    try server.send(Message(string: "World"))
}

// Client receives the reply
if let reply = try client.recv(), let replyString = reply.string {
    print("Client received: \(replyString)")
}
```

### Publish-Subscribe Example

```swift
import szq

// Create a context
let context = Context()

// Publisher
let publisher = try context.bind(type: .pub, url: "tcp://*:5555")

// Subscriber
let subscriber = try context.connect(type: .sub, url: "tcp://localhost:5555")
try subscriber.subscribe(prefix: "weather") // Only receive weather updates

// Publisher sends messages
try publisher.send(Message(string: "weather Temperature is 25C"))
try publisher.send(Message(string: "sports Team won the match"))

// Subscriber receives only weather updates
if let update = try subscriber.recv(), let updateString = update.string {
    print("Received update: \(updateString)")
}
```

## Documentation

For comprehensive documentation, visit our [Documentation](Documentation/) directory.

### Guides

- [Basic Patterns](Documentation/basic-patterns.md) - REQ/REP, PUB/SUB, PUSH/PULL, PAIR
- [Socket Types](Documentation/socket-types.md) - Detailed explanation of all socket types
- [Advanced Features](Documentation/advanced-features.md) - Proxies, socket options, identities, CURVE security
- [API Reference](Documentation/api-reference.md) - Complete API documentation

### Examples

The [examples directory](Documentation/examples) contains working examples for all supported patterns:

- Request-Reply
- Publish-Subscribe
- Dealer-Router
- Proxies
- Security
- Socket Options

---

## Consuming ZeroMQ

**szq** depends on ZeroMQ.

For convenience, it uses the ZeroMQ XCFramework available at [libzmq-xcf](https://github.com/a4z/libzmq-xcf).

---

## Platform Support

- **Apple Platforms**: Fully supported.
- **Linux**: Support is in progress and coming soon.
