// Genre.swift — SwiftSonic
//
// Data model for genres as returned by the getGenres endpoint.
//
// Note: the genre name is in the "value" key (original Subsonic spec quirk),
// not "name". For the ItemGenre type used on Album/Song, see SharedModels.swift.

import Foundation

// MARK: - Genre

/// A genre with song and album counts, as returned by ``SwiftSonicClient/getGenres()``.
///
/// Note that the genre name is in ``value`` (a legacy Subsonic naming quirk).
/// For per-track/per-album genre tags, see ``ItemGenre``.
public struct Genre: Codable, Sendable {
    /// Number of songs tagged with this genre.
    public let songCount: Int

    /// Number of albums tagged with this genre.
    public let albumCount: Int

    /// The genre name.
    ///
    /// Named `value` to match the Subsonic JSON field name.
    public let value: String
}

// MARK: - Indexes (getIndexes response)

/// The result of ``SwiftSonicClient/getIndexes(musicFolderId:ifModifiedSince:)``.
///
/// Uses folder-based (non-ID3) browsing. Prefer ``SwiftSonicClient/getArtists()``
/// for ID3-tagged metadata.
public struct Indexes: Codable, Sendable {
    /// Last-modified timestamp in milliseconds since epoch.
    public let lastModified: Int?

    /// Articles ignored when sorting (e.g. `"The El La"`).
    public let ignoredArticles: String?

    /// Artist index buckets.
    public let index: [ArtistIndex]?

    /// Shortcut (pinned) artists.
    public let shortcut: [IndexArtist]?

    /// Top-level files not inside any folder.
    public let child: [Song]?
}

/// A minimal artist reference used in folder-based indexes.
public struct IndexArtist: Codable, Sendable, Identifiable {
    /// The unique identifier.
    public let id: String

    /// The artist name.
    public let name: String

    /// Cover art ID.
    public let coverArt: String?

    /// Date starred by the current user, if starred.
    public let starred: Date?

    /// User rating (1–5).
    public let userRating: Int?

    /// Average community rating.
    public let averageRating: Double?
}
