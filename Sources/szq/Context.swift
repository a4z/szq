// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ZeroMQ

public class Context: @unchecked Sendable {
  var context: UnsafeMutableRawPointer?

  public init() {
    context = zmq_ctx_new()

  }

  deinit {
    // print("deinit context")
    if context != nil {
      close()
    }
  }

  public func close() {
    zmq_ctx_term(context)
    context = nil
  }

  public func isClosed() -> Bool {
    return context == nil
  }

  public func maxSockets() -> Int32 {
    return zmq_ctx_get(context, ZMQ_MAX_SOCKETS)
  }

  public func ioThreads() -> Int32 {
    return zmq_ctx_get(context, ZMQ_IO_THREADS)
  }

  public func bind(type: SocketType, url: String) throws -> Socket {
    if context == nil {
      throw SzqError.invalidContext
    }

    let socket = zmq_socket(context, type.zmqValue)
    if socket == nil {
      throw currentZmqError()
    }
    let rc = zmq_bind(socket, url)
    if rc != 0 {
      throw currentZmqError()
    }
    var linger: Int32 = 0
    let rcLinger = zmq_setsockopt(socket, ZMQ_LINGER, &linger, MemoryLayout.size(ofValue: linger))
    if rcLinger != 0 {
      throw currentZmqError()
    }
    return Socket(socket: socket!)
  }

  public func connect(type: SocketType, url: String) throws -> Socket {
    if context == nil {
      throw SzqError.invalidContext
    }
    let socket = zmq_socket(context, type.zmqValue)
    if socket == nil {
      throw currentZmqError()
    }
    let rc = zmq_connect(socket, url)
    if rc != 0 {
      throw currentZmqError()
    }

    var linger: Int32 = 0
    let rcLinger = zmq_setsockopt(socket, ZMQ_LINGER, &linger, MemoryLayout.size(ofValue: linger))
    if rcLinger != 0 {
      throw currentZmqError()
    }

    return Socket(socket: socket!)
  }

}
