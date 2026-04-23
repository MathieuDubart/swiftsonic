// MockHTTPTransport.swift — SwiftSonicTests
//
// A test double for HTTPTransport that returns pre-configured responses
// without making real network calls.
//
// Usage:
//   let mock = MockHTTPTransport()
//   mock.enqueue(fixture: "getArtists", statusCode: 200)
//   let client = SwiftSonicClient(configuration: .test, transport: mock)
//
// For retry/resilience tests, use enqueueError(_:) and responseDelay:
//   mock.enqueueError(URLError(.networkConnectionLost))
//   mock.responseDelay = 0.05   // artificial latency per response

import Foundation
@testable import SwiftSonic

/// An `HTTPTransport` implementation for use in tests.
///
/// Captures all outgoing `URLRequest`s and returns pre-configured responses.
final class MockHTTPTransport: HTTPTransport, @unchecked Sendable {

    // MARK: - Captured requests

    private(set) var capturedRequests: [URLRequest] = []

    // MARK: - Response queue

    private enum MockResponse {
        case success(Data, HTTPURLResponse)
        case failure(Error)
    }
    private var responses: [MockResponse] = []

    // MARK: - Optional artificial latency

    /// Delay (in seconds) added before returning each response.
    ///
    /// Useful for testing cancellation and timeout behaviour.
    var responseDelay: TimeInterval = 0

    // MARK: - Configuration

    /// Enqueues a success response to be returned for the next request.
    ///
    /// Responses are returned in FIFO order.
    func enqueue(_ data: Data, statusCode: Int = 200) {
        let response = HTTPURLResponse(
            url: URL(string: "https://test.example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        responses.append(.success(data, response))
    }

    /// Enqueues a success response with custom HTTP headers.
    func enqueue(_ data: Data, statusCode: Int, headers: [String: String]) {
        let response = HTTPURLResponse(
            url: URL(string: "https://test.example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )!
        responses.append(.success(data, response))
    }

    /// Enqueues a fixture JSON file as the response for the next request.
    func enqueue(fixture name: String, statusCode: Int = 200) {
        let data = FixtureLoader.load(name)
        enqueue(data, statusCode: statusCode)
    }

    /// Enqueues an error to be thrown for the next request.
    ///
    /// Use this to simulate network failures, timeouts, and other transport errors.
    func enqueueError(_ error: Error) {
        responses.append(.failure(error))
    }

    // MARK: - HTTPTransport

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        capturedRequests.append(request)

        if responseDelay > 0 {
            try await Task.sleep(for: .seconds(responseDelay))
        }

        guard !responses.isEmpty else {
            throw URLError(.badServerResponse)
        }

        switch responses.removeFirst() {
        case .success(let data, let response):
            return (data, response)
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Helpers

    var lastRequest: URLRequest? { capturedRequests.last }

    func queryItem(named name: String, in request: URLRequest? = nil) -> String? {
        let req = request ?? lastRequest
        guard let url = req?.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }
        return components.queryItems?.first(where: { $0.name == name })?.value
    }
}
