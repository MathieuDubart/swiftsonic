// NowPlayingEntry.swift — SwiftSonic
//
// Data model for entries returned by the getNowPlaying endpoint.

import Foundation

// MARK: - NowPlayingEntry

/// A currently playing track reported by a connected client.
///
/// Each entry represents one user's active playback session.
/// Returned by ``SwiftSonicClient/getNowPlaying()``.
public struct NowPlayingEntry: Decodable, Sendable, Identifiable {

    // MARK: Now-playing fields

    /// The username of the person playing this track.
    public let username: String

    /// Minutes elapsed since playback started.
    public let minutesAgo: Int

    /// An opaque identifier for the player/client instance.
    public let playerId: Int

    /// A human-readable name for the player/client (e.g. `"iPhone"`, `"Web Player"`).
    public let playerName: String?

    // MARK: Song fields (focused subset)

    /// The unique server-assigned song identifier.
    public let id: String

    /// The song title.
    public let title: String

    /// The primary artist name.
    public let artist: String?

    /// The album name.
    public let album: String?

    /// Duration in seconds.
    public let duration: Int?

    /// The ID used to fetch cover art via ``SwiftSonicClient/coverArtURL(id:size:)``.
    public let coverArt: String?

    /// MIME type (e.g. `"audio/mpeg"`).
    public let contentType: String?
}
