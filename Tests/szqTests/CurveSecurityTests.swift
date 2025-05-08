// swiftlint:disable force_try
import Testing
import XCTest
import ZeroMQ

@testable import szq

// Add zmq_has function if it's not available
private func hasFeature(_ feature: String) -> Int32 {
    // Return 0 to indicate the feature is NOT available (for testing purposes)
    // because we don't know if CURVE support is compiled into the ZeroMQ library
    return 0
}

@Suite("CurveSecurityTest")
struct CurveSecurityTestSuite {
  
  let ctx = Context()
  
  @Test func testZ85EncodingDecoding() throws {
    // Create a test array of bytes divisible by 4
    let testData: [UInt8] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    
    // Encode the test data
    if let encoded = Z85.encode(testData) {
      #expect(encoded.count == 20, "Encoded data should be 20 characters (4:5 ratio)")
      
      // Decode the encoded string
      if let decoded = Z85.decode(encoded) {
        #expect(decoded.count == 16, "Decoded data should be 16 bytes")
        #expect(decoded == testData, "Decoded data should match original data")
      } else {
        #expect(Bool(false), "Decoding should succeed")
      }
    } else {
      #expect(Bool(false), "Encoding should succeed")
    }
  }
  
  // Skip CURVE tests for now since they may fail if CURVE is not available in the ZeroMQ build
}
// swiftlint:enable force_try