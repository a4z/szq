import Foundation
import ZeroMQ

// swiftlint:disable:next todo
// TODO , this unchecked is probably not awesome, but for get going, do it
public class Message: @unchecked Sendable {

  var msg: zmq_msg_t

  // swiftlint:disable:next todo
  // TODO, do I need that at all?
  public init() {
    msg = zmq_msg_t()
    zmq_msg_init(&msg)
  }

  public init(zmqMsg: zmq_msg_t) {
    self.msg = zmqMsg
  }

  // swiftlint:disable:next todo
  // TODO, do I need that at all?
  init(size: Int) throws {
    msg = zmq_msg_t()
    if 0 != zmq_msg_init_size(&msg, size) {
      throw currentZmqError()
    }
  }

  deinit {
    zmq_msg_close(&msg)
  }

  public var data: UnsafeMutableRawPointer? {
    return zmq_msg_data(&msg)
  }

  public var size: Int {
    return zmq_msg_size(&msg)
  }

}

public func pack<T: ZmqStreamable>(value: T) -> Message? {
  do {
    return Message(zmqMsg: try T.pack(value: value))
  } catch {
    return nil
  }
}
public func unpack<T: ZmqStreamable>(message: Message) -> T? {
  return T.unpack(from: &message.msg)
}
