import Foundation
import ZeroMQ

public class TypedMessage {

  let type: String
  let msg: Message

  public init<T: ZmqStreamable>(value: T) throws {
    self.type = String(describing: Swift.type(of: value))
    self.msg = try Message(zmq_msg: T.pack(value: value))
  }

  public init(type: String, message: Message) {
    self.type = type
    self.msg = message
  }

  public init(type: Message, message: Message) {
    self.type = unpack(message: type)! as String
    self.msg = message
  }

  public func hasType<T: ZmqStreamable>(_ type: T.Type) -> Bool {
    return self.type == String(describing: type)
  }

  public var typeString: String {
    return type
  }

  public func value<T: ZmqStreamable>() throws -> T! {
    if !hasType(T.self) {
      throw SzqError.badType
    }
    return unpack(message: msg)
  }
}

public func send(socket: Socket, message: TypedMessage) throws {
  let msgType = pack(value: message.type)!
  _ = try socket.send(msgType, message.msg)
}
