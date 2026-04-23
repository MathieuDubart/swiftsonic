// ServerCapabilities.swift — SwiftSonic
//
// Represents the capabilities reported by the server after calling fetchCapabilities().
// Populated from ping (base fields) and getOpenSubsonicExtensions (extension map).
//
// Use supports(_:version:) to safely gate calls to OpenSubsonic-specific endpoints.

import Foundation

/// The capabilities and version information reported by a connected server.
///
/// Populated by calling ``SwiftSonicClient/fetchCapabilities()``.
/// Access via ``SwiftSonicClient/serverCapabilities`` (nil until fetched).
///
/// ```swift
/// try await client.fetchCapabilities()
/// if client.serverCapabilities?.supports("songLyrics") == true {
///     let lyrics = try await client.getLyricsBySongId("song-123")
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
    /// Use ``supports(_:version:)`` rather than querying this directly.
    public let extensions: [String: [Int]]

    // MARK: - Extension support check

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

    // MARK: - Internal init

    init(
        apiVersion: String,
        isOpenSubsonic: Bool,
        serverType: String?,
        serverVersion: String?,
        extensions: [String: [Int]]
    ) {
        self.apiVersion = apiVersion
        self.isOpenSubsonic = isOpenSubsonic
        self.serverType = serverType
        self.serverVersion = serverVersion
        self.extensions = extensions
    }
}
