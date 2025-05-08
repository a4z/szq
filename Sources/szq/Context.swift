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

    if 0 != zmq_bind(socket, url) {
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
    if 0 != zmq_connect(socket, url) {
      throw currentZmqError()
    }

    var linger: Int32 = 0
    let rcLinger = zmq_setsockopt(socket, ZMQ_LINGER, &linger, MemoryLayout.size(ofValue: linger))
    if rcLinger != 0 {
      throw currentZmqError()
    }

    return Socket(socket: socket!)
  }
  
  /// Creates a proxy (device) that connects a frontend socket to a backend socket, and optionally a capture socket.
  /// 
  /// A ZeroMQ proxy connects a frontend socket to a backend socket, passing messages bidirectionally between
  /// them. It can also optionally connect to a capture socket to monitor traffic. This is useful for several patterns:
  /// 
  /// - Queue device (ROUTER to DEALER)
  /// - Forwarder device (SUB to PUB)
  /// - Streamer device (PULL to PUSH)
  /// 
  /// The proxy function will run in the current thread and block until the thread is terminated or the context
  /// is shut down.
  ///
  /// - Parameters:
  ///   - frontend: The frontend socket (ROUTER/SUB/PULL)
  ///   - backend: The backend socket (DEALER/PUB/PUSH)
  ///   - capture: Optional capture socket to monitor traffic
  /// - Throws: ZmqError if the proxy operation fails
  /// 
  /// - Note: This is a blocking call that will run until the thread is terminated or context is shut down.
  ///   In most cases, you'll want to run this in a separate thread.
  public func proxy(frontend: Socket, backend: Socket, capture: Socket? = nil) throws {
    if context == nil {
      throw SzqError.invalidContext
    }
    
    let captureSocket = capture?.socket
    let zrc = zmq_proxy(frontend.socket, backend.socket, captureSocket)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Creates a proxy in a separate thread, returning a control socket that can be used to terminate the proxy.
  ///
  /// This method creates a proxy device connecting a frontend socket to a backend socket, optionally with
  /// a capture socket, and runs it in a separate thread. It returns a control socket that can be used to
  /// send commands to the proxy thread (such as termination).
  ///
  /// - Parameters:
  ///   - frontend: The frontend socket (ROUTER/SUB/PULL)
  ///   - backend: The backend socket (DEALER/PUB/PUSH)
  ///   - capture: Optional capture socket to monitor traffic
  /// - Returns: A control socket that can be used to terminate the proxy
  /// - Throws: ZmqError if the proxy operation fails
  ///
  /// - Note: Send any message to the control socket to terminate the proxy
  public func proxyWithControl(frontend: Socket, backend: Socket, capture: Socket? = nil) throws -> Socket {
    if context == nil {
      throw SzqError.invalidContext
    }
    
    let controlSocket = zmq_socket(context, ZMQ_PAIR)
    if controlSocket == nil {
      throw currentZmqError()
    }
    
    let captureSocket = capture?.socket
    let zrc = zmq_proxy_steerable(frontend.socket, backend.socket, captureSocket, controlSocket)
    if zrc == -1 {
      throw currentZmqError()
    }
    
    return Socket(socket: controlSocket!)
  }

}
