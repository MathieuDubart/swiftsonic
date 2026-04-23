// HTTPTransport.swift — SwiftSonic
//
// Defines the HTTPTransport protocol: the single seam between SwiftSonicClient
// and the network layer.
//
// Inject a custom conformance via SwiftSonicClient(configuration:transport:) to:
//   - Add request logging
//   - Pin SSL certificates
//   - Route through a proxy
//   - Stub network calls in tests (see MockHTTPTransport in the test target)

import Foundation

/// Performs a single HTTP request and returns the raw response.
///
/// The default implementation is ``URLSessionTransport``, which wraps `URLSession`.
/// Inject a custom conformance to intercept or replace network calls.
///
/// ```swift
/// struct LoggingTransport: HTTPTransport {
///     let underlying: any HTTPTransport
///
///     func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
///         print("→ \(request.url?.absoluteString ?? "")")
///         let (data, response) = try await underlying.data(for: request)
///         print("← \(response.statusCode)")
///         return (data, response)
///     }
/// }
/// ```
public protocol HTTPTransport: Sendable {
    /// Executes the request and returns the response body and HTTP metadata.
    ///
    /// - Parameter request: The fully constructed `URLRequest` to execute.
    /// - Returns: A tuple of the response body and the HTTP response metadata.
    /// - Throws: Any error encountered during the network call (typically `URLError`).
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
