// Artist.swift — SwiftSonic
//
// Data models for artists, as defined by the Subsonic and OpenSubsonic specs.
//
// ArtistID3   — a single artist with full metadata (used in ID3-tagged responses)
// ArtistIndex — a letter bucket containing an array of ArtistID3 (used in getArtists)
// ArtistInfo  — biographical data returned by getArtistInfo2

import Foundation

// MARK: - ArtistID3

/// A music artist with full ID3-style metadata.
///
/// Returned by ``SwiftSonicClient/getArtists()`` and ``SwiftSonicClient/getArtist(id:)``.
public struct ArtistID3: Codable, Sendable, Identifiable {
    /// The unique server-assigned identifier for this artist.
    public let id: String

    /// The artist's display name.
    public let name: String

    /// The number of albums associated with this artist, if provided.
    public let albumCount: Int?

    /// The ID used to fetch cover art via ``SwiftSonicClient/coverArtURL(id:size:)``.
    public let coverArt: String?

    /// The date the user starred this artist, if starred.
    public let starred: Date?

    /// The user's rating for this artist (1–5), if set.
    public let userRating: Int?

    // MARK: OpenSubsonic fields

    /// MusicBrainz artist identifier (OpenSubsonic).
    public let musicBrainzId: String?

    /// Sort name for alphabetical ordering (OpenSubsonic).
    public let sortName: String?

    /// Roles this artist has contributed (e.g. `["composer", "producer"]`) (OpenSubsonic).
    public let roles: [String]?
}

// MARK: - ArtistIndex

/// A grouped collection of artists sharing the same first letter.
///
/// Used to represent the index structure returned by ``SwiftSonicClient/getArtists()``.
public struct ArtistIndex: Codable, Sendable {
    /// The index letter (e.g. `"A"`, `"B"`, `"#"` for non-alphabetic).
    public let name: String

    /// Artists in this index bucket.
    public let artist: [ArtistID3]
}

// MARK: - ArtistInfo

/// Biographical and external-link information about an artist.
///
/// Returned by ``SwiftSonicClient/getArtistInfo2(id:count:includeNotPresent:)``.
public struct ArtistInfo: Codable, Sendable {
    /// A short biography text.
    public let biography: String?

    /// MusicBrainz identifier for this artist.
    public let musicBrainzId: String?

    /// Last.fm URL for this artist.
    public let lastFmUrl: String?

    /// Small image URL.
    public let smallImageUrl: String?

    /// Medium image URL.
    public let mediumImageUrl: String?

    /// Large image URL.
    public let largeImageUrl: String?

    /// Artists similar to this one.
    public let similarArtist: [ArtistID3]?
}
