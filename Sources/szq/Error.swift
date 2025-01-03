//typealias Error = Int32

import ZeroMQ

public struct ZmqError: Error, CustomStringConvertible {
  public let code: Int32
  public let description: String

  init(code: Int32) {
    self.code = code
    self.description = String(validatingCString: zmq_strerror(code))!
  }
}

public func currentZmqError() -> ZmqError {
  ZmqError(code: zmq_errno())
}

enum SzqError: Error {
  case badType
  case invalidContext

}
