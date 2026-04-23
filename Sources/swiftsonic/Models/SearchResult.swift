// SearchResult.swift — SwiftSonic
//
// Model for search3 endpoint results.

import Foundation

// MARK: - SearchResult3

/// Results returned by the `search3` endpoint.
///
/// Each of the three arrays is optional — the server only includes a key when
/// it has at least one matching result.
public struct SearchResult3: Decodable, Sendable {
    /// Matching artists.
    public let artist: [ArtistID3]?
    /// Matching albums.
    public let album: [AlbumID3]?
    /// Matching songs.
    public let song: [Song]?
}
