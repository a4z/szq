import Foundation
import ZeroMQ

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

}
