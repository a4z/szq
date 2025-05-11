import Foundation
import ZeroMQ

/// Utility class for Z85 encoding and decoding.
///
/// Z85 is a binary-to-text encoding scheme used by ZeroMQ, particularly
/// for encoding CURVE key material.
public class Z85 {
  
  /// Encodes binary data using the Z85 encoding scheme.
  ///
  /// - Parameter data: The binary data to encode. Must be divisible by 4.
  /// - Returns: The Z85-encoded string, or nil if encoding fails.
  public static func encode(_ data: [UInt8]) -> String? {
    // Z85 encoding requires data length to be divisible by 4
    guard data.count % 4 == 0 else {
      return nil
    }
    
    let destLen = data.count * 5 / 4 + 1
    var dest = [Int8](repeating: 0, count: destLen)
    
    let result = data.withUnsafeBytes { srcBuffer in
      zmq_z85_encode(&dest, srcBuffer.bindMemory(to: UInt8.self).baseAddress, data.count)
    }
    
    // zmq_z85_encode returns nil on failure
    guard result != nil else {
      return nil
    }
    
    // Convert to UInt8 array and truncate null terminator for String creation
    let uint8Buffer = dest.map { UInt8(bitPattern: $0) }
    let nullIndex = uint8Buffer.firstIndex(of: 0) ?? dest.count
    return String(decoding: uint8Buffer[0..<nullIndex], as: UTF8.self)
  }
  
  /// Decodes a Z85-encoded string back to binary data.
  ///
  /// - Parameter string: The Z85-encoded string to decode. Length must be divisible by 5.
  /// - Returns: The decoded binary data, or nil if decoding fails.
  public static func decode(_ string: String) -> [UInt8]? {
    // Z85 decoding requires string length to be divisible by 5
    guard string.count % 5 == 0 else {
      return nil
    }
    
    let destLen = string.count * 4 / 5
    var dest = [UInt8](repeating: 0, count: destLen)
    
    guard let cString = string.cString(using: .ascii) else {
      return nil
    }
    
    let result = zmq_z85_decode(&dest, cString)
    
    // zmq_z85_decode returns nil on failure
    guard result != nil else {
      return nil
    }
    
    return dest
  }
  
  /// Generates a new CURVE key pair.
  ///
  /// - Returns: A tuple containing the Z85-encoded public and secret keys, or nil if generation fails.
  public static func generateKeyPair() -> (publicKey: String, secretKey: String)? {
    var publicKey = [Int8](repeating: 0, count: 41) // Z85-encoded key (40 chars) + null terminator
    var secretKey = [Int8](repeating: 0, count: 41) // Z85-encoded key (40 chars) + null terminator
    
    let result = zmq_curve_keypair(&publicKey, &secretKey)
    
    if result == 0 {
      // Convert to UInt8 arrays and truncate null terminators for String creation
      let publicKeyBuffer = publicKey.map { UInt8(bitPattern: $0) }
      let secretKeyBuffer = secretKey.map { UInt8(bitPattern: $0) }
      
      let publicKeyNullIndex = publicKeyBuffer.firstIndex(of: 0) ?? publicKey.count
      let secretKeyNullIndex = secretKeyBuffer.firstIndex(of: 0) ?? secretKey.count
      
      let publicKeyString = String(decoding: publicKeyBuffer[0..<publicKeyNullIndex], as: UTF8.self)
      let secretKeyString = String(decoding: secretKeyBuffer[0..<secretKeyNullIndex], as: UTF8.self)
      
      return (publicKeyString, secretKeyString)
    } else {
      return nil
    }
  }
}