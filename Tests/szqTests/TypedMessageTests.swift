import Testing

@testable import szq

// swiftlint:disable force_try
// swiftlint:disable identifier_name
private struct Point {
  let x: Int
  let y: Int
}
// swiftlint:enable identifier_name

extension Point: ZmqStreamable {}

@Suite("TypedMessageSuite")
struct TypedMessageTestSuite {

  let ctx = Context()

  @Test func testHasType() async throws {
    let msg1 = try! TypedMessage(value: 123)
    #expect(msg1.hasType(Int.self))
    #expect(!msg1.hasType(String.self))

    let msg2 = try! TypedMessage(value: "Hello")
    #expect(!msg2.hasType(Int.self))
    #expect(msg2.hasType(String.self))

    let msg3 = try! TypedMessage(value: Point(x: 1, y: 2))
    #expect(msg3.hasType(Point.self))
    #expect(msg3.typeString == "Point")

    #expect(throws: SzqError.badType) {
      _ = try msg3.value() as String
    }
    let val = try msg3.value() as Point
    #expect(val.x == 1 && val.y == 2)

  }

  @Test func testSend() async throws {
    let address = "ipc:///tmp/zq_test_pipe_TypedMessageSuite\(#line)"
    let server = try! ctx.bind(type: .pull, url: address)
    let client = try! ctx.connect(type: .push, url: address)

    let msg1 = try! TypedMessage(value: 123)
    try send(socket: client, message: msg1)

    let gotMessage = try server.awaitMessage(timeout: 1000)
    #expect(gotMessage == true)

    let msgs = try server.recvAll()!
    #expect(msgs.count == 2)
    let val1 = unpack(message: msgs[0])! as String
    #expect(val1 == "Int")
    let val2 = unpack(message: msgs[1])! as Int
    #expect(val2 == 123)

    let recMessage = TypedMessage(type: msgs[0], message: msgs[1])
    #expect(recMessage.hasType(Int.self))

  }

}

// swiftlint:enable force_try
