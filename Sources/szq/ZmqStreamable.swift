import Foundation
import ZeroMQ

public protocol ZmqStreamable {
  static func pack(value: Self) throws -> zmq_msg_t
  static func unpack(from msgPtr: UnsafeMutablePointer<zmq_msg_t>) -> Self?
}

extension String: ZmqStreamable {

  public static func pack(value: String) throws -> zmq_msg_t {
    var msg = zmq_msg_t()
    let zrc = zmq_msg_init_size(&msg, value.utf8.count)
    if zrc != 0 {
      throw currentZmqError()
    }
    let data = zmq_msg_data(&msg)
    _ = value.withCString { cStr in
      memcpy(data, cStr, value.utf8.count)
    }
    return msg
  }

  public static func unpack(from msgPtr: UnsafeMutablePointer<zmq_msg_t>) -> String? {
    guard let dataPtr = zmq_msg_data(msgPtr) else {
      return nil
    }
    let buffer = UnsafeBufferPointer(
      start: dataPtr.assumingMemoryBound(to: UInt8.self), count: zmq_msg_size(msgPtr))
    return String(bytes: buffer, encoding: .utf8)
  }

}

extension ZmqStreamable where Self: BitwiseCopyable {
  public static func unpack(from msgPtr: UnsafeMutablePointer<zmq_msg_t>) -> Self? {
    guard let dataPtr = zmq_msg_data(msgPtr) else {
      return nil
    }

    return dataPtr.withMemoryRebound(to: Self.self, capacity: 1) { pointer in
      return pointer.pointee
    }
  }

  public static func pack(value: Self) throws -> zmq_msg_t {
    var msg = zmq_msg_t()
    let size = MemoryLayout<Self>.size
    let zrc = zmq_msg_init_size(&msg, size)
    if zrc != 0 {
      throw currentZmqError()
    }
    let data = zmq_msg_data(&msg)
    _ = withUnsafeBytes(of: value) { bytes in
      memcpy(data, bytes.baseAddress, size)
    }
    return msg
  }
}

extension Bool: ZmqStreamable {}

extension Int: ZmqStreamable {}
extension Int8: ZmqStreamable {}
extension Int16: ZmqStreamable {}
extension Int32: ZmqStreamable {}
extension Int64: ZmqStreamable {}

extension UInt: ZmqStreamable {}
extension UInt8: ZmqStreamable {}
extension UInt16: ZmqStreamable {}
extension UInt32: ZmqStreamable {}
extension UInt64: ZmqStreamable {}

extension Float: ZmqStreamable {}
extension Double: ZmqStreamable {}
