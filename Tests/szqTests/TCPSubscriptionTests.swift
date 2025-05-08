// swiftlint:disable force_try
import Testing
import XCTest

@testable import szq

@Suite("TCPSubscriptionTest")
struct TCPSubscriptionTestSuite {
  
  let ctx = Context()
  
  @Test func testTCPSubscribe() throws {
    let address = "tcp://127.0.0.1:\(5000 + #line)"
    let publisher = try! ctx.bind(type: .pub, url: address)
    let subscriber = try! ctx.connect(type: .sub, url: address)
    
    // Subscribe to messages with prefix "A"
    try! subscriber.subscribe(prefix: "A")
    
    // Sleep to allow subscription to take effect (slow joiner syndrome)
    Thread.sleep(forTimeInterval: 0.5)
    
    // Send messages with different prefixes
    let msgA = pack(value: "A-Message")!
    let msgB = pack(value: "B-Message")!
    
    _ = try! publisher.send(msgA)
    _ = try! publisher.send(msgB)
    
    // Sleep to allow messages to be processed
    Thread.sleep(forTimeInterval: 0.5)
    
    // Should receive only message with prefix "A"
    if try subscriber.awaitMessage(timeout: 1000) {
      let msg = try subscriber.recv()!
      let val = unpack(message: msg)! as String
      #expect(val == "A-Message")
      
      // Should not receive message with prefix "B"
      let gotAnotherMessage = try subscriber.awaitMessage(timeout: 100)
      #expect(gotAnotherMessage == false)
    } else {
      #expect(Bool(false), "Should have received a message")
    }
  }
  
  @Test func testTCPUnsubscribe() throws {
    let address = "tcp://127.0.0.1:\(5000 + #line)"
    let publisher = try! ctx.bind(type: .pub, url: address)
    let subscriber = try! ctx.connect(type: .sub, url: address)
    
    // First subscribe to specific prefixes
    try! subscriber.subscribe(prefix: "A")
    try! subscriber.subscribe(prefix: "B")
    
    // Sleep to allow subscriptions to take effect
    Thread.sleep(forTimeInterval: 0.5)
    
    // Send messages to verify both subscriptions work
    let msgA1 = pack(value: "A-First")!
    let msgB1 = pack(value: "B-First")!
    
    _ = try! publisher.send(msgA1)
    _ = try! publisher.send(msgB1)
    
    // Sleep to allow messages to be processed
    Thread.sleep(forTimeInterval: 0.5)
    
    // Should receive both messages
    var receivedMessages = 0
    
    // First message
    if try subscriber.awaitMessage(timeout: 1000) {
      let msg = try subscriber.recv()!
      let val = unpack(message: msg)! as String
      #expect(val == "A-First" || val == "B-First")
      receivedMessages += 1
    } else {
      #expect(Bool(false), "Should have received first message")
    }
    
    // Second message
    if try subscriber.awaitMessage(timeout: 1000) {
      let msg = try subscriber.recv()!
      let val = unpack(message: msg)! as String
      #expect(val == "A-First" || val == "B-First")
      receivedMessages += 1
    } else {
      #expect(Bool(false), "Should have received second message")
    }
    
    #expect(receivedMessages == 2, "Should have received both messages")
    
    // Now unsubscribe from B
    try! subscriber.unsubscribe(prefix: "B")
    
    // Sleep to allow unsubscribe to take effect
    Thread.sleep(forTimeInterval: 0.5)
    
    // Send new messages
    let msgA2 = pack(value: "A-Second")!
    let msgB2 = pack(value: "B-Second")!
    
    _ = try! publisher.send(msgA2)
    _ = try! publisher.send(msgB2)
    
    // Sleep to allow messages to be processed
    Thread.sleep(forTimeInterval: 0.5)
    
    // Should receive only A message
    if try subscriber.awaitMessage(timeout: 1000) {
      let msg = try subscriber.recv()!
      let val = unpack(message: msg)! as String
      #expect(val == "A-Second", "Should only receive A-prefixed message after unsubscribe")
      
      // Should not receive B message
      let gotAnotherMessage = try subscriber.awaitMessage(timeout: 100)
      #expect(gotAnotherMessage == false, "Should not receive B-prefixed message after unsubscribe")
    } else {
      #expect(Bool(false), "Should have received A-prefixed message after unsubscribe")
    }
  }
  
  @Test func testTCPMultipleSubscriptions() throws {
    let address = "tcp://127.0.0.1:\(5000 + #line)"
    let publisher = try! ctx.bind(type: .pub, url: address)
    let subscriber = try! ctx.connect(type: .sub, url: address)
    
    // Subscribe to messages with prefixes "A" and "C"
    try! subscriber.subscribe(prefix: "A")
    try! subscriber.subscribe(prefix: "C")
    
    // Sleep to allow subscription to take effect (slow joiner syndrome)
    Thread.sleep(forTimeInterval: 0.5)
    
    // Send messages with different prefixes
    let msgA = pack(value: "A-Message")!
    let msgB = pack(value: "B-Message")!
    let msgC = pack(value: "C-Message")!
    
    _ = try! publisher.send(msgA)
    _ = try! publisher.send(msgB)
    _ = try! publisher.send(msgC)
    
    // Sleep to allow messages to be processed
    Thread.sleep(forTimeInterval: 0.5)
    
    // Should receive messages with prefixes "A" and "C"
    var receivedA = false
    var receivedC = false
    
    // Check for first message
    if try subscriber.awaitMessage(timeout: 1000) {
      let msg1 = try subscriber.recv()!
      let val1 = unpack(message: msg1)! as String
      if val1 == "A-Message" {
        receivedA = true
      } else if val1 == "C-Message" {
        receivedC = true
      } else {
        #expect(Bool(false), "Received unexpected message: \(val1)")
      }
    } else {
      #expect(Bool(false), "Should have received first message")
    }
    
    // Check for second message
    if try subscriber.awaitMessage(timeout: 1000) {
      let msg2 = try subscriber.recv()!
      let val2 = unpack(message: msg2)! as String
      if val2 == "A-Message" {
        receivedA = true
      } else if val2 == "C-Message" {
        receivedC = true
      } else {
        #expect(Bool(false), "Received unexpected message: \(val2)")
      }
    } else {
      #expect(Bool(false), "Should have received a second message")
    }
    
    #expect(receivedA && receivedC, "Should have received both A and C messages")
    
    // Should not receive message with prefix "B"
    let gotAnotherMessage = try subscriber.awaitMessage(timeout: 100)
    #expect(gotAnotherMessage == false)
  }
}
// swiftlint:enable force_try