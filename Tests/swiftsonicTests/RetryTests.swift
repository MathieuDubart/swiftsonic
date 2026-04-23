// RetryTests.swift — SwiftSonicTests
//
// Behavioural tests for the automatic retry mechanism in SwiftSonicClient.
//
// What is tested:
//   - Transient errors (network timeouts, 5xx, 429) are retried up to maxAttempts
//   - Non-transient errors (Subsonic API, 4xx, decoding) are never retried
//   - The 429 Retry-After header is parsed and surfaced on the thrown error
//   - Task cancellation during the retry sleep propagates CancellationError
//
// All tests use a zero-delay retry policy so the suite runs in milliseconds.

import Testing
import Foundation
@testable import SwiftSonic

@Suite("Retry behaviour")
struct RetryTests {

    // MARK: - Helpers

    /// A retry policy with zero base delay and no jitter for fast, deterministic tests.
    private func fastPolicy(maxAttempts: Int = 3) -> RetryPolicy {
        RetryPolicy(maxAttempts: maxAttempts, baseDelay: 0, jitterFactor: 0)
    }

    // MARK: - Transient error retry

    @Test("retries on transient network error and eventually succeeds")
    func retriesOnTransientNetworkError() async throws {
        let mock = MockHTTPTransport()
        mock.enqueueError(URLError(.networkConnectionLost))
        mock.enqueueError(URLError(.networkConnectionLost))
        mock.enqueue(fixture: "ping_ok") // succeeds on the 3rd attempt

        let client = SwiftSonicClient(configuration: .test, transport: mock, retryPolicy: fastPolicy())
        try await client.ping()

        #expect(mock.capturedRequests.count == 3)
    }

    @Test("retries on HTTP 5xx and eventually succeeds")
    func retriesOnHTTP5xx() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(Data(), statusCode: 503)
        mock.enqueue(Data(), statusCode: 500)
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock, retryPolicy: fastPolicy())
        try await client.ping()

        #expect(mock.capturedRequests.count == 3)
    }

    @Test("retries on HTTP 429 and eventually succeeds")
    func retriesOn429() async throws {
        let mock = MockHTTPTransport()
        // No Retry-After header → delay falls back to retryPolicy.delay (0s)
        mock.enqueue(Data(), statusCode: 429, headers: [:])
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock, retryPolicy: fastPolicy())
        try await client.ping()

        #expect(mock.capturedRequests.count == 2)
    }

    // MARK: - Non-transient errors are not retried

    @Test("does not retry on Subsonic API error")
    func doesNotRetryOnAPIError() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_error_40")

        let client = SwiftSonicClient(configuration: .test, transport: mock, retryPolicy: fastPolicy())

        await #expect(throws: SwiftSonicError.self) {
            try await client.ping()
        }
        #expect(mock.capturedRequests.count == 1)
    }

    @Test("does not retry on HTTP 4xx (non-429)")
    func doesNotRetryOnHTTP4xx() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(Data(), statusCode: 403)

        let client = SwiftSonicClient(configuration: .test, transport: mock, retryPolicy: fastPolicy())

        await #expect(throws: SwiftSonicError.self) {
            try await client.ping()
        }
        #expect(mock.capturedRequests.count == 1)
    }

    @Test("does not retry on JSON decoding error")
    func doesNotRetryOnDecodingError() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue("INVALID JSON".data(using: .utf8)!, statusCode: 200)

        let client = SwiftSonicClient(configuration: .test, transport: mock, retryPolicy: fastPolicy())

        await #expect(throws: SwiftSonicError.self) {
            try await client.ping()
        }
        #expect(mock.capturedRequests.count == 1)
    }

    // MARK: - maxAttempts enforcement

    @Test("stops retrying after exhausting maxAttempts")
    func stopsAtMaxAttempts() async throws {
        let mock = MockHTTPTransport()
        mock.enqueueError(URLError(.timedOut))
        mock.enqueueError(URLError(.timedOut))
        mock.enqueueError(URLError(.timedOut))

        let client = SwiftSonicClient(configuration: .test, transport: mock, retryPolicy: fastPolicy(maxAttempts: 3))

        await #expect(throws: SwiftSonicError.self) {
            try await client.ping()
        }
        #expect(mock.capturedRequests.count == 3)
    }

    @Test("RetryPolicy.none makes exactly one attempt")
    func noPolicyMakesOneAttempt() async throws {
        let mock = MockHTTPTransport()
        mock.enqueueError(URLError(.timedOut))

        let client = SwiftSonicClient(configuration: .test, transport: mock, retryPolicy: .none)

        await #expect(throws: SwiftSonicError.self) {
            try await client.ping()
        }
        #expect(mock.capturedRequests.count == 1)
    }

    // MARK: - 429 Retry-After header

    @Test("Retry-After header value is parsed and attached to the thrown error")
    func retryAfterIsParsed() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(Data(), statusCode: 429, headers: ["Retry-After": "5"])

        // .none policy so the error is surfaced immediately without waiting
        let client = SwiftSonicClient(configuration: .test, transport: mock, retryPolicy: .none)

        do {
            try await client.ping()
            Issue.record("Expected SwiftSonicError.rateLimited to be thrown")
        } catch SwiftSonicError.rateLimited(let retryAfter, _, _) {
            #expect(retryAfter == 5.0)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Cancellation

    @Test("cancellation during retry sleep propagates CancellationError")
    func cancellationDuringRetrySleep() async throws {
        let mock = MockHTTPTransport()
        mock.enqueueError(URLError(.networkConnectionLost))

        // A 60-second delay ensures the task is still sleeping when we cancel it.
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 60, jitterFactor: 0)
        let client = SwiftSonicClient(configuration: .test, transport: mock, retryPolicy: policy)

        let task = Task {
            try await client.ping()
        }

        // Give the first attempt time to fail and enter the retry sleep (takes microseconds).
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected CancellationError to be thrown")
        } catch is CancellationError {
            #expect(mock.capturedRequests.count == 1)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
