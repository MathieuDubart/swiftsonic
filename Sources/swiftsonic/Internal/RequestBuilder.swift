// RequestBuilder.swift — SwiftSonic (Internal)
//
// Centralises URL construction for every Subsonic API request.
//
// Responsibilities:
//   - Appending the /rest/ path and .view endpoint suffix
//   - Adding common parameters: f, v, c
//   - Adding authentication parameters (u/t/s for token auth, apiKey for API key auth)
//   - Generating or reusing the auth salt
//
// All methods are internal — only SwiftSonicClient calls this.

import Foundation

// MARK: - Request builder

/// Builds authenticated `URLRequest`s for Subsonic API endpoints.
final class RequestBuilder: Sendable {
    private let configuration: ServerConfiguration

    // Reused salt for reusesSalt == true (protected by the actor that owns this builder)
    // Nonisolated storage: safe because it's only mutated once and only accessed
    // from the owning actor's context.
    private let cachedSalt: String?

    init(configuration: ServerConfiguration) {
        self.configuration = configuration

        // Pre-compute salt if reusesSalt is requested
        if case .tokenAuth(_, _, let reuses) = configuration.auth, reuses {
            cachedSalt = randomSalt()
        } else {
            cachedSalt = nil
        }
    }

    // MARK: - URL construction

    /// Builds a complete `URLRequest` for the given endpoint and parameters.
    ///
    /// - Parameters:
    ///   - endpoint: The Subsonic endpoint name (e.g. `"getArtists"`).
    ///   - params: Endpoint-specific query parameters (do not include auth or common params).
    ///   - multiParams: Parameters that can appear multiple times (e.g. `songIdToAdd`).
    ///     Each key maps to an array of values; one `URLQueryItem` is appended per value.
    /// - Returns: A ready-to-execute `URLRequest`.
    /// - Throws: `SwiftSonicError.invalidConfiguration` if the URL cannot be constructed.
    func request(
        endpoint: String,
        params: [String: String] = [:],
        multiParams: [String: [String]] = [:]
    ) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = configuration.serverURL.scheme
        components.host = configuration.serverURL.host
        components.port = configuration.serverURL.port
        components.path = configuration.serverURL.path.trimTrailingSlash + "/rest/\(endpoint).view"

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "f", value: "json"),
            URLQueryItem(name: "v", value: configuration.apiVersion),
            URLQueryItem(name: "c", value: configuration.clientName),
        ]

        // Auth parameters
        switch configuration.auth {
        case .tokenAuth(let username, let password, _):
            let salt = cachedSalt ?? randomSalt()
            let token = subsonicToken(password: password, salt: salt)
            queryItems.append(contentsOf: [
                URLQueryItem(name: "u", value: username),
                URLQueryItem(name: "t", value: token),
                URLQueryItem(name: "s", value: salt),
            ])

        case .apiKey(let key):
            queryItems.append(URLQueryItem(name: "apiKey", value: key))
        }

        // Endpoint-specific scalar parameters
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }

        // Endpoint-specific multi-value parameters (one item per value)
        for (key, values) in multiParams {
            for value in values {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw SwiftSonicError.invalidConfiguration(
                "Could not build URL for endpoint '\(endpoint)' with base '\(configuration.serverURL)'"
            )
        }

        return URLRequest(url: url)
    }

    /// Builds an authenticated media URL (stream, download, coverArt) without making a
    /// network request. The returned URL can be passed directly to `AVPlayer` or an
    /// image loading system.
    ///
    /// - Parameters:
    ///   - endpoint: The media endpoint name (e.g. `"stream"`, `"getCoverArt"`).
    ///   - params: Endpoint-specific query parameters.
    /// - Returns: A fully authenticated `URL`, or `nil` if the URL cannot be constructed.
    func mediaURL(endpoint: String, params: [String: String] = [:]) -> URL? {
        (try? request(endpoint: endpoint, params: params, multiParams: [:]))?.url
    }
}

// MARK: - Private helpers

private extension String {
    var trimTrailingSlash: String {
        hasSuffix("/") ? String(dropLast()) : self
    }
}
