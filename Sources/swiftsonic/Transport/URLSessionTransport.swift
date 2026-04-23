// URLSessionTransport.swift — SwiftSonic
//
// Default HTTPTransport implementation backed by URLSession.
// Used automatically when no custom transport is injected into SwiftSonicClient.

import Foundation

/// The default ``HTTPTransport`` implementation, backed by `URLSession`.
///
/// Uses `URLSession.shared` by default. Pass a custom `URLSession` to configure
/// timeout intervals, TLS settings, or a custom delegate:
///
/// ```swift
/// let session = URLSession(configuration: .default)
/// let transport = URLSessionTransport(session: session)
/// let client = SwiftSonicClient(configuration: config, transport: transport)
/// ```
public struct URLSessionTransport: HTTPTransport, Sendable {
    private let session: URLSession

    /// Creates a transport backed by the given session.
    ///
    /// - Parameter session: The `URLSession` to use. Defaults to `.shared`.
    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }
}
