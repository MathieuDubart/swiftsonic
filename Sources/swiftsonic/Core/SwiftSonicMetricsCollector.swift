// SwiftSonicMetricsCollector.swift — SwiftSonic
//
// Opt-in hook for request metrics. Inject a collector into SwiftSonicClient.init
// to integrate with Datadog, Sentry, custom logging, or any other backend.

import Foundation

// MARK: - Event type

/// An event emitted by ``SwiftSonicClient`` during the lifecycle of a request.
///
/// Collect these events by implementing ``SwiftSonicMetricsCollector`` and passing
/// it to ``SwiftSonicClient/init(configuration:transport:retryPolicy:metricsCollector:logSubsystem:)``.
public enum SwiftSonicRequestEvent: Sendable {
    /// A request attempt has started.
    case started(endpoint: String, attempt: Int)

    /// A request attempt completed successfully.
    case succeeded(endpoint: String, attempt: Int, duration: TimeInterval)

    /// A request attempt failed.
    ///
    /// This event is emitted for every failed attempt, including those that will be retried.
    case failed(endpoint: String, attempt: Int, error: SwiftSonicError, duration: TimeInterval)

    /// A retry has been scheduled after a failed attempt.
    case retryScheduled(endpoint: String, attempt: Int, delay: TimeInterval)
}

// MARK: - Collector protocol

/// A hook for collecting per-request metrics from ``SwiftSonicClient``.
///
/// Implement this protocol to integrate with your observability stack:
///
/// ```swift
/// final class MyCollector: SwiftSonicMetricsCollector, @unchecked Sendable {
///     func record(_ event: SwiftSonicRequestEvent) {
///         switch event {
///         case .failed(let ep, _, let err, let ms):
///             MyMonitoring.recordError(endpoint: ep, error: err, duration: ms)
///         case .retryScheduled(let ep, let attempt, let delay):
///             MyMonitoring.recordRetry(endpoint: ep, attempt: attempt, delay: delay)
///         default:
///             break
///         }
///     }
/// }
///
/// let client = SwiftSonicClient(
///     configuration: config,
///     metricsCollector: MyCollector()
/// )
/// ```
///
/// > Important: `record(_:)` is called **synchronously** from the client's actor context.
/// > Do not block. Dispatch heavy work to your own executor.
public protocol SwiftSonicMetricsCollector: Sendable {
    /// Records a request lifecycle event.
    func record(_ event: SwiftSonicRequestEvent)
}
