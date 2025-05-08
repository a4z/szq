// swiftlint:disable force_try
import Testing
import XCTest

@testable import szq

@Suite("InprocTest")
struct InprocTestSuite {

  let ctx = Context()

  @Test func testInprocBasicSendRec() throws {
    let address = "inproc://test-basic-\(#line)"
    let server = try! ctx.bind(type: .pull, url: address)
    let client = try! ctx.connect(type: .push, url: address)

    let msgSend = pack(value: "Hello Inproc")!
    let zrc = try! client.send(msgSend)
    #expect(zrc == 12)

    let gotMessage = try server.awaitMessage(timeout: 1000)
    #expect(gotMessage == true)

    let msgReceived = try server.recv()!
    let val = unpack(message: msgReceived)! as String
    #expect(val == "Hello Inproc")
  }

  @Test func testInprocSubscription() throws {
    let address = "inproc://test-sub-\(#line)"
    let publisher = try! ctx.bind(type: .pub, url: address)
    let subscriber = try! ctx.connect(type: .sub, url: address)
    
    // Subscribe to messages with prefix "A"
    try! subscriber.subscribe(prefix: "A")
    
    // Sleep to allow subscription to take effect
    Thread.sleep(forTimeInterval: 0.5)
    
    // Send messages with different prefixes
    let msgA = pack(value: "A-Inproc")!
    let msgB = pack(value: "B-Inproc")!
    
    _ = try! publisher.send(msgA)
    _ = try! publisher.send(msgB)
    
    // Sleep to allow messages to be processed
    Thread.sleep(forTimeInterval: 0.5)
    
    // Should receive only message with prefix "A"
    if try subscriber.awaitMessage(timeout: 1000) {
      let msg = try subscriber.recv()!
      let val = unpack(message: msg)! as String
      #expect(val == "A-Inproc")
      
      // Should not receive message with prefix "B"
      let gotAnotherMessage = try subscriber.awaitMessage(timeout: 100)
      #expect(gotAnotherMessage == false)
    } else {
      #expect(Bool(false), "Should have received a message")
    }
  }
  
  @Test func testInprocMultipart() throws {
    let address = "inproc://test-multipart-\(#line)"
    let server = try! ctx.bind(type: .pull, url: address)
    let client = try! ctx.connect(type: .push, url: address)

    let msg1 = pack(value: "First part")!
    let msg2 = pack(value: "Second part")!
    
    _ = try! client.send(msg1, msg2)
    
    if try server.awaitMessage(timeout: 1000) {
      let msgs = try server.recvAll()!
      #expect(msgs.count == 2)
      let val1 = unpack(message: msgs[0])! as String
      let val2 = unpack(message: msgs[1])! as String
      #expect(val1 == "First part")
      #expect(val2 == "Second part")
    } else {
      #expect(Bool(false), "Should have received messages")
    }
  }
}
// swiftlint:enable force_try