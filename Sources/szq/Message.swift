import Foundation
import ZeroMQ

// TODO , this unchecked is probably not awesome, but for get going, do it
public class Message: @unchecked Sendable{

  var msg: zmq_msg_t

// TODO, do I need that at all?
  public init() {
    msg = zmq_msg_t()
    zmq_msg_init(&msg)
  }

  public init(zmq_msg: zmq_msg_t) {
    self.msg = zmq_msg
  }

// TODO, do I need that at all?
  init(size: Int) throws {
    msg = zmq_msg_t()
    let rc = zmq_msg_init_size(&msg, size)
    if rc != 0 {
      throw currentZmqError()
    }
  }

  public var data: UnsafeMutableRawPointer? {
    return zmq_msg_data(&msg)
  }

  public var size: Int {
    return zmq_msg_size(&msg)
  }

}

public func pack<T: ZmqStreamable>(value: T) -> Message? {
  return Message(zmq_msg: try! T.pack(value: value))
}
public func unpack<T: ZmqStreamable>(message: Message) -> T? {
  return T.unpack(from: &message.msg)
}
