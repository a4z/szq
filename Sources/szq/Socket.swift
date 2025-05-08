import Foundation
import ZeroMQ

// Define constants that might not be available in the imported ZeroMQ library
// These are the standard values from zmq.h
public let ZMQ_SOCKS_USERNAME: Int32 = 99
public let ZMQ_SOCKS_PASSWORD: Int32 = 100

public enum SocketType {
  case req
  case rep
  case dealer
  case router
  case pub
  case sub
  case xpub
  case xsub
  case push
  case pull
  case pair
  case stream

  var zmqValue: Int32 {
    switch self {
    case .req: return ZMQ_REQ
    case .rep: return ZMQ_REP
    case .dealer: return ZMQ_DEALER
    case .router: return ZMQ_ROUTER
    case .pub: return ZMQ_PUB
    case .sub: return ZMQ_SUB
    case .xpub: return ZMQ_XPUB
    case .xsub: return ZMQ_XSUB
    case .push: return ZMQ_PUSH
    case .pull: return ZMQ_PULL
    case .pair: return ZMQ_PAIR
    case .stream: return ZMQ_STREAM
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  init?(zmqValue: Int32) {
    switch zmqValue {
    case ZMQ_REQ: self = .req
    case ZMQ_REP: self = .rep
    case ZMQ_DEALER: self = .dealer
    case ZMQ_ROUTER: self = .router
    case ZMQ_PUB: self = .pub
    case ZMQ_SUB: self = .sub
    case ZMQ_XPUB: self = .xpub
    case ZMQ_XSUB: self = .xsub
    case ZMQ_PUSH: self = .push
    case ZMQ_PULL: self = .pull
    case ZMQ_PAIR: self = .pair
    case ZMQ_STREAM: self = .stream
    default: return nil
    }
  }
}

public enum RecvResult: Error {
  case noData
  case overflow(data: [Message])
  case underflow(data: [Message])
}

public class Socket {

  internal var socket: UnsafeMutableRawPointer

  public init(socket: UnsafeMutableRawPointer) {
    self.socket = socket
  }

  deinit {
    zmq_close(socket)
  }

  public func send(_ messages: Message..., dontwait: Bool = true) throws -> Int {
    let waitFlag = dontwait ? ZMQ_DONTWAIT : 0
    var sent = 0
    for (index, message) in messages.enumerated() {
      let isLast = index == messages.count - 1
      let flags = isLast ? waitFlag : ZMQ_SNDMORE
      let zrc = zmq_send(socket, message.data, message.size, flags)
      if zrc == -1 {
        throw currentZmqError()
      }
      sent += Int(zrc)
    }
    return sent
  }

  public func recv() throws -> Message? {
    let message = Message()
    do {
      let zrc = zmq_msg_recv(&message.msg, socket, ZMQ_DONTWAIT)
      if zrc == -1 {
        if zmq_errno() == EAGAIN {
          throw RecvResult.noData
        }
        throw currentZmqError()
      }
    } catch RecvResult.noData {
      return nil
    } catch {
      throw error
    }
    return message
  }

  public func recvAll() throws -> [Message]? {
    let msg = try recv()
    if msg == nil {
      return nil
    }
    var messages = [Message]()
    messages.append(msg!)

    var more: Int32 = 0
    var moreSize = MemoryLayout<Int32>.size
    let zrc = zmq_getsockopt(socket, ZMQ_RCVMORE, &more, &moreSize)
    if zrc == -1 {
      throw currentZmqError()
    }
    while more == 1 {
      if let msg = try recv() {
        messages.append(msg)
      } else {
        throw RecvResult.noData
      }
      let zrc = zmq_getsockopt(socket, ZMQ_RCVMORE, &more, &moreSize)
      if zrc == -1 {
        throw currentZmqError()
      }
    }
    return messages
  }

  public func awaitMessage(timeout: Int) throws -> Bool {
    var item = zmq_pollitem_t(socket: socket, fd: 0, events: Int16(ZMQ_POLLIN), revents: 0)
    let zrc = zmq_poll(&item, 1, timeout)
    if zrc == -1 {
      throw currentZmqError()
    }
    return item.revents == ZMQ_POLLIN
  }

  public func linger(milliseconds: Int32) throws {
    var milliseconds = milliseconds
    let zrc = zmq_setsockopt(
      socket, ZMQ_LINGER, &milliseconds, MemoryLayout.size(ofValue: milliseconds))
    if zrc == -1 {
      throw currentZmqError()
    }
  }

  public func linger() throws -> Int32 {
    var milliseconds: Int32 = 0
    var size = MemoryLayout.size(ofValue: milliseconds)
    let zrc = zmq_getsockopt(socket, ZMQ_LINGER, &milliseconds, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return milliseconds
  }

  /// Subscribes a SUB socket to messages that match the given prefix.
  /// - Parameter prefix: The message prefix to subscribe to. An empty string subscribes to all messages.
  /// - Throws: ZmqError if the subscription fails or if not called on a SUB socket.
  public func subscribe(prefix: String) throws {
    let zrc = zmq_setsockopt(
      socket, ZMQ_SUBSCRIBE, prefix, prefix.utf8.count)
    if zrc == -1 {
      throw currentZmqError()
    }
  }

  /// Subscribes a SUB socket to messages that match the given byte data prefix.
  /// - Parameter data: The raw byte data prefix to subscribe to.
  /// - Parameter size: The size of the data in bytes.
  /// - Throws: ZmqError if the subscription fails or if not called on a SUB socket.
  public func subscribe(data: UnsafeRawPointer, size: Int) throws {
    let zrc = zmq_setsockopt(socket, ZMQ_SUBSCRIBE, data, size)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Unsubscribes a SUB socket from messages that match the given prefix.
  /// - Parameter prefix: The message prefix to unsubscribe from.
  /// - Throws: ZmqError if the unsubscription fails or if not called on a SUB socket.
  public func unsubscribe(prefix: String) throws {
    let zrc = zmq_setsockopt(
      socket, ZMQ_UNSUBSCRIBE, prefix, prefix.utf8.count)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Unsubscribes a SUB socket from messages that match the given byte data prefix.
  /// - Parameter data: The raw byte data prefix to unsubscribe from.
  /// - Parameter size: The size of the data in bytes.
  /// - Throws: ZmqError if the unsubscription fails or if not called on a SUB socket.
  public func unsubscribe(data: UnsafeRawPointer, size: Int) throws {
    let zrc = zmq_setsockopt(socket, ZMQ_UNSUBSCRIBE, data, size)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Sets the identity for a socket.
  /// This is primarily used with ROUTER and DEALER sockets to provide a persistent
  /// identity that survives application restarts.
  ///
  /// - Parameter identity: The string to use as the socket identity.
  /// - Throws: ZmqError if setting the identity fails.
  /// - Note: Identity must be between 1 and 255 bytes long and cannot start with a zero byte.
  public func setIdentity(_ identity: String) throws {
    try setIdentity(identity, size: identity.utf8.count)
  }
  
  /// Sets the identity for a socket using raw bytes.
  ///
  /// - Parameter data: The raw byte data to use as the socket identity.
  /// - Parameter size: The size of the data in bytes.
  /// - Throws: ZmqError if setting the identity fails.
  /// - Note: Identity must be between 1 and 255 bytes long and cannot start with a zero byte.
  public func setIdentity(_ data: UnsafeRawPointer, size: Int) throws {
    // ZeroMQ requires identities to be between 1 and 255 bytes
    guard size > 0 && size <= 255 else {
      throw SzqError.invalidIdentitySize
    }
    
    let zrc = zmq_setsockopt(socket, ZMQ_IDENTITY, data, size)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Sets the identity for a socket using an array of bytes.
  ///
  /// - Parameter bytes: The byte array to use as the socket identity.
  /// - Parameter size: The number of bytes to use from the array.
  /// - Throws: ZmqError if setting the identity fails.
  /// - Note: Identity must be between 1 and 255 bytes long and cannot start with a zero byte.
  public func setIdentity(_ bytes: [UInt8], size: Int) throws {
    try bytes.withUnsafeBytes { buffer in
      try setIdentity(buffer.baseAddress!, size: size)
    }
  }
  
  /// Gets the current identity of a socket.
  ///
  /// - Returns: The socket's identity as a Message.
  /// - Throws: ZmqError if retrieving the identity fails.
  public func getIdentity() throws -> Message {
    var buffer = [UInt8](repeating: 0, count: 255)
    var size = buffer.count
    
    let zrc = zmq_getsockopt(socket, ZMQ_IDENTITY, &buffer, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    
    let message = try Message(size: size)
    if let dataPtr = message.data {
      memcpy(dataPtr, buffer, size)
    }
    
    return message
  }
  
  // MARK: - High Water Mark Options
  
  /// Sets the high water mark for outbound messages.
  ///
  /// The high water mark is a hard limit on the maximum number of outstanding messages
  /// ZeroMQ shall queue in memory for any single peer that the specified socket is
  /// communicating with. If this limit has been reached the socket shall enter an
  /// exceptional state and depending on the socket type, ZeroMQ shall take appropriate
  /// action such as blocking or dropping sent messages.
  ///
  /// - Parameter value: The high water mark for outbound messages (default: 1000)
  /// - Throws: ZmqError if setting the option fails.
  public func setSendHighWaterMark(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_SNDHWM, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the high water mark for outbound messages.
  ///
  /// - Returns: The high water mark for outbound messages.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getSendHighWaterMark() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_SNDHWM, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  /// Sets the high water mark for inbound messages.
  ///
  /// The high water mark is a hard limit on the maximum number of outstanding messages
  /// ZeroMQ shall queue in memory for any single peer that the specified socket is
  /// communicating with. If this limit has been reached the socket shall enter an
  /// exceptional state and depending on the socket type, ZeroMQ shall take appropriate
  /// action such as blocking or dropping received messages.
  ///
  /// - Parameter value: The high water mark for inbound messages (default: 1000)
  /// - Throws: ZmqError if setting the option fails.
  public func setReceiveHighWaterMark(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_RCVHWM, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the high water mark for inbound messages.
  ///
  /// - Returns: The high water mark for inbound messages.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getReceiveHighWaterMark() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_RCVHWM, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  // MARK: - Timeout Options
  
  /// Sets the timeout for send operations.
  ///
  /// Sets the timeout for send operations on the socket. If the value is 0,
  /// zmq_send(3) will return immediately if there is no message to send. If the value
  /// is -1, it will block until a message can be sent. For all other values, it will
  /// try to send the message for that amount of time before returning with an error.
  ///
  /// - Parameter milliseconds: The timeout in milliseconds (default: -1)
  /// - Throws: ZmqError if setting the option fails.
  public func setSendTimeout(milliseconds: Int32) throws {
    var milliseconds = milliseconds
    let zrc = zmq_setsockopt(socket, ZMQ_SNDTIMEO, &milliseconds, MemoryLayout.size(ofValue: milliseconds))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the timeout for send operations.
  ///
  /// - Returns: The timeout for send operations in milliseconds.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getSendTimeout() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_SNDTIMEO, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  /// Sets the timeout for receive operations.
  ///
  /// Sets the timeout for receive operations on the socket. If the value is 0,
  /// zmq_recv(3) will return immediately if there is no message to receive. If the value
  /// is -1, it will block until a message is available. For all other values, it will
  /// try to receive a message for that amount of time before returning with an error.
  ///
  /// - Parameter milliseconds: The timeout in milliseconds (default: -1)
  /// - Throws: ZmqError if setting the option fails.
  public func setReceiveTimeout(milliseconds: Int32) throws {
    var milliseconds = milliseconds
    let zrc = zmq_setsockopt(socket, ZMQ_RCVTIMEO, &milliseconds, MemoryLayout.size(ofValue: milliseconds))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the timeout for receive operations.
  ///
  /// - Returns: The timeout for receive operations in milliseconds.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getReceiveTimeout() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_RCVTIMEO, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  // MARK: - Reconnection Options
  
  /// Sets the initial reconnection interval.
  ///
  /// The initial reconnection interval sets the period to wait before attempting
  /// to reconnect after a disconnection. The value is in milliseconds.
  ///
  /// - Parameter milliseconds: The reconnection interval in milliseconds (default: 100)
  /// - Throws: ZmqError if setting the option fails.
  public func setReconnectInterval(milliseconds: Int32) throws {
    var milliseconds = milliseconds
    let zrc = zmq_setsockopt(socket, ZMQ_RECONNECT_IVL, &milliseconds, MemoryLayout.size(ofValue: milliseconds))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the initial reconnection interval.
  ///
  /// - Returns: The reconnection interval in milliseconds.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getReconnectInterval() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_RECONNECT_IVL, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  /// Sets the maximum reconnection interval.
  ///
  /// The maximum reconnection interval sets the upper limit for the reconnection
  /// interval when using exponential backoff. It is used to prevent endless reconnection attempts
  /// at absurdly large time intervals.
  ///
  /// - Parameter milliseconds: The maximum reconnection interval in milliseconds (default: 0, meaning no exponential backoff)
  /// - Throws: ZmqError if setting the option fails.
  public func setMaxReconnectInterval(milliseconds: Int32) throws {
    var milliseconds = milliseconds
    let zrc = zmq_setsockopt(socket, ZMQ_RECONNECT_IVL_MAX, &milliseconds, MemoryLayout.size(ofValue: milliseconds))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the maximum reconnection interval.
  ///
  /// - Returns: The maximum reconnection interval in milliseconds.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getMaxReconnectInterval() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_RECONNECT_IVL_MAX, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  // MARK: - TCP Options
  
  /// Sets the TCP keep-alive option.
  ///
  /// Defines whether TCP keep-alive packets should be sent on the connection. The default
  /// value is -1, which means to skip any overrides and leave it to the OS default.
  ///
  /// - Parameter value: The TCP keep-alive option (-1: OS default, 0: no keep-alive, 1: use keep-alive)
  /// - Throws: ZmqError if setting the option fails.
  public func setTCPKeepAlive(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_TCP_KEEPALIVE, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the TCP keep-alive option.
  ///
  /// - Returns: The TCP keep-alive option.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getTCPKeepAlive() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_TCP_KEEPALIVE, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  // MARK: - Message Size Option
  
  /// Sets the maximum allowed size of a message.
  ///
  /// Limits the size of messages that can be transferred over the socket. If a peer
  /// sends a message exceeding this limit, the message will be dropped.
  ///
  /// - Parameter maxSize: The maximum message size in bytes (default: -1, meaning no limit)
  /// - Throws: ZmqError if setting the option fails.
  public func setMaxMessageSize(_ maxSize: Int64) throws {
    var maxSize = maxSize
    let zrc = zmq_setsockopt(socket, ZMQ_MAXMSGSIZE, &maxSize, MemoryLayout.size(ofValue: maxSize))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the maximum allowed size of a message.
  ///
  /// - Returns: The maximum message size in bytes.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getMaxMessageSize() throws -> Int64 {
    var value: Int64 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_MAXMSGSIZE, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  // MARK: - Multicast Options
  
  /// Sets the multicast hop count.
  ///
  /// Sets the multicast hop count for packets sent from the socket. Setting this
  /// option limits the number of "hops" a multicast packet will take.
  ///
  /// - Parameter value: The multicast hop count (default: 1)
  /// - Throws: ZmqError if setting the option fails.
  public func setMulticastHops(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_MULTICAST_HOPS, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the multicast hop count.
  ///
  /// - Returns: The multicast hop count.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getMulticastHops() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_MULTICAST_HOPS, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  // MARK: - Connection Backlog Option
  
  /// Sets the maximum length of the queue of outstanding connections.
  ///
  /// Sets the maximum length of the queue of outstanding peer connections for the
  /// specified socket. This applies only to connection-oriented transports.
  ///
  /// - Parameter value: The backlog size (default: 100)
  /// - Throws: ZmqError if setting the option fails.
  public func setBacklog(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_BACKLOG, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the maximum length of the queue of outstanding connections.
  ///
  /// - Returns: The backlog size.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getBacklog() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_BACKLOG, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  // MARK: - ROUTER/DEALER Socket Options
  
  /// Sets the ROUTER socket's behavior when an unroutable message is encountered.
  ///
  /// A value of 0 is the default and discards the message silently when it cannot be
  /// routed. A value of 1 causes send() to throw an error if the message cannot be
  /// routed.
  ///
  /// - Parameter value: The router mandatory flag (0: discard silently, 1: report errors)
  /// - Throws: ZmqError if setting the option fails.
  public func setRouterMandatory(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_ROUTER_MANDATORY, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Sets whether the ROUTER socket should hand off a raw identity to a newly connected
  /// peer, rather than generating an identity for it.
  ///
  /// A value of 0 means ZeroMQ will generate a new UUID for each new connection
  /// (the default). A value of 1 means the socket will use a raw identity for new connections.
  ///
  /// - Parameter value: The router raw mode flag (0: ZeroMQ-generated IDs, 1: raw IDs)
  /// - Throws: ZmqError if setting the option fails.
  public func setRouterRaw(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_ROUTER_RAW, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Sets whether a ROUTER socket will route messages from a DEALER with an empty identity.
  ///
  /// A value of 0 means reject empty identity DEALER connections (the default).
  /// A value of 1 means allow connections from dealers with no identity.
  ///
  /// - Parameter value: The router handover flag (0: reject, 1: allow)
  /// - Throws: ZmqError if setting the option fails.
  public func setRouterHandover(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_ROUTER_HANDOVER, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  // MARK: - PUB/SUB Socket Options
  
  /// Sets a publisher socket's conflate option.
  ///
  /// Specifies that only the last message should be kept in the send queue, for
  /// subscribers with slow connections. A value of 1 means only keep the most recent
  /// message (conflate), while 0 means keep all messages (the default).
  ///
  /// - Parameter value: The conflate flag (0: keep all messages, 1: only keep the most recent)
  /// - Throws: ZmqError if setting the option fails.
  public func setConflate(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_CONFLATE, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets a publisher socket's conflate option.
  ///
  /// - Returns: The conflate flag value.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getConflate() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_CONFLATE, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  /// Sets the SOCKS5 proxy password.
  ///
  /// Sets the password used for authenticating with the SOCKS5 proxy.
  ///
  /// - Parameter password: The password string for SOCKS5 proxy authentication
  /// - Throws: ZmqError if setting the option fails.
  public func setSocks5Password(_ password: String) throws {
    let zrc = zmq_setsockopt(socket, ZMQ_SOCKS_PASSWORD, password, password.utf8.count)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Sets the SOCKS5 proxy username.
  ///
  /// Sets the username used for authenticating with the SOCKS5 proxy.
  ///
  /// - Parameter username: The username string for SOCKS5 proxy authentication
  /// - Throws: ZmqError if setting the option fails.
  public func setSocks5Username(_ username: String) throws {
    let zrc = zmq_setsockopt(socket, ZMQ_SOCKS_USERNAME, username, username.utf8.count)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Sets the proxy address to use for the socket.
  ///
  /// - Parameter proxyAddress: The proxy address string, e.g., "tcp://proxy.example.com:1080"
  /// - Throws: ZmqError if setting the option fails.
  public func setProxy(_ proxyAddress: String) throws {
    let zrc = zmq_setsockopt(socket, ZMQ_SOCKS_PROXY, proxyAddress, proxyAddress.utf8.count)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the proxy address used for the socket.
  ///
  /// - Returns: The proxy address string, or nil if no proxy is set.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getProxy() throws -> String? {
    var buffer = [Int8](repeating: 0, count: 255)
    var size = buffer.count
    let zrc = zmq_getsockopt(socket, ZMQ_SOCKS_PROXY, &buffer, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    
    if size == 0 {
      return nil
    }
    
    // Convert to UInt8 array and truncate null terminator for String creation
    let uint8Buffer = buffer.map { UInt8(bitPattern: $0) }
    let nullIndex = uint8Buffer.firstIndex(of: 0) ?? size
    return String(decoding: uint8Buffer[0..<nullIndex], as: UTF8.self)
  }
  
  // MARK: - IP Version Options
  
  /// Sets whether the socket should use IPv6.
  ///
  /// A value of 1 means the socket will use IPv6 when available (default: 0).
  ///
  /// - Parameter value: The IPv6 flag (0: don't use IPv6, 1: use IPv6)
  /// - Throws: ZmqError if setting the option fails.
  public func setIPv6(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_IPV6, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets whether the socket will use IPv6.
  ///
  /// - Returns: The IPv6 flag value.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getIPv6() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_IPV6, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  /// Sets whether the socket should use IPv4 only.
  ///
  /// A value of 1 means the socket will use IPv4 only (default: 1).
  /// This option is deprecated in favor of ZMQ_IPV6.
  ///
  /// - Parameter value: The IPv4-only flag (0: use IPv6 if available, 1: use IPv4 only)
  /// - Throws: ZmqError if setting the option fails.
  public func setIPv4Only(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_IPV4ONLY, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets whether the socket uses IPv4 only.
  ///
  /// - Returns: The IPv4-only flag value.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getIPv4Only() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_IPV4ONLY, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  // MARK: - Connection Options
  
  /// Gets the last endpoint bound or connected for the socket.
  ///
  /// This can be useful for retrieving the assigned port when binding to an
  /// ephemeral port (e.g., tcp://127.0.0.1:*).
  ///
  /// - Returns: The last endpoint string.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getLastEndpoint() throws -> String {
    var buffer = [Int8](repeating: 0, count: 255)
    var size = buffer.count
    let zrc = zmq_getsockopt(socket, ZMQ_LAST_ENDPOINT, &buffer, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    
    // Convert to UInt8 array and truncate null terminator for String creation
    let uint8Buffer = buffer.map { UInt8(bitPattern: $0) }
    let nullIndex = uint8Buffer.firstIndex(of: 0) ?? size
    return String(decoding: uint8Buffer[0..<nullIndex], as: UTF8.self)
  }
  
  /// Sets the handshake interval for the socket.
  ///
  /// The handshake interval is the maximum allowed time for the connection handshake
  /// to complete in milliseconds.
  ///
  /// - Parameter milliseconds: The handshake interval in milliseconds (default: 30000)
  /// - Throws: ZmqError if setting the option fails.
  public func setHandshakeInterval(milliseconds: Int32) throws {
    var milliseconds = milliseconds
    let zrc = zmq_setsockopt(socket, ZMQ_HANDSHAKE_IVL, &milliseconds, MemoryLayout.size(ofValue: milliseconds))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the handshake interval for the socket.
  ///
  /// - Returns: The handshake interval in milliseconds.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getHandshakeInterval() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_HANDSHAKE_IVL, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  /// Sets whether the socket should delay or drop outgoing messages when there is no connection.
  ///
  /// By default (0), ZeroMQ will queue messages when there is no connection for PUSH, DEALER, and ROUTER sockets.
  /// With immediate set to 1, it will instead drop the messages.
  ///
  /// - Parameter value: The immediate flag (0: queue messages, 1: drop messages)
  /// - Throws: ZmqError if setting the option fails.
  public func setImmediate(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_IMMEDIATE, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets whether the socket drops outgoing messages when there is no connection.
  ///
  /// - Returns: The immediate flag value.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getImmediate() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_IMMEDIATE, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  // MARK: - Socket Information
  
  /// Gets the socket type.
  ///
  /// - Returns: The socket type.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getType() throws -> SocketType {
    var type: Int32 = 0
    var size = MemoryLayout.size(ofValue: type)
    let zrc = zmq_getsockopt(socket, ZMQ_TYPE, &type, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    
    guard let socketType = SocketType(zmqValue: type) else {
      throw SzqError.badType
    }
    
    return socketType
  }
  
  /// Gets the events currently waiting on the socket.
  ///
  /// - Returns: A bitmask of events (ZMQ_POLLIN, ZMQ_POLLOUT).
  /// - Throws: ZmqError if retrieving the option fails.
  public func getEvents() throws -> Int32 {
    var events: Int32 = 0
    var size = MemoryLayout.size(ofValue: events)
    let zrc = zmq_getsockopt(socket, ZMQ_EVENTS, &events, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return events
  }
  
  // MARK: - Multicast Rate Control
  
  /// Sets the multicast data rate in kilobits per second.
  ///
  /// - Parameter value: The multicast rate in kilobits per second (default: 100)
  /// - Throws: ZmqError if setting the option fails.
  public func setMulticastRate(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_RATE, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the multicast data rate.
  ///
  /// - Returns: The multicast rate in kilobits per second.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getMulticastRate() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_RATE, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  /// Sets the multicast recovery interval in milliseconds.
  ///
  /// The recovery interval determines how long a receiver will take to recover
  /// when a multicast transmission is dropped.
  ///
  /// - Parameter milliseconds: The multicast recovery interval in milliseconds (default: 10000)
  /// - Throws: ZmqError if setting the option fails.
  public func setMulticastRecoveryInterval(milliseconds: Int32) throws {
    var milliseconds = milliseconds
    let zrc = zmq_setsockopt(socket, ZMQ_RECOVERY_IVL, &milliseconds, MemoryLayout.size(ofValue: milliseconds))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the multicast recovery interval.
  ///
  /// - Returns: The multicast recovery interval in milliseconds.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getMulticastRecoveryInterval() throws -> Int32 {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_RECOVERY_IVL, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
  
  // MARK: - Security Options (CURVE)
  
  /// Sets whether the socket should use CURVE security.
  ///
  /// A value of 1 means the socket will use CURVE security (default: 0).
  ///
  /// - Parameter value: The CURVE security flag (0: no security, 1: use CURVE)
  /// - Throws: ZmqError if setting the option fails.
  public func setCurveServer(_ value: Int32) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_CURVE_SERVER, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets whether the socket is using CURVE security in server mode.
  ///
  /// - Returns: The CURVE server flag value.
  /// - Throws: ZmqError if retrieving the option fails.
  public func isCurveServer() throws -> Bool {
    var value: Int32 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_CURVE_SERVER, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value == 1
  }
  
  /// Sets the CURVE public key for the socket.
  ///
  /// The public key must be 32 bytes long (Z85-encoded or binary).
  ///
  /// - Parameter key: The CURVE public key as a string (Z85-encoded 40-character string)
  /// - Throws: ZmqError if setting the option fails.
  public func setCurvePublicKey(_ key: String) throws {
    let zrc = zmq_setsockopt(socket, ZMQ_CURVE_PUBLICKEY, key, key.utf8.count)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Sets the CURVE public key for the socket using raw binary data.
  ///
  /// - Parameter key: The 32-byte raw binary CURVE public key
  /// - Throws: ZmqError if setting the option fails.
  public func setCurvePublicKeyBinary(_ key: [UInt8]) throws {
    guard key.count == 32 else {
      throw SzqError.invalidKeySize
    }
    
    let zrc = zmq_setsockopt(socket, ZMQ_CURVE_PUBLICKEY, key, 32)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the CURVE public key for the socket.
  ///
  /// - Returns: The CURVE public key as a Z85-encoded string.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getCurvePublicKey() throws -> String {
    var buffer = [Int8](repeating: 0, count: 41) // Z85-encoded key (40 chars) + null terminator
    var size = buffer.count - 1
    let zrc = zmq_getsockopt(socket, ZMQ_CURVE_PUBLICKEY, &buffer, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    
    // Convert to UInt8 array and truncate null terminator for String creation
    let uint8Buffer = buffer.map { UInt8(bitPattern: $0) }
    let nullIndex = uint8Buffer.firstIndex(of: 0) ?? size
    return String(decoding: uint8Buffer[0..<nullIndex], as: UTF8.self)
  }
  
  /// Sets the CURVE secret key for the socket.
  ///
  /// The secret key must be 32 bytes long (Z85-encoded or binary).
  ///
  /// - Parameter key: The CURVE secret key as a string (Z85-encoded 40-character string)
  /// - Throws: ZmqError if setting the option fails.
  public func setCurveSecretKey(_ key: String) throws {
    let zrc = zmq_setsockopt(socket, ZMQ_CURVE_SECRETKEY, key, key.utf8.count)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Sets the CURVE secret key for the socket using raw binary data.
  ///
  /// - Parameter key: The 32-byte raw binary CURVE secret key
  /// - Throws: ZmqError if setting the option fails.
  public func setCurveSecretKeyBinary(_ key: [UInt8]) throws {
    guard key.count == 32 else {
      throw SzqError.invalidKeySize
    }
    
    let zrc = zmq_setsockopt(socket, ZMQ_CURVE_SECRETKEY, key, 32)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the CURVE secret key for the socket.
  ///
  /// - Returns: The CURVE secret key as a Z85-encoded string.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getCurveSecretKey() throws -> String {
    var buffer = [Int8](repeating: 0, count: 41) // Z85-encoded key (40 chars) + null terminator
    var size = buffer.count - 1
    let zrc = zmq_getsockopt(socket, ZMQ_CURVE_SECRETKEY, &buffer, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    
    // Convert to UInt8 array and truncate null terminator for String creation
    let uint8Buffer = buffer.map { UInt8(bitPattern: $0) }
    let nullIndex = uint8Buffer.firstIndex(of: 0) ?? size
    return String(decoding: uint8Buffer[0..<nullIndex], as: UTF8.self)
  }
  
  /// Sets the CURVE server's public key for the socket.
  ///
  /// Used by CURVE client sockets to specify the server's public key.
  ///
  /// - Parameter key: The CURVE server's public key as a string (Z85-encoded 40-character string)
  /// - Throws: ZmqError if setting the option fails.
  public func setCurveServerKey(_ key: String) throws {
    let zrc = zmq_setsockopt(socket, ZMQ_CURVE_SERVERKEY, key, key.utf8.count)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Sets the CURVE server's public key for the socket using raw binary data.
  ///
  /// - Parameter key: The 32-byte raw binary CURVE server's public key
  /// - Throws: ZmqError if setting the option fails.
  public func setCurveServerKeyBinary(_ key: [UInt8]) throws {
    guard key.count == 32 else {
      throw SzqError.invalidKeySize
    }
    
    let zrc = zmq_setsockopt(socket, ZMQ_CURVE_SERVERKEY, key, 32)
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the CURVE server's public key for the socket.
  ///
  /// - Returns: The CURVE server's public key as a Z85-encoded string.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getCurveServerKey() throws -> String {
    var buffer = [Int8](repeating: 0, count: 41) // Z85-encoded key (40 chars) + null terminator
    var size = buffer.count - 1
    let zrc = zmq_getsockopt(socket, ZMQ_CURVE_SERVERKEY, &buffer, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    
    // Convert to UInt8 array and truncate null terminator for String creation
    let uint8Buffer = buffer.map { UInt8(bitPattern: $0) }
    let nullIndex = uint8Buffer.firstIndex(of: 0) ?? size
    return String(decoding: uint8Buffer[0..<nullIndex], as: UTF8.self)
  }
  
  // MARK: - Thread Affinity Option
  
  /// Sets the socket's I/O thread affinity.
  ///
  /// This option sets which threads from the I/O thread pool will handle the socket.
  /// The affinity is represented as a bitmask, with each bit corresponding to a thread
  /// in the pool.
  ///
  /// - Parameter value: The I/O thread affinity bitmask
  /// - Throws: ZmqError if setting the option fails.
  public func setAffinity(_ value: UInt64) throws {
    var value = value
    let zrc = zmq_setsockopt(socket, ZMQ_AFFINITY, &value, MemoryLayout.size(ofValue: value))
    if zrc == -1 {
      throw currentZmqError()
    }
  }
  
  /// Gets the socket's I/O thread affinity.
  ///
  /// - Returns: The I/O thread affinity bitmask.
  /// - Throws: ZmqError if retrieving the option fails.
  public func getAffinity() throws -> UInt64 {
    var value: UInt64 = 0
    var size = MemoryLayout.size(ofValue: value)
    let zrc = zmq_getsockopt(socket, ZMQ_AFFINITY, &value, &size)
    if zrc == -1 {
      throw currentZmqError()
    }
    return value
  }
}
