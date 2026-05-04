// ServerCapabilities.swift — SwiftSonic
//
// Represents the capabilities reported by the server after calling fetchCapabilities().
// Populated from ping (base fields) and getOpenSubsonicExtensions (extension map).
//
// Use supports(_:) to safely gate calls to OpenSubsonic-specific endpoints.

import Foundation

// MARK: - KnownExtension

/// Well-known OpenSubsonic extension identifiers.
///
/// Pass to ``ServerCapabilities/supports(_:)-8y7jh`` to check support without
/// hardcoding raw strings.
///
/// ```swift
/// if capabilities.supports(.songLyrics) {
///     let lyrics = try await client.getLyricsBySongId(id: song.id)
/// }
/// ```
public enum KnownExtension: String, Sendable, CaseIterable {
    /// Structured lyrics with optional per-line timing.
    case songLyrics           = "songLyrics"
    /// `offset` parameter on `stream` for mid-track resume.
    case transcodeOffset      = "transcodeOffset"
    /// HTTP POST for API requests (alternative to GET).
    case formPost             = "formPost"
    /// API key authentication (alternative to token auth).
    case apiKeyAuthentication = "apiKeyAuthentication"
    /// Index-based play queue operations.
    case indexBasedQueue      = "indexBasedQueue"
    /// Playback reporting endpoints.
    case playbackReport       = "playbackReport"
    /// Sonic-similarity search endpoints.
    case sonicSimilarity      = "sonicSimilarity"
    /// Transcoding decision and stream endpoints.
    case transcoding          = "transcoding"
    /// Single podcast episode fetch.
    case getPodcastEpisode    = "getPodcastEpisode"
}

// MARK: - ServerCapabilities

/// The capabilities and version information reported by a connected server.
///
/// Populated by calling ``SwiftSonicClient/fetchCapabilities()``.
/// Access via ``SwiftSonicClient/serverCapabilities`` (nil until fetched) or
/// ``SwiftSonicClient/loadCapabilities()`` (lazy, never nil after a successful ping).
///
/// ```swift
/// let caps = try await client.loadCapabilities()
/// if caps.supports(.songLyrics) {
///     let lyrics = try await client.getLyricsBySongId(id: "song-123")
/// }
/// ```
public struct ServerCapabilities: Sendable {
    /// The Subsonic API version the server reports (e.g. `"1.16.1"`).
    public let apiVersion: String

    /// `true` if the server supports OpenSubsonic extensions.
    public let isOpenSubsonic: Bool

    /// The server implementation name, if provided (OpenSubsonic only).
    ///
    /// Examples: `"navidrome"`, `"gonic"`, `"airsonic-advanced"`.
    public let serverType: String?

    /// The server application's own version string (OpenSubsonic only).
    ///
    /// This is the server software version, distinct from the Subsonic API version.
    public let serverVersion: String?

    /// Map of OpenSubsonic extension names to their supported versions.
    ///
    /// Example: `["songLyrics": [1, 2], "apiKeyAuthentication": [1]]`
    ///
    /// Use ``supports(_:)-9q8rp`` or ``supports(_:version:)-7q2n5`` rather than querying this directly.
    public let extensions: [String: [Int]]

    // MARK: - Derived view

    /// The OpenSubsonic extensions as a typed array.
    ///
    /// Derived from ``extensions``. Element order is not guaranteed.
    public var extensionList: [OpenSubsonicExtension] {
        extensions.map { OpenSubsonicExtension(name: $0.key, versions: $0.value) }
    }

    // MARK: - Extension support checks

    /// Returns `true` if the server supports the given well-known extension.
    ///
    /// - Parameter knownExtension: A ``KnownExtension`` case.
    public func supports(_ knownExtension: KnownExtension) -> Bool {
        supports(knownExtension.rawValue)
    }

    /// Returns `true` if the server supports the named OpenSubsonic extension at the given version.
    ///
    /// - Parameters:
    ///   - extensionName: The extension name as defined by the OpenSubsonic spec
    ///     (e.g. `"songLyrics"`, `"apiKeyAuthentication"`).
    ///   - version: The minimum version required. Defaults to `1`.
    /// - Returns: `true` if the server's extension list includes `extensionName` at `version`
    ///   or higher.
    public func supports(_ extensionName: String, version: Int = 1) -> Bool {
        guard let versions = extensions[extensionName] else { return false }
        return versions.contains(version)
    }

    // MARK: - Factory

    /// Returns a ``ServerCapabilities`` representing a Subsonic legacy server with no
    /// OpenSubsonic extensions.
    ///
    /// Used as a safe fallback when ``SwiftSonicClient/loadCapabilities()`` cannot
    /// reach the extensions endpoint, or when building test stubs.
    public static func legacy() -> ServerCapabilities {
        ServerCapabilities(
            apiVersion: "",
            isOpenSubsonic: false,
            serverType: nil,
            serverVersion: nil,
            extensions: [:]
        )
    }

    // MARK: - Initializer

    public init(
        apiVersion: String,
        isOpenSubsonic: Bool,
        serverType: String?,
        serverVersion: String?,
        extensions: [String: [Int]]
    ) {
        self.apiVersion     = apiVersion
        self.isOpenSubsonic = isOpenSubsonic
        self.serverType     = serverType
        self.serverVersion  = serverVersion
        self.extensions     = extensions
    }
}
