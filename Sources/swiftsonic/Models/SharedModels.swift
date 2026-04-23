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
}

// MARK: - DiscTitle

/// A per-disc title for multi-disc albums (OpenSubsonic).
public struct DiscTitle: Codable, Sendable {
    /// The disc number (1-based).
    public let disc: Int
    /// The disc's title.
    public let title: String
}

// MARK: - RecordLabel

/// A record label associated with an album (OpenSubsonic).
public struct RecordLabel: Codable, Sendable {
    /// The label name.
    public let name: String
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
}

/// A minimal artist reference used inside ``Contributor``.
public struct ContributorArtist: Codable, Sendable {
    public let id: String
    public let name: String
    public let musicBrainzId: String?
    public let sortName: String?
}
