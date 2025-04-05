// let address = "tcp://localhost:5555"
// swiftlint:disable force_try
import Testing
import XCTest

@testable import szq

@Suite("SocketTest")

struct SocketTestSuite {

  let ctx = Context()

  @Test func testLinger() throws {
    let address = "ipc:///tmp/zq_test_pipe_SocketTest\(#line)"
    let client = try! ctx.connect(type: .push, url: address)
    var linger = try! client.linger()
    #expect(linger == 0)
    try! client.linger(milliseconds: 1000)
    linger = try! client.linger()
    #expect(linger == 1000)
  }

  @Test func testBasicSendRec() throws {
    let address = "ipc:///tmp/zq_test_pipe_SocketTest\(#line)"
    let server = try! ctx.bind(type: .pull, url: address)
    let client = try! ctx.connect(type: .push, url: address)

    let msgSend = pack(value: "Hello")!
    let zrc = try! client.send(msgSend)
    #expect(zrc == 5)

    let gotMessage = try server.awaitMessage(timeout: 1000)
    #expect(gotMessage == true)

    let msgReceived = try server.recv()!
    let val = unpack(message: msgReceived)! as String
    #expect(val == "Hello")

  }

  @Test func testBasicSendRecN() throws {
    let address = "ipc:///tmp/zq_test_pipe_SocketTest\(#line)"
    let server = try! ctx.bind(type: .pull, url: address)
    let client = try! ctx.connect(type: .push, url: address)

    let msg1 = pack(value: "Hello")!
    let msg2 = pack(value: 1.23)!

    _ = try! client.send(msg1, msg2)

    if try server.awaitMessage(timeout: 1000) {
      let msgs = try server.recvAll()!
      #expect(msgs.count == 2)
      let val1 = unpack(message: msgs[0])! as String
      let val2 = unpack(message: msgs[1])! as Double
      #expect(val1 == "Hello")
      #expect(val2 == 1.23)
    } else {
      #expect(Bool(false))
    }
  }

  @Test func testSendNoMessage() throws {
    let address = "ipc:///tmp/zq_test_pipe_SocketTest\(#line)"
    let server = try! ctx.bind(type: .pull, url: address)
    // let client = try! ctx.connect(type: .push, url: address)
    let gotMessage = try server.awaitMessage(timeout: 100)
    #expect(gotMessage == false)
    let msg = try server.recv()
    #expect(msg == nil)
    let msgs = try server.recvAll()
    #expect(msgs == nil)
  }
}
// swiftlint:enable force_try
