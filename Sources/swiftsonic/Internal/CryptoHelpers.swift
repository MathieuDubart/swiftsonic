// CryptoHelpers.swift — SwiftSonic (Internal)
//
// Provides MD5 hashing (via CryptoKit.Insecure.MD5) and random salt generation
// used exclusively for Subsonic token authentication.
//
// This file is intentionally internal — callers never interact with raw tokens.

import CryptoKit
import Foundation

// MARK: - MD5 token computation

/// Computes the Subsonic authentication token: `MD5(password + salt)` as a lowercase hex string.
///
/// - Parameters:
///   - password: The user's plaintext password.
///   - salt: A random alphanumeric string.
/// - Returns: Lowercase hex-encoded MD5 digest.
func subsonicToken(password: String, salt: String) -> String {
    let input = password + salt
    let data = Data(input.utf8)
    let digest = Insecure.MD5.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
}

// MARK: - Salt generation

/// Generates a cryptographically random alphanumeric salt string.
///
/// - Parameter length: Number of characters. Defaults to 10.
/// - Returns: A random string suitable for use as a Subsonic auth salt.
func randomSalt(length: Int = 10) -> String {
    let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    var result = ""
    result.reserveCapacity(length)
    for _ in 0 ..< length {
        // SystemRandomNumberGenerator is cryptographically secure on Apple platforms
        let index = alphabet.index(
            alphabet.startIndex,
            offsetBy: Int.random(in: 0 ..< alphabet.count)
        )
        result.append(alphabet[index])
    }
    return result
}
