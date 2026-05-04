// SharedModels.swift — SwiftSonic
//
// Small value types shared across multiple domain models.
// Kept here to avoid duplication between Album, Song, and Artist models.

import Foundation

// MARK: - ItemGenre

/// A genre tag on an album or song (OpenSubsonic).
///
/// Distinct from ``Genre`` (which is returned by `getGenres` and includes counts).
public struct ItemGenre: Codable, Sendable, Equatable {
    /// The genre name (e.g. `"Rock"`, `"Jazz"`).
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

// MARK: - ReplayGain

/// Replay gain information for volume normalisation (OpenSubsonic).
public struct ReplayGain: Codable, Sendable {
    /// Track-level gain in dB.
    public let trackGain: Double?
    /// Album-level gain in dB.
    public let albumGain: Double?
    /// Track peak amplitude (0.0–1.0).
    public let trackPeak: Double?
    /// Album peak amplitude (0.0–1.0).
    public let albumPeak: Double?
    /// Base gain applied before track/album gain.
    public let baseGain: Double?
    /// Fallback gain used when track gain is absent.
    public let fallbackGain: Double?

    public init(
        trackGain: Double? = nil,
        albumGain: Double? = nil,
        trackPeak: Double? = nil,
        albumPeak: Double? = nil,
        baseGain: Double? = nil,
        fallbackGain: Double? = nil
    ) {
        self.trackGain    = trackGain
        self.albumGain    = albumGain
        self.trackPeak    = trackPeak
        self.albumPeak    = albumPeak
        self.baseGain     = baseGain
        self.fallbackGain = fallbackGain
    }
}

// MARK: - ItemDate

/// A partial date with optional month and day (OpenSubsonic).
///
/// Used for `releaseDate` and `originalReleaseDate` on albums.
public struct ItemDate: Codable, Sendable {
    /// The four-digit year.
    public let year: Int?
    /// The month (1–12).
    public let month: Int?
    /// The day of month (1–31).
    public let day: Int?

    public init(year: Int? = nil, month: Int? = nil, day: Int? = nil) {
        self.year  = year
        self.month = month
        self.day   = day
    }
}

// MARK: - DiscTitle

/// A per-disc title for multi-disc albums (OpenSubsonic).
public struct DiscTitle: Codable, Sendable {
    /// The disc number (1-based).
    public let disc: Int
    /// The disc's title.
    public let title: String

    public init(disc: Int, title: String) {
        self.disc  = disc
        self.title = title
    }
}

// MARK: - RecordLabel

/// A record label associated with an album (OpenSubsonic).
public struct RecordLabel: Codable, Sendable {
    /// The label name.
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

// MARK: - Contributor

/// An artist contributor with a specific role (OpenSubsonic).
///
/// Used in `Song.contributors` to represent composers, producers, etc.
public struct Contributor: Codable, Sendable {
    /// The role (e.g. `"composer"`, `"producer"`, `"lyricist"`).
    public let role: String
    /// An optional sub-role for finer-grained credits.
    public let subRole: String?
    /// The contributing artist.
    public let artist: ContributorArtist

    public init(role: String, subRole: String? = nil, artist: ContributorArtist) {
        self.role    = role
        self.subRole = subRole
        self.artist  = artist
    }
}

/// A minimal artist reference used inside ``Contributor``.
///
/// This is a lean subset of `ArtistID3` — only the fields reliably returned by
/// servers for contributor credits are included. Full `ArtistID3` conformance
/// may be considered in a future major version.
public struct ContributorArtist: Codable, Sendable {
    public let id: String
    public let name: String
    public let musicBrainzId: String?
    public let sortName: String?

    public init(
        id: String,
        name: String,
        musicBrainzId: String? = nil,
        sortName: String? = nil
    ) {
        self.id            = id
        self.name          = name
        self.musicBrainzId = musicBrainzId
        self.sortName      = sortName
    }
}
