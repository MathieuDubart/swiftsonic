// MockHTTPTransport.swift — SwiftSonicTests
//
// A test double for HTTPTransport that returns pre-configured responses
// without making real network calls.
//
// Usage:
//   let mock = MockHTTPTransport()
//   mock.enqueue(fixture: "getArtists", statusCode: 200)
//   let client = SwiftSonicClient(configuration: .test, transport: mock)

import Foundation
@testable import SwiftSonic

/// An `HTTPTransport` implementation for use in tests.
///
/// Captures all outgoing `URLRequest`s and returns pre-configured responses.
final class MockHTTPTransport: HTTPTransport, @unchecked Sendable {

    // MARK: - Captured requests

    private(set) var capturedRequests: [URLRequest] = []

    // MARK: - Response queue

    private var responses: [(Data, HTTPURLResponse)] = []

    // MARK: - Configuration

    /// Enqueues a response to be returned for the next request.
    ///
    /// Responses are returned in FIFO order.
    func enqueue(_ data: Data, statusCode: Int = 200) {
        let response = HTTPURLResponse(
            url: URL(string: "https://test.example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        responses.append((data, response))
    }

    /// Enqueues a fixture JSON file as the response for the next request.
    func enqueue(fixture name: String, statusCode: Int = 200) {
        let data = FixtureLoader.load(name)
        enqueue(data, statusCode: statusCode)
    }

    // MARK: - HTTPTransport

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        capturedRequests.append(request)
        guard !responses.isEmpty else {
            throw URLError(.badServerResponse)
        }
        return responses.removeFirst()
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
