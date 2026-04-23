// MockURLProtocol.swift — SwiftSonicTests
//
// A URLProtocol subclass for full-stack testing: intercepts requests made by a real
// URLSession so you can test the complete SwiftSonicClient → URLSessionTransport → URLSession
// pipeline without hitting the network.
//
// Usage:
//   MockURLProtocol.handler = { request in
//       let response = HTTPURLResponse(url: request.url!, statusCode: 200, ...)!
//       return (FixtureLoader.load("ping_ok"), response)
//   }
//   let cfg = URLSessionConfiguration.ephemeral
//   cfg.protocolClasses = [MockURLProtocol.self]
//   let transport = URLSessionTransport(configuration: cfg)
//   let client   = SwiftSonicClient(configuration: .test, transport: transport)
//
// IMPORTANT: Tests that use MockURLProtocol must run serially (add .serialized to the
// @Suite) because `handler` is a static mutable property shared across tests.

import Foundation
@testable import SwiftSonic

/// A `URLProtocol` subclass that intercepts requests and returns handler-provided responses.
///
/// Register it via `URLSessionConfiguration.protocolClasses` — never globally — to keep
/// its scope limited to the session under test.
final class MockURLProtocol: URLProtocol {

    // MARK: - Static handler

    /// Invoked for every intercepted request. Set before each test, clear after.
    ///
    /// `nonisolated(unsafe)` opts this property out of Swift 6 data-race checking.
    /// Safety is guaranteed by the `.serialized` trait on every `@Suite` that uses it.
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (Data, HTTPURLResponse))?

    // MARK: - URLProtocol overrides

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (data, response) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
