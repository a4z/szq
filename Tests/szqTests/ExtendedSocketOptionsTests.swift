// swiftlint:disable force_try
import Testing
import XCTest

@testable import szq

@Suite("ExtendedSocketOptionsTest")
struct ExtendedSocketOptionsTestSuite {
  
  let ctx = Context()
  
  @Test func testIPVersionOptions() throws {
    // Create a socket to test options
    let socket = try ctx.connect(type: .push, url: "inproc://ipversion-test")
    
    // Test IPv6 option
    let ipv6Value: Int32 = 1
    try socket.setIPv6(ipv6Value)
    let retrievedIPv6 = try socket.getIPv6()
    #expect(retrievedIPv6 == ipv6Value, "IPv6 setting should match set value")
    
    // Test IPv4Only option
    let ipv4OnlyValue: Int32 = 0
    try socket.setIPv4Only(ipv4OnlyValue)
    let retrievedIPv4Only = try socket.getIPv4Only()
    #expect(retrievedIPv4Only == ipv4OnlyValue, "IPv4Only setting should match set value")
  }
  
  @Test func testConnectionOptions() throws {
    // Create a socket to test options
    let socket = try ctx.bind(type: .push, url: "inproc://connection-test")
    
    // Test last endpoint
    let lastEndpoint = try socket.getLastEndpoint()
    #expect(lastEndpoint == "inproc://connection-test", "Last endpoint should match the bound URL")
    
    // Test handshake interval
    let handshakeInterval: Int32 = 5000
    try socket.setHandshakeInterval(milliseconds: handshakeInterval)
    let retrievedHandshakeInterval = try socket.getHandshakeInterval()
    #expect(retrievedHandshakeInterval == handshakeInterval, "Handshake interval should match set value")
    
    // Test immediate option
    let immediateValue: Int32 = 1
    try socket.setImmediate(immediateValue)
    let retrievedImmediate = try socket.getImmediate()
    #expect(retrievedImmediate == immediateValue, "Immediate setting should match set value")
  }
  
  @Test func testSocketInformation() throws {
    // Create a socket to test options
    let socket = try ctx.connect(type: .push, url: "inproc://socketinfo-test")
    
    // Test socket type retrieval
    let socketType = try socket.getType()
    #expect(socketType == .push, "Socket type should be .push")
    
    // Test events retrieval
    let events = try socket.getEvents()
    // We can't predict the exact events, but we can verify it's a valid bitmask
    #expect(events >= 0, "Events should be a valid bitmask")
  }
  
  @Test func testMulticastRateOptions() throws {
    // Create a socket to test options
    let socket = try ctx.connect(type: .pub, url: "inproc://multicast-rate-test")
    
    // Test multicast rate
    let rate: Int32 = 200
    try socket.setMulticastRate(rate)
    let retrievedRate = try socket.getMulticastRate()
    #expect(retrievedRate == rate, "Multicast rate should match set value")
    
    // Test multicast recovery interval
    let recoveryInterval: Int32 = 15000
    try socket.setMulticastRecoveryInterval(milliseconds: recoveryInterval)
    let retrievedRecoveryInterval = try socket.getMulticastRecoveryInterval()
    #expect(retrievedRecoveryInterval == recoveryInterval, "Multicast recovery interval should match set value")
  }
  
  @Test func testThreadAffinityOption() throws {
    // Create a socket to test options
    let socket = try ctx.connect(type: .req, url: "inproc://affinity-test")
    
    // Test thread affinity
    let affinity: UInt64 = 3 // Bind to I/O threads 0 and 1
    try socket.setAffinity(affinity)
    let retrievedAffinity = try socket.getAffinity()
    #expect(retrievedAffinity == affinity, "Thread affinity should match set value")
  }
}
// swiftlint:enable force_try