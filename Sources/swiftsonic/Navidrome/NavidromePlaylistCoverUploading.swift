// NavidromePlaylistCoverUploading.swift — SwiftSonic
//
// Protocol for Navidrome-specific REST endpoints that manage playlist cover images.
// These endpoints are NOT part of the Subsonic/OpenSubsonic spec — they are
// Navidrome-native and require separate JWT authentication.

import Foundation

/// Navidrome-specific REST API for uploading playlist cover images.
///
/// This protocol covers endpoints that are not part of the Subsonic or OpenSubsonic
/// specifications. Authentication uses Navidrome's own JWT mechanism via ``authenticate``,
/// which is entirely separate from the Subsonic credential system.
///
/// ## Typical usage
/// ```swift
/// let api = NavidromeNativeAPI()
/// let token = try await api.authenticate(baseURL: url, username: "alice", password: "s3cr3t")
/// try await api.uploadPlaylistCover(baseURL: url, token: token,
///                                   playlistId: "42",
///                                   imageData: pngData, mimeType: "image/png")
/// ```
public protocol NavidromePlaylistCoverUploading: Sendable {

    /// Authenticates against Navidrome's native REST API and returns a JWT token.
    ///
    /// Calls `POST {baseURL}/auth/login` with a JSON body containing the credentials.
    ///
    /// - Parameters:
    ///   - baseURL: The root URL of the Navidrome server (e.g. `https://music.example.com`).
    ///   - username: The Navidrome username.
    ///   - password: The Navidrome password.
    /// - Returns: A JWT token string for use with subsequent native API calls.
    /// - Throws: ``NavidromeNativeAPIError`` on failure.
    ///
    /// > Important: The returned token is a credential. Store it securely and
    /// > never include it in log output or error messages.
    func authenticate(
        baseURL: URL,
        username: String,
        password: String
    ) async throws -> String

    /// Uploads an image as the cover art for the specified playlist.
    ///
    /// Calls `POST {baseURL}/api/playlist/{playlistId}/image` with a
    /// `multipart/form-data` body containing the image in the `playlistImage` field.
    ///
    /// - Parameters:
    ///   - baseURL: The root URL of the Navidrome server.
    ///   - token: A valid JWT token obtained from ``authenticate``.
    ///   - playlistId: The Navidrome playlist identifier.
    ///   - imageData: The raw image bytes.
    ///   - mimeType: The MIME type of the image data (e.g. `"image/jpeg"` or `"image/png"`).
    /// - Throws: ``NavidromeNativeAPIError`` on failure.
    func uploadPlaylistCover(
        baseURL: URL,
        token: String,
        playlistId: String,
        imageData: Data,
        mimeType: String
    ) async throws
}
