// RetryPolicy.swift — SwiftSonic
//
// Configures the automatic retry behaviour of SwiftSonicClient.
// Only transient errors are retried (network timeouts, 5xx, 429).
// Non-transient errors (auth failures, decoding errors, 4xx) are never retried.

import Foundation

/// Configures how ``SwiftSonicClient`` retries failed requests.
///
/// SwiftSonic retries only transient errors: network timeouts, connection
/// resets, HTTP 5xx, and HTTP 429 (rate-limited). Authentication failures,
/// decoding errors, and other 4xx responses are never retried.
///
/// ## Presets
///
/// ```swift
/// // Default: 3 attempts, 0.5s → 1s → 2s (±20% jitter)
/// RetryPolicy.default
///
/// // Disable retries completely
/// RetryPolicy.none
///
/// // Custom
/// RetryPolicy(maxAttempts: 5, baseDelay: 1.0, multiplier: 2.0, jitterFactor: 0.1)
/// ```
///
/// ## Injecting a policy
///
/// Pass the policy to ``SwiftSonicClient`` at initialisation time:
/// ```swift
/// let client = SwiftSonicClient(
///     configuration: config,
///     retryPolicy: .default
/// )
/// ```
public struct RetryPolicy: Sendable {

    // MARK: - Properties

    /// Total number of attempts, including the initial one.
    ///
    /// `1` disables retries. `3` means one initial attempt plus two retries.
    public let maxAttempts: Int

    /// Delay before the first retry, in seconds.
    public let baseDelay: TimeInterval

    /// Multiplicative factor applied to the delay after each failed attempt.
    ///
    /// A value of `2.0` doubles the delay each time: 0.5s → 1s → 2s.
    public let multiplier: Double

    /// Fractional random jitter applied to each computed delay.
    ///
    /// `0.2` varies the delay by ±20%. Set to `0` for deterministic delays in tests.
    public let jitterFactor: Double

    // MARK: - Presets

    /// Three attempts with exponential backoff and ±20% jitter.
    ///
    /// Delays: ~500ms → ~1s → ~2s.
    public static let `default` = RetryPolicy(
        maxAttempts: 3,
        baseDelay: 0.5,
        multiplier: 2.0,
        jitterFactor: 0.2
    )

    /// Disables retries. Every request is attempted exactly once.
    public static let none = RetryPolicy(
        maxAttempts: 1,
        baseDelay: 0,
        multiplier: 1,
        jitterFactor: 0
    )

    // MARK: - Initializer

    /// Creates a custom retry policy.
    ///
    /// - Parameters:
    ///   - maxAttempts: Total number of attempts (minimum 1).
    ///   - baseDelay: Delay before the first retry, in seconds. Defaults to `0.5`.
    ///   - multiplier: Backoff multiplier. Must be ≥ 1. Defaults to `2.0`.
    ///   - jitterFactor: Jitter as a fraction of the computed delay (0–1). Defaults to `0.2`.
    public init(
        maxAttempts: Int,
        baseDelay: TimeInterval = 0.5,
        multiplier: Double = 2.0,
        jitterFactor: Double = 0.2
    ) {
        self.maxAttempts  = max(1, maxAttempts)
        self.baseDelay    = max(0, baseDelay)
        self.multiplier   = max(1, multiplier)
        self.jitterFactor = min(1, max(0, jitterFactor))
    }

    // MARK: - Delay calculation

    /// Returns the delay (in seconds) to wait before the given attempt index.
    ///
    /// - Parameter attempt: Zero-based index of the *completed* attempt (0 = before first retry).
    /// - Returns: A non-negative delay value, including jitter.
    public func delay(for attempt: Int) -> TimeInterval {
        guard maxAttempts > 1, attempt >= 0 else { return 0 }
        let base   = baseDelay * pow(multiplier, Double(attempt))
        let jitter = base * jitterFactor * Double.random(in: -1...1)
        return max(0, base + jitter)
    }
}
