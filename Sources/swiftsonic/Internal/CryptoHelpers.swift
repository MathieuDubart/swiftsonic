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
/// Uses `SystemRandomNumberGenerator` explicitly — this generator is backed by
/// the OS CSPRNG (`SecRandomCopyBytes` on Apple platforms) and is suitable for
/// security-sensitive use cases.
///
/// - Parameter length: Number of characters. Defaults to 16 (~95 bits of entropy
///   from a 62-character alphabet), which exceeds the 128-bit security recommendation
///   when paired with MD5 token auth.
/// - Returns: A random string suitable for use as a Subsonic auth salt.
func randomSalt(length: Int = 16) -> String {
    let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    var rng = SystemRandomNumberGenerator()
    var result = ""
    result.reserveCapacity(length)
    for _ in 0 ..< length {
        let index = alphabet.index(
            alphabet.startIndex,
            offsetBy: Int.random(in: 0 ..< alphabet.count, using: &rng)
        )
        result.append(alphabet[index])
    }
    return result
}
