# szq API Reference

This document provides a comprehensive reference for all the classes, methods, and properties in the szq library.

## Table of Contents

- [Context](#context)
- [Socket](#socket)
- [Message](#message)
- [TypedMessage](#typedmessage)
- [Proxy](#proxy)
- [Z85](#z85)
- [Enumerations](#enumerations)
- [Errors](#errors)

## Context

`Context` is the container for ZeroMQ sockets. You typically create one context per application.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `context` | `UnsafeMutableRawPointer?` | The raw ZeroMQ context pointer. |

### Methods

#### Initialization and Management

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `init()` | None | `Context` | Creates a new ZeroMQ context. |
| `close()` | None | `Void` | Terminates the context. |
| `isClosed()` | None | `Bool` | Checks if the context is closed. |
| `maxSockets()` | None | `Int32` | Gets the maximum number of sockets. |
| `ioThreads()` | None | `Int32` | Gets the number of I/O threads. |

#### Socket Creation

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `bind(type:url:)` | `type: SocketType, url: String` | `Socket` | Creates a socket and binds it to an address. |
| `connect(type:url:)` | `type: SocketType, url: String` | `Socket` | Creates a socket and connects it to an endpoint. |

#### Proxy Functions

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `proxy(frontend:backend:capture:)` | `frontend: Socket, backend: Socket, capture: Socket? = nil` | `Void` | Creates a proxy between frontend and backend sockets. |
| `proxyWithControl(frontend:backend:capture:)` | `frontend: Socket, backend: Socket, capture: Socket? = nil` | `Socket` | Creates a steerable proxy with a control socket. |

## Socket

`Socket` represents a ZeroMQ socket that can send and receive messages.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `socket` | `UnsafeMutableRawPointer` | The raw ZeroMQ socket pointer. |

### Methods

#### Initialization

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `init(socket:)` | `socket: UnsafeMutableRawPointer` | `Socket` | Creates a Socket instance from a raw ZeroMQ socket. |

#### Sending and Receiving

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `send(_:dontwait:)` | `messages: Message..., dontwait: Bool = true` | `Int` | Sends one or more messages. |
| `recv()` | None | `Message?` | Receives a single message. |
| `recvAll()` | None | `[Message]?` | Receives all parts of a multipart message. |
| `awaitMessage(timeout:)` | `timeout: Int` | `Bool` | Waits for a message for the specified timeout. |

#### Socket Options

##### Linger

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `linger(milliseconds:)` | `milliseconds: Int32` | `Void` | Sets the linger period for socket close. |
| `linger()` | None | `Int32` | Gets the current linger period. |

##### Subscription (SUB sockets)

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `subscribe(prefix:)` | `prefix: String` | `Void` | Subscribes to messages that match the prefix. |
| `subscribe(data:size:)` | `data: UnsafeRawPointer, size: Int` | `Void` | Subscribes using raw binary data. |
| `unsubscribe(prefix:)` | `prefix: String` | `Void` | Unsubscribes from messages with the prefix. |
| `unsubscribe(data:size:)` | `data: UnsafeRawPointer, size: Int` | `Void` | Unsubscribes using raw binary data. |

##### Identity (ROUTER/DEALER sockets)

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setIdentity(_:)` | `identity: String` | `Void` | Sets the socket identity as a string. |
| `setIdentity(_:size:)` | `data: UnsafeRawPointer, size: Int` | `Void` | Sets the identity using raw data. |
| `setIdentity(_:size:)` | `bytes: [UInt8], size: Int` | `Void` | Sets the identity using a byte array. |
| `getIdentity()` | None | `Message` | Gets the current identity as a Message. |

##### High Water Mark Options

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setSendHighWaterMark(_:)` | `value: Int32` | `Void` | Sets the send high water mark. |
| `getSendHighWaterMark()` | None | `Int32` | Gets the send high water mark. |
| `setReceiveHighWaterMark(_:)` | `value: Int32` | `Void` | Sets the receive high water mark. |
| `getReceiveHighWaterMark()` | None | `Int32` | Gets the receive high water mark. |

##### Timeout Options

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setSendTimeout(milliseconds:)` | `milliseconds: Int32` | `Void` | Sets the send timeout. |
| `getSendTimeout()` | None | `Int32` | Gets the send timeout. |
| `setReceiveTimeout(milliseconds:)` | `milliseconds: Int32` | `Void` | Sets the receive timeout. |
| `getReceiveTimeout()` | None | `Int32` | Gets the receive timeout. |

##### Reconnection Options

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setReconnectInterval(milliseconds:)` | `milliseconds: Int32` | `Void` | Sets the reconnection interval. |
| `getReconnectInterval()` | None | `Int32` | Gets the reconnection interval. |
| `setMaxReconnectInterval(milliseconds:)` | `milliseconds: Int32` | `Void` | Sets the maximum reconnection interval. |
| `getMaxReconnectInterval()` | None | `Int32` | Gets the maximum reconnection interval. |

##### TCP Options

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setTCPKeepAlive(_:)` | `value: Int32` | `Void` | Sets the TCP keep-alive option. |
| `getTCPKeepAlive()` | None | `Int32` | Gets the TCP keep-alive option. |

##### Message Size Option

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setMaxMessageSize(_:)` | `maxSize: Int64` | `Void` | Sets the maximum allowed message size. |
| `getMaxMessageSize()` | None | `Int64` | Gets the maximum allowed message size. |

##### Multicast Options

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setMulticastHops(_:)` | `value: Int32` | `Void` | Sets the multicast hop count. |
| `getMulticastHops()` | None | `Int32` | Gets the multicast hop count. |
| `setMulticastRate(_:)` | `value: Int32` | `Void` | Sets the multicast data rate. |
| `getMulticastRate()` | None | `Int32` | Gets the multicast data rate. |
| `setMulticastRecoveryInterval(milliseconds:)` | `milliseconds: Int32` | `Void` | Sets the multicast recovery interval. |
| `getMulticastRecoveryInterval()` | None | `Int32` | Gets the multicast recovery interval. |

##### Connection Backlog Option

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setBacklog(_:)` | `value: Int32` | `Void` | Sets the connection backlog. |
| `getBacklog()` | None | `Int32` | Gets the connection backlog. |

##### ROUTER/DEALER Socket Options

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setRouterMandatory(_:)` | `value: Int32` | `Void` | Sets whether ROUTER should report errors on unroutable messages. |
| `setRouterRaw(_:)` | `value: Int32` | `Void` | Sets whether ROUTER should use raw IDs. |
| `setRouterHandover(_:)` | `value: Int32` | `Void` | Sets the ROUTER handover behavior. |

##### PUB/SUB Socket Options

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setConflate(_:)` | `value: Int32` | `Void` | Sets whether to keep only the most recent message. |
| `getConflate()` | None | `Int32` | Gets the conflate setting. |

##### SOCKS Proxy Options

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setProxy(_:)` | `proxyAddress: String` | `Void` | Sets the SOCKS proxy address. |
| `getProxy()` | None | `String?` | Gets the SOCKS proxy address. |
| `setSocks5Username(_:)` | `username: String` | `Void` | Sets the SOCKS5 proxy username. |
| `setSocks5Password(_:)` | `password: String` | `Void` | Sets the SOCKS5 proxy password. |

##### IP Version Options

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setIPv6(_:)` | `value: Int32` | `Void` | Sets whether to use IPv6. |
| `getIPv6()` | None | `Int32` | Gets the IPv6 setting. |
| `setIPv4Only(_:)` | `value: Int32` | `Void` | Sets whether to use IPv4 only. |
| `getIPv4Only()` | None | `Int32` | Gets the IPv4-only setting. |

##### Connection Options

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `getLastEndpoint()` | None | `String` | Gets the last endpoint bound or connected. |
| `setHandshakeInterval(milliseconds:)` | `milliseconds: Int32` | `Void` | Sets the handshake interval. |
| `getHandshakeInterval()` | None | `Int32` | Gets the handshake interval. |
| `setImmediate(_:)` | `value: Int32` | `Void` | Sets whether to drop messages when no connection. |
| `getImmediate()` | None | `Int32` | Gets the immediate setting. |

##### Socket Information

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `getType()` | None | `SocketType` | Gets the socket type. |
| `getEvents()` | None | `Int32` | Gets the events waiting on the socket. |

##### Thread Affinity Option

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setAffinity(_:)` | `value: UInt64` | `Void` | Sets the socket's I/O thread affinity. |
| `getAffinity()` | None | `UInt64` | Gets the socket's I/O thread affinity. |

##### CURVE Security Options

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setCurveServer(_:)` | `value: Int32` | `Void` | Sets whether the socket is a CURVE server. |
| `isCurveServer()` | None | `Bool` | Gets whether the socket is a CURVE server. |
| `setCurvePublicKey(_:)` | `key: String` | `Void` | Sets the CURVE public key as a string. |
| `setCurvePublicKeyBinary(_:)` | `key: [UInt8]` | `Void` | Sets the CURVE public key as binary. |
| `getCurvePublicKey()` | None | `String` | Gets the CURVE public key. |
| `setCurveSecretKey(_:)` | `key: String` | `Void` | Sets the CURVE secret key as a string. |
| `setCurveSecretKeyBinary(_:)` | `key: [UInt8]` | `Void` | Sets the CURVE secret key as binary. |
| `getCurveSecretKey()` | None | `String` | Gets the CURVE secret key. |
| `setCurveServerKey(_:)` | `key: String` | `Void` | Sets the server's CURVE public key. |
| `setCurveServerKeyBinary(_:)` | `key: [UInt8]` | `Void` | Sets the server's CURVE public key as binary. |
| `getCurveServerKey()` | None | `String` | Gets the server's CURVE public key. |

## Message

`Message` represents a ZeroMQ message.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `msg` | `zmq_msg_t` | The raw ZeroMQ message struct. |
| `data` | `UnsafeMutableRawPointer?` | The message data. |
| `size` | `Int` | The size of the message in bytes. |
| `string` | `String?` | The message as a string, if valid UTF-8. |

### Methods

#### Initialization

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `init()` | None | `Message` | Creates an empty message. |
| `init(size:)` | `size: Int` | `Message` | Creates a message of the specified size. |
| `init(string:)` | `string: String` | `Message` | Creates a message from a string. |
| `init(bytes:)` | `bytes: [UInt8]` | `Message` | Creates a message from a byte array. |

## TypedMessage

`TypedMessage` is a generic wrapper for `Message` that provides type-safe access to message data.

### Methods

#### Initialization

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `init(_ value: T)` | `value: T` | `TypedMessage<T>` | Creates a typed message from a value. |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `value` | `T` | The typed value contained in the message. |

## Proxy

`Proxy` manages a ZeroMQ proxy device.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `context` | `Context` | The ZeroMQ context. |
| `frontend` | `Socket` | The frontend socket. |
| `backend` | `Socket` | The backend socket. |
| `capture` | `Socket?` | The optional capture socket. |

### Methods

#### Initialization

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `init(context:frontend:backend:capture:)` | `context: Context, frontend: Socket, backend: Socket, capture: Socket? = nil` | `Proxy` | Creates a proxy with the given sockets. |

#### Control

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `start()` | None | `Void` | Starts the proxy in a separate thread. |
| `startSteerable()` | None | `Void` | Starts a steerable proxy. |
| `stop()` | None | `Void` | Stops the proxy. |
| `running()` | None | `Bool` | Checks if the proxy is running. |

## ProxyPattern

`ProxyPattern` is an enumeration of standard proxy patterns.

### Cases

| Case | Description |
|------|-------------|
| `queue` | A queue device (ROUTER-DEALER). |
| `forwarder` | A forwarder device (SUB-PUB). |
| `streamer` | A streamer device (PULL-PUSH). |

### Methods

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `createProxy(context:frontendUrl:backendUrl:)` | `context: Context, frontendUrl: String, backendUrl: String` | `Proxy` | Creates a proxy for this pattern. |

## Z85

`Z85` provides utilities for Z85 encoding and CURVE key management.

### Methods

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `encode(_:)` | `data: [UInt8]` | `String?` | Encodes binary data using Z85. |
| `decode(_:)` | `string: String` | `[UInt8]?` | Decodes a Z85-encoded string. |
| `generateKeyPair()` | None | `(publicKey: String, secretKey: String)?` | Generates a CURVE key pair. |

## Enumerations

### SocketType

Enumeration of ZeroMQ socket types.

| Case | Description |
|------|-------------|
| `req` | Request socket (synchronous request-reply pattern). |
| `rep` | Reply socket (synchronous request-reply pattern). |
| `dealer` | Dealer socket (asynchronous request-reply pattern). |
| `router` | Router socket (asynchronous request-reply pattern). |
| `pub` | Publisher socket (publish-subscribe pattern). |
| `sub` | Subscriber socket (publish-subscribe pattern). |
| `xpub` | Extended publisher socket. |
| `xsub` | Extended subscriber socket. |
| `push` | Push socket (pipeline pattern). |
| `pull` | Pull socket (pipeline pattern). |
| `pair` | Pair socket (exclusive connection pattern). |
| `stream` | Stream socket (raw TCP). |

### RecvResult

Error cases for message reception.

| Case | Description |
|------|-------------|
| `noData` | No message data available. |
| `overflow(data: [Message])` | Too many message parts received. |
| `underflow(data: [Message])` | Too few message parts received. |

## Errors

### ZmqError

Error type for ZeroMQ errors.

| Property | Type | Description |
|----------|------|-------------|
| `code` | `Int32` | The ZeroMQ error code. |
| `description` | `String` | The error description. |

### SzqError

Error type for szq-specific errors.

| Case | Description |
|------|-------------|
| `badType` | Invalid socket type. |
| `invalidContext` | Invalid ZeroMQ context. |
| `invalidIdentitySize` | Invalid size for socket identity. |
| `invalidKeySize` | Invalid size for CURVE key. |