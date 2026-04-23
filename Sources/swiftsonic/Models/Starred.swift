// Starred.swift — SwiftSonic
//
// Data model for starred (favourited) items, returned by getStarred2.

import Foundation

// MARK: - Starred2

/// The collection of items starred by the current user.
///
/// Returned by ``SwiftSonicClient/getStarred2(musicFolderId:)``.
public struct Starred2: Codable, Sendable {
    /// Starred artists.
    public let artist: [ArtistID3]?

    /// Starred albums.
    public let album: [AlbumID3]?

    /// Starred songs.
    public let song: [Song]?
}
