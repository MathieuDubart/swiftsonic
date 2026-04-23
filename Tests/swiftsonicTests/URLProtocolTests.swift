// URLProtocolTests.swift — SwiftSonicTests
//
// Full-stack tests that exercise the complete pipeline:
//   SwiftSonicClient → URLSessionTransport → URLSession → MockURLProtocol
//
// These complement the MockHTTPTransport-based tests by routing requests through
// a real URLSession, verifying that URLSessionTransport and the client work correctly
// together end-to-end (error wrapping, timeout propagation, retry via real transport).

import Testing
import Foundation
@testable import SwiftSonic

// .serialized is required because MockURLProtocol.handler is static mutable state.
@Suite("URLSessionTransport full-stack", .serialized)
struct URLProtocolTests {

    // MARK: - Helpers

    /// Creates a SwiftSonicClient whose URLSession is intercepted by MockURLProtocol.
    private func makeClient(
        configuration: ServerConfiguration = .test,
        retryPolicy: RetryPolicy = .none
    ) -> SwiftSonicClient {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [MockURLProtocol.self]
        let transport = URLSessionTransport(configuration: sessionConfig)
        return SwiftSonicClient(
            configuration: configuration,
            transport: transport,
            retryPolicy: retryPolicy
        )
    }

    // MARK: - Success path

    @Test("URLSessionTransport delivers a successful response end-to-end")
    func deliversSuccessResponse() async throws {
        let responseData = FixtureLoader.load("ping_ok")
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (responseData, response)
        }

        let client = makeClient()
        try await client.ping()  // should not throw
    }

    // MARK: - Error wrapping

    @Test("URLError from URLSession is wrapped in SwiftSonicError.network")
    func wrapsURLError() async throws {
        MockURLProtocol.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let client = makeClient()

        do {
            try await client.ping()
            Issue.record("Expected SwiftSonicError.network to be thrown")
        } catch SwiftSonicError.network(let urlError) {
            #expect(urlError.code == .notConnectedToInternet)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Retry through real URLSession

    @Test("HTTP 5xx through URLSession triggers retry and succeeds on second attempt")
    func http5xxTriggersRetry() async throws {
        let successData = FixtureLoader.load("ping_ok")
        var callCount = 0

        MockURLProtocol.handler = { request in
            callCount += 1
            let statusCode = callCount == 1 ? 503 : 200
            let body = callCount == 1 ? Data() : successData
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (body, response)
        }

        let client = makeClient(
            retryPolicy: RetryPolicy(maxAttempts: 2, baseDelay: 0, jitterFactor: 0)
        )
        try await client.ping()
        #expect(callCount == 2)
    }

    // MARK: - Timeout

    @Test("URLRequest.timeoutInterval is set to configuration.requestTimeout")
    func timeoutIntervalIsSetOnRequest() async throws {
        let successData = FixtureLoader.load("ping_ok")
        var capturedTimeout: TimeInterval = 0

        MockURLProtocol.handler = { request in
            capturedTimeout = request.timeoutInterval
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (successData, response)
        }

        let config = ServerConfiguration(
            serverURL: URL(string: "https://test.example.com")!,
            username: "u",
            password: "p",
            requestTimeout: 13
        )
        let client = makeClient(configuration: config)
        try await client.ping()

        #expect(capturedTimeout == 13)
    }
}
