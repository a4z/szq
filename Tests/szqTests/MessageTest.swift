import Testing

@testable import szq

fileprivate struct Point  {
  let x: Int
  let y: Int
}

extension Point : ZmqStreamable {}


@Suite("Message Types")
struct MessageTestSuite {

  @Test func testEmpty() async throws {
    let msg = try! Message(size: 1024)
    #expect(msg.size == 1024)
  }

  @Test func testInt() async throws {
    let msg = pack(value: 123)!
    #expect(msg.size == 8)
    let val: Int = unpack(message: msg)!
    #expect(val == 123)
  }

  @Test func testDouble() async throws {
    let msg = pack(value: 1.23)!
    #expect(msg.size == 8)
    let val: Double? = unpack(message: msg)
    #expect(val == 1.23)
  }

  @Test func testString() async throws {
    let msg = pack(value: "Hello")!
    #expect(msg.size == 5)
    let val = unpack(message: msg)! as String
    #expect(val == "Hello")
  }

  @Test func testPoint() async throws {
    let msg = pack(value: Point(x: 1, y: 2))!
    #expect(msg.size == 16)
    let val = unpack(message: msg) as Point?
    #expect(val?.x == 1)
    #expect(val?.y == 2)
  }

}
