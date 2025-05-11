// swiftlint:disable force_try
import Testing
import XCTest

@testable import szq

@Suite("SocketOptionsTest")
struct SocketOptionsTestSuite {
  
  let ctx = Context()
  
  @Test func testHighWaterMarkOptions() throws {
    // Create a socket to test options
    let socket = try ctx.connect(type: .push, url: "inproc://hwm-test")
    
    // Test send high water mark
    let sendHwm: Int32 = 2000
    try socket.setSendHighWaterMark(sendHwm)
    let retrievedSendHwm = try socket.getSendHighWaterMark()
    #expect(retrievedSendHwm == sendHwm, "Send high water mark should match set value")
    
    // Test receive high water mark
    let receiveHwm: Int32 = 3000
    try socket.setReceiveHighWaterMark(receiveHwm)
    let retrievedReceiveHwm = try socket.getReceiveHighWaterMark()
    #expect(retrievedReceiveHwm == receiveHwm, "Receive high water mark should match set value")
  }
  
  @Test func testTimeoutOptions() throws {
    // Create a socket to test options
    let socket = try ctx.connect(type: .req, url: "inproc://timeout-test")
    
    // Test send timeout
    let sendTimeout: Int32 = 1500
    try socket.setSendTimeout(milliseconds: sendTimeout)
    let retrievedSendTimeout = try socket.getSendTimeout()
    #expect(retrievedSendTimeout == sendTimeout, "Send timeout should match set value")
    
    // Test receive timeout
    let receiveTimeout: Int32 = 2500
    try socket.setReceiveTimeout(milliseconds: receiveTimeout)
    let retrievedReceiveTimeout = try socket.getReceiveTimeout()
    #expect(retrievedReceiveTimeout == receiveTimeout, "Receive timeout should match set value")
  }
  
  @Test func testReconnectionOptions() throws {
    // Create a socket to test options
    let socket = try ctx.connect(type: .dealer, url: "inproc://reconnect-test")
    
    // Test reconnect interval
    let reconnectInterval: Int32 = 200
    try socket.setReconnectInterval(milliseconds: reconnectInterval)
    let retrievedReconnectInterval = try socket.getReconnectInterval()
    #expect(retrievedReconnectInterval == reconnectInterval, "Reconnect interval should match set value")
    
    // Test max reconnect interval
    let maxReconnectInterval: Int32 = 5000
    try socket.setMaxReconnectInterval(milliseconds: maxReconnectInterval)
    let retrievedMaxReconnectInterval = try socket.getMaxReconnectInterval()
    #expect(retrievedMaxReconnectInterval == maxReconnectInterval, "Max reconnect interval should match set value")
  }
  
  @Test func testTCPOptions() throws {
    // Create a socket to test options
    let socket = try ctx.connect(type: .pull, url: "inproc://tcp-test")
    
    // Test TCP keep-alive
    let keepAlive: Int32 = 1
    try socket.setTCPKeepAlive(keepAlive)
    let retrievedKeepAlive = try socket.getTCPKeepAlive()
    #expect(retrievedKeepAlive == keepAlive, "TCP keep-alive should match set value")
  }
  
  @Test func testMessageSizeOption() throws {
    // Create a socket to test options
    let socket = try ctx.connect(type: .pub, url: "inproc://msgsize-test")
    
    // Test max message size
    let maxMsgSize: Int64 = 8192
    try socket.setMaxMessageSize(maxMsgSize)
    let retrievedMaxMsgSize = try socket.getMaxMessageSize()
    #expect(retrievedMaxMsgSize == maxMsgSize, "Max message size should match set value")
  }
  
  @Test func testMulticastOptions() throws {
    // Create a socket to test options
    let socket = try ctx.connect(type: .pub, url: "inproc://multicast-test")
    
    // Test multicast hops
    let multicastHops: Int32 = 5
    try socket.setMulticastHops(multicastHops)
    let retrievedMulticastHops = try socket.getMulticastHops()
    #expect(retrievedMulticastHops == multicastHops, "Multicast hops should match set value")
  }
  
  @Test func testBacklogOption() throws {
    // Create a socket to test options
    let socket = try ctx.connect(type: .router, url: "inproc://backlog-test")
    
    // Test backlog value
    let backlog: Int32 = 200
    try socket.setBacklog(backlog)
    let retrievedBacklog = try socket.getBacklog()
    #expect(retrievedBacklog == backlog, "Backlog should match set value")
  }
  
  @Test func testRouterOptions() throws {
    // Create a ROUTER socket to test options
    let socket = try ctx.connect(type: .router, url: "inproc://router-options-test")
    
    // Test router mandatory option
    do {
      try socket.setRouterMandatory(1)
      // No exception means it worked
    } catch {
      #expect(Bool(false), "Setting router mandatory should not throw")
    }
    
    // Test router handover option
    do {
      try socket.setRouterHandover(1)
      // No exception means it worked
    } catch {
      #expect(Bool(false), "Setting router handover should not throw")
    }
  }
  
  @Test func testPublisherOptions() throws {
    // Create a PUB socket to test options
    let socket = try ctx.connect(type: .pub, url: "inproc://pub-options-test")
    
    // Test conflate option
    let conflate: Int32 = 1
    try socket.setConflate(conflate)
    let retrievedConflate = try socket.getConflate()
    #expect(retrievedConflate == conflate, "Conflate should match set value")
  }
  
  @Test func testIdentityOption() throws {
    // Create a DEALER socket to test identity
    let socket = try ctx.connect(type: .dealer, url: "inproc://identity-test")
    
    // Set and get identity
    let identityStr = "MyIdentity-\(#line)"
    try socket.setIdentity(identityStr)
    
    let identity = try socket.getIdentity()
    
    // Convert the identity message to a string
    var buffer = [UInt8](repeating: 0, count: identity.size)
    if let data = identity.data {
      memcpy(&buffer, data, identity.size)
    }
    let retrievedIdentity = String(bytes: buffer, encoding: .utf8)
    
    #expect(retrievedIdentity == identityStr, "Identity should match set value")
  }
  
  @Test func testLingerOption() throws {
    // Create a socket to test linger
    let socket = try ctx.connect(type: .pull, url: "inproc://linger-test")
    
    // Test linger option
    let linger: Int32 = 500
    try socket.linger(milliseconds: linger)
    let retrievedLinger = try socket.linger()
    #expect(retrievedLinger == linger, "Linger should match set value")
  }
  
  @Test func testProxyOption() throws {
    // Create a socket to test proxy settings
    let socket = try ctx.connect(type: .req, url: "inproc://proxy-test")
    
    // Test proxy address
    let proxyAddress = "tcp://proxy.example.com:1080"
    try socket.setProxy(proxyAddress)
    let retrievedProxy = try socket.getProxy()
    #expect(retrievedProxy == proxyAddress, "Proxy address should match set value")
    
    // Test SOCKS5 credentials
    let username = "test-user"
    let password = "test-password"
    try socket.setSocks5Username(username)
    try socket.setSocks5Password(password)
    
    // These don't have getter methods in ZeroMQ, so we just check that setting doesn't throw
  }
}
// swiftlint:enable force_try