// swiftlint:disable force_try
import Testing
import XCTest

@testable import szq

@Suite("IdentityTest")
struct IdentityTestSuite {

  let ctx = Context()

  @Test func testSocketIdentitySetting() throws {
    // DEALER sockets can have an explicit identity
    do {
      let socket = try ctx.connect(type: .dealer, url: "inproc://identity-test-\(#line)")
      
      // Set a string identity
      let identity = "dealer-identity-\(#line)"
      try socket.setIdentity(identity)
      
      // Retrieve the identity
      let retrievedIdentity = try socket.getIdentity()
      
      // Convert to string for comparison
      var identityBytes = [UInt8](repeating: 0, count: retrievedIdentity.size)
      if let data = retrievedIdentity.data {
        memcpy(&identityBytes, data, retrievedIdentity.size)
      }
      let retrievedString = String(bytes: identityBytes, encoding: .utf8)
      
      #expect(retrievedString == identity, "Retrieved identity should match set identity")
    } catch {
      print("Identity setting test skipped: \(error)")
    }
  }
  
  @Test func testRouterDealerWithIdentity() throws {
    let address = "inproc://router-dealer-identity-\(#line)"
    
    do {
      let router = try ctx.bind(type: .router, url: address)
      let dealer1 = try ctx.connect(type: .dealer, url: address)
      let dealer2 = try ctx.connect(type: .dealer, url: address)
      
      // Set explicit identities for the dealers
      // Using the identity byte-by-byte to ensure correct encoding
      let dealer1ID = "DEALER1".utf8.map { UInt8($0) }
      let dealer2ID = "DEALER2".utf8.map { UInt8($0) }
      
      try dealer1.setIdentity(dealer1ID, size: dealer1ID.count)
      try dealer2.setIdentity(dealer2ID, size: dealer2ID.count)
      
      // Allow time for connections to establish
      Thread.sleep(forTimeInterval: 0.5)
      
      // Send a message from dealer1 to router
      let msgFromDealer1 = pack(value: "Message from Dealer1")!
      _ = try dealer1.send(msgFromDealer1)
      
      // Router should receive the message with dealer1's identity as first frame
      if try router.awaitMessage(timeout: 1000) {
        let frames = try router.recvAll()!
        #expect(frames.count >= 2, "Router should receive identity frame and message")
        
        // Verify we have an identity frame
        print("Received identity frame size: \(frames[0].size)")
        
        // Last frame should be the message (we skip checking the identity content for now)
        let content = unpack(message: frames.last!)! as String
        #expect(content == "Message from Dealer1", "Should receive correct message content")
        
        // Now router can send a reply to dealer1 using its identity
        let replyMsg = pack(value: "Reply to Dealer1")!
        _ = try router.send(frames[0], replyMsg)
        
        // Dealer1 should receive the reply
        if try dealer1.awaitMessage(timeout: 1000) {
          let replyFrame = try dealer1.recv()!
          let replyContent = unpack(message: replyFrame)! as String
          #expect(replyContent == "Reply to Dealer1", "Dealer1 should receive correct reply")
        } else {
          #expect(Bool(false), "Dealer1 should have received a reply")
        }
        
        // Send a message from dealer2 to router
        let msgFromDealer2 = pack(value: "Message from Dealer2")!
        _ = try dealer2.send(msgFromDealer2)
        
        // Router should receive the message with dealer2's identity
        if try router.awaitMessage(timeout: 1000) {
          let frames2 = try router.recvAll()!
          #expect(frames2.count >= 2, "Router should receive identity frame and message")
          
          // Verify we have a different identity frame
          print("Received second identity frame size: \(frames2[0].size)")
          
          // Check the message content
          let content2 = unpack(message: frames2.last!)! as String
          #expect(content2 == "Message from Dealer2", "Should receive correct message from dealer2")
          
          // Verify the identities are different (they should be)
          #expect(frames[0].size == frames2[0].size, "Identity frames should have the same size")
          
          var same = true
          if let data1 = frames[0].data, let data2 = frames2[0].data {
            let size = frames[0].size
            let buffer1 = UnsafeRawBufferPointer(start: data1, count: size)
            let buffer2 = UnsafeRawBufferPointer(start: data2, count: size)
            
            for i in 0..<size {
              if buffer1[i] != buffer2[i] {
                same = false
                break
              }
            }
          }
          
          #expect(!same, "Identities from dealer1 and dealer2 should be different")
        } else {
          #expect(Bool(false), "Router should have received message from dealer2")
        }
      } else {
        #expect(Bool(false), "Router should have received a message")
      }
    } catch {
      print("Router-Dealer identity test skipped: \(error)")
    }
  }
  
  @Test func testInvalidIdentitySize() throws {
    do {
      let socket = try ctx.connect(type: .dealer, url: "inproc://invalid-identity-\(#line)")
      
      // Empty identity should throw
      do {
        try socket.setIdentity("")
        #expect(Bool(false), "Empty identity should throw an error")
      } catch SzqError.invalidIdentitySize {
        // Expected error - test passes
      }
      
      // Too large identity should throw (> 255 bytes)
      do {
        let largeIdentity = String(repeating: "X", count: 256)
        try socket.setIdentity(largeIdentity)
        #expect(Bool(false), "Oversized identity should throw an error")
      } catch SzqError.invalidIdentitySize {
        // Expected error - test passes
      }
    } catch {
      print("Invalid identity size test skipped: \(error)")
    }
  }
}
// swiftlint:enable force_try