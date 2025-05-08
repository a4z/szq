// swiftlint:disable force_try
import Testing
import XCTest

@testable import szq

@Suite("TCPSocketTest")
struct TCPSocketTestSuite {

  let ctx = Context()

  @Test func testTCPLinger() throws {
    let address = "tcp://127.0.0.1:\(5000 + #line)"
    let client = try! ctx.connect(type: .push, url: address)
    var linger = try! client.linger()
    #expect(linger == 0)
    try! client.linger(milliseconds: 1000)
    linger = try! client.linger()
    #expect(linger == 1000)
  }

  @Test func testTCPBasicSendRec() throws {
    let address = "tcp://127.0.0.1:\(5000 + #line)"
    let server = try! ctx.bind(type: .pull, url: address)
    let client = try! ctx.connect(type: .push, url: address)

    // Sleep to ensure connection is established
    Thread.sleep(forTimeInterval: 0.1)
    
    let msgSend = pack(value: "Hello TCP")!
    let zrc = try! client.send(msgSend)
    #expect(zrc == 9)

    let gotMessage = try server.awaitMessage(timeout: 1000)
    #expect(gotMessage == true)

    let msgReceived = try server.recv()!
    let val = unpack(message: msgReceived)! as String
    #expect(val == "Hello TCP")
  }

  @Test func testTCPBasicSendRecN() throws {
    let address = "tcp://127.0.0.1:\(5000 + #line)"
    let server = try! ctx.bind(type: .pull, url: address)
    let client = try! ctx.connect(type: .push, url: address)

    // Sleep to ensure connection is established
    Thread.sleep(forTimeInterval: 0.1)
    
    let msg1 = pack(value: "Hello TCP")!
    let msg2 = pack(value: 4.56)!

    _ = try! client.send(msg1, msg2)

    if try server.awaitMessage(timeout: 1000) {
      let msgs = try server.recvAll()!
      #expect(msgs.count == 2)
      let val1 = unpack(message: msgs[0])! as String
      let val2 = unpack(message: msgs[1])! as Double
      #expect(val1 == "Hello TCP")
      #expect(val2 == 4.56)
    } else {
      #expect(Bool(false))
    }
  }

  @Test func testTCPSendNoMessage() throws {
    let address = "tcp://127.0.0.1:\(5000 + #line)"
    let server = try! ctx.bind(type: .pull, url: address)
    // No client connects, so no messages should be received
    
    let gotMessage = try server.awaitMessage(timeout: 100)
    #expect(gotMessage == false)
    let msg = try server.recv()
    #expect(msg == nil)
    let msgs = try server.recvAll()
    #expect(msgs == nil)
  }
}
// swiftlint:enable force_try