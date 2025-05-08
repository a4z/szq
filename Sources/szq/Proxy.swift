import Foundation
import ZeroMQ

/// A class that manages a ZeroMQ proxy (device) running in a separate thread.
///
/// ZeroMQ proxies provide a way to connect different socket types together, creating
/// intermediaries such as queue devices (ROUTER-DEALER), forwarders (SUB-PUB),
/// or streamers (PULL-PUSH).
@available(macOS 10.15, *)
public class Proxy: @unchecked Sendable {
  
  private let context: Context
  private let frontend: Socket
  private let backend: Socket
  private let capture: Socket?
  private var controlSocket: Socket?
  private var proxyThread: Thread?
  private var isRunning = false
  
  /// Creates a new proxy with the given frontend and backend sockets.
  ///
  /// - Parameters:
  ///   - context: The ZeroMQ context to use.
  ///   - frontend: The frontend socket (e.g., ROUTER, SUB, PULL).
  ///   - backend: The backend socket (e.g., DEALER, PUB, PUSH).
  ///   - capture: An optional capture socket for monitoring traffic.
  /// - Note: The sockets should already be bound or connected as needed.
  public init(context: Context, frontend: Socket, backend: Socket, capture: Socket? = nil) {
    self.context = context
    self.frontend = frontend
    self.backend = backend
    self.capture = capture
  }
  
  /// Starts the proxy in a separate thread.
  ///
  /// This method starts the proxy in a separate thread, allowing your main thread
  /// to continue processing. The proxy will run until `stop()` is called or the
  /// context is terminated.
  ///
  /// - Throws: ZmqError if the proxy fails to start.
  public func start() throws {
    guard !isRunning else {
      return
    }
    
    isRunning = true
    
    do {
      // Start the proxy in a separate thread
      proxyThread = Thread {
        do {
          try self.context.proxy(frontend: self.frontend, backend: self.backend, capture: self.capture)
        } catch {
          print("Proxy error: \(error)")
        }
      }
      
      proxyThread?.name = "ZMQ-Proxy"
      proxyThread?.start()
      
      // Create a way to terminate the proxy
      // Set up a control channel
      let backendUrl = "inproc://proxy-control-\(UUID().uuidString)"
      let _ = try context.bind(type: .pair, url: backendUrl)
      controlSocket = try context.connect(type: .pair, url: backendUrl)
      
    } catch {
      isRunning = false
      throw error
    }
  }
  
  /// Starts the proxy with built-in control socket (ZeroMQ 4.1.0+).
  ///
  /// This method uses the zmq_proxy_steerable function to create a proxy with a
  /// built-in control socket. This allows for more control over the proxy, such
  /// as pausing and resuming message flow.
  ///
  /// - Throws: ZmqError if the proxy fails to start.
  /// - Note: This requires ZeroMQ 4.1.0 or later.
  public func startSteerable() throws {
    guard !isRunning else {
      return
    }
    
    isRunning = true
    
    do {
      controlSocket = try context.proxyWithControl(frontend: frontend, backend: backend, capture: capture)
    } catch {
      isRunning = false
      throw error
    }
  }
  
  /// Stops the proxy.
  ///
  /// This method terminates the proxy thread.
  ///
  /// - Throws: ZmqError if there's an error stopping the proxy.
  public func stop() throws {
    guard isRunning else {
      return
    }
    
    // Terminate the proxy thread
    proxyThread?.cancel()
    
    isRunning = false
  }
  
  /// Returns the current running state of the proxy.
  ///
  /// - Returns: true if the proxy is running, false otherwise.
  public func running() -> Bool {
    return isRunning
  }
  
  deinit {
    if isRunning {
      try? stop()
    }
  }
}

/// Common proxy patterns in ZeroMQ.
@available(macOS 10.15, *)
public enum ProxyPattern {
  /// Queue device (ROUTER to DEALER)
  case queue
  /// Forwarder device (SUB to PUB)
  case forwarder
  /// Streamer device (PULL to PUSH)
  case streamer
  
  /// Creates a proxy with the appropriate socket types for this pattern.
  ///
  /// - Parameters:
  ///   - context: The ZeroMQ context to use.
  ///   - frontendUrl: The URL for the frontend socket to bind to.
  ///   - backendUrl: The URL for the backend socket to bind to.
  /// - Returns: A configured Proxy object.
  /// - Throws: ZmqError if there's an error creating the sockets.
  public func createProxy(context: Context, frontendUrl: String, backendUrl: String) throws -> Proxy {
    switch self {
    case .queue:
      let frontend = try context.bind(type: .router, url: frontendUrl)
      let backend = try context.bind(type: .dealer, url: backendUrl)
      return Proxy(context: context, frontend: frontend, backend: backend)
      
    case .forwarder:
      let frontend = try context.bind(type: .sub, url: frontendUrl)
      let backend = try context.bind(type: .pub, url: backendUrl)
      // Subscribe to all messages
      try frontend.subscribe(prefix: "")
      return Proxy(context: context, frontend: frontend, backend: backend)
      
    case .streamer:
      let frontend = try context.bind(type: .pull, url: frontendUrl)
      let backend = try context.bind(type: .push, url: backendUrl)
      return Proxy(context: context, frontend: frontend, backend: backend)
    }
  }
}