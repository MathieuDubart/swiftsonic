// Playlist.swift — SwiftSonic
//
// Models for playlist-related endpoints: getPlaylists, getPlaylist,
// createPlaylist, updatePlaylist, deletePlaylist.

import Foundation

// MARK: - Playlist

/// A Subsonic playlist.
public struct Playlist: Decodable, Sendable, Identifiable, Equatable, Hashable {

    // MARK: Core fields

    public let id: String
    public let name: String
    public let comment: String?
    public let owner: String?
    /// Whether the playlist is publicly visible. JSON key is `"public"`.
    public let isPublic: Bool?
    public let songCount: Int
    /// Total duration of the playlist in seconds.
    public let duration: Int
    public let created: Date?
    public let changed: Date?
    public let coverArt: String?

    // MARK: Public initializer

    public init(
        id: String,
        name: String,
        songCount: Int,
        duration: Int,
        comment: String? = nil,
        owner: String? = nil,
        isPublic: Bool? = nil,
        created: Date? = nil,
        changed: Date? = nil,
        coverArt: String? = nil
    ) {
        self.id        = id
        self.name      = name
        self.songCount = songCount
        self.duration  = duration
        self.comment   = comment
        self.owner     = owner
        self.isPublic  = isPublic
        self.created   = created
        self.changed   = changed
        self.coverArt  = coverArt
    }

    // MARK: CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, name, comment, owner
        case isPublic = "public"
        case songCount, duration, created, changed, coverArt
    }

    public static func == (lhs: Playlist, rhs: Playlist) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - PlaylistWithSongs

/// A playlist that includes its track list (returned by `getPlaylist`).
public struct PlaylistWithSongs: Decodable, Sendable, Identifiable, Equatable, Hashable {

    public let id: String
    public let name: String
    public let comment: String?
    public let owner: String?
    public let isPublic: Bool?
    public let songCount: Int
    public let duration: Int
    public let created: Date?
    public let changed: Date?
    public let coverArt: String?
    /// The ordered list of tracks in this playlist.
    public let entry: [Song]?

    // MARK: Public initializer

    public init(
        id: String,
        name: String,
        songCount: Int,
        duration: Int,
        comment: String? = nil,
        owner: String? = nil,
        isPublic: Bool? = nil,
        created: Date? = nil,
        changed: Date? = nil,
        coverArt: String? = nil,
        entry: [Song]? = nil
    ) {
        self.id        = id
        self.name      = name
        self.songCount = songCount
        self.duration  = duration
        self.comment   = comment
        self.owner     = owner
        self.isPublic  = isPublic
        self.created   = created
        self.changed   = changed
        self.coverArt  = coverArt
        self.entry     = entry
    }

    enum CodingKeys: String, CodingKey {
        case id, name, comment, owner
        case isPublic = "public"
        case songCount, duration, created, changed, coverArt, entry
    }

    public static func == (lhs: PlaylistWithSongs, rhs: PlaylistWithSongs) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
