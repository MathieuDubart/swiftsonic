// Album.swift — SwiftSonic
//
// Data model for albums, as defined by the Subsonic and OpenSubsonic specs.
//
// AlbumID3 — ID3-tagged album, returned by getAlbum, getArtist, getAlbumList2, etc.
// AlbumInfo — biographical data returned by getAlbumInfo2.

import Foundation

// MARK: - AlbumID3

/// An album with full ID3-style metadata.
///
/// Returned by ``SwiftSonicClient/getAlbum(id:)``, ``SwiftSonicClient/getArtist(id:)``,
/// ``SwiftSonicClient/getAlbumList2(type:size:offset:fromYear:toYear:genre:musicFolderId:)``, etc.
public struct AlbumID3: Codable, Sendable, Identifiable, Equatable, Hashable {
    /// The unique server-assigned identifier.
    public let id: String

    /// The album title.
    public let name: String

    /// The primary artist name.
    public let artist: String?

    /// The primary artist ID.
    public let artistId: String?

    /// The ID used to fetch cover art via ``SwiftSonicClient/coverArtURL(id:size:)``.
    public let coverArt: String?

    /// Number of songs in the album.
    public let songCount: Int

    /// Total duration of the album in seconds.
    public let duration: Int

    /// Total play count across all users.
    public let playCount: Int?

    /// Date the album was added to the library.
    public let created: Date?

    /// Date the current user starred this album, if starred.
    public let starred: Date?

    /// Release year.
    public let year: Int?

    /// Primary genre name (legacy Subsonic field; see also ``genres``).
    public let genre: String?

    // MARK: OpenSubsonic fields

    /// Date this album was last played by the current user (OpenSubsonic).
    public let played: Date?

    /// User rating (1–5) (OpenSubsonic).
    public let userRating: Int?

    /// MusicBrainz release identifier (OpenSubsonic).
    public let musicBrainzId: String?

    /// All genres for this album (OpenSubsonic).
    public let genres: [ItemGenre]?

    /// All contributing artists (OpenSubsonic).
    public let artists: [ArtistID3]?

    /// Display string for multiple artists (OpenSubsonic).
    public let displayArtist: String?

    /// Release types (e.g. `["Album"]`, `["Single"]`) (OpenSubsonic).
    public let releaseTypes: [String]?

    /// Mood tags (OpenSubsonic).
    public let moods: [String]?

    /// Sort name for alphabetical ordering (OpenSubsonic).
    public let sortName: String?

    /// The original release date (OpenSubsonic).
    public let originalReleaseDate: ItemDate?

    /// The release date (OpenSubsonic).
    public let releaseDate: ItemDate?

    /// `true` if this is a compilation album (OpenSubsonic).
    public let isCompilation: Bool?

    /// Per-disc titles for multi-disc albums (OpenSubsonic).
    public let discTitles: [DiscTitle]?

    /// Record labels (OpenSubsonic).
    public let recordLabels: [RecordLabel]?

    /// Explicit content status (OpenSubsonic).
    ///
    /// Values: `"notExplicit"`, `"explicit"`, `"edited"`.
    public let explicitStatus: String?

    /// Edition descriptor (OpenSubsonic).
    ///
    /// Examples: `"Deluxe Edition"`, `"Remastered"`, `"Anniversary Edition"`.
    public let version: String?

    /// The songs on this album. Only populated by ``SwiftSonicClient/getAlbum(id:)``.
    public let song: [Song]?

    public init(
        id: String,
        name: String,
        songCount: Int,
        duration: Int,
        artist: String? = nil,
        artistId: String? = nil,
        coverArt: String? = nil,
        playCount: Int? = nil,
        created: Date? = nil,
        starred: Date? = nil,
        year: Int? = nil,
        genre: String? = nil,
        played: Date? = nil,
        userRating: Int? = nil,
        musicBrainzId: String? = nil,
        genres: [ItemGenre]? = nil,
        artists: [ArtistID3]? = nil,
        displayArtist: String? = nil,
        releaseTypes: [String]? = nil,
        moods: [String]? = nil,
        sortName: String? = nil,
        originalReleaseDate: ItemDate? = nil,
        releaseDate: ItemDate? = nil,
        isCompilation: Bool? = nil,
        discTitles: [DiscTitle]? = nil,
        recordLabels: [RecordLabel]? = nil,
        explicitStatus: String? = nil,
        version: String? = nil,
        song: [Song]? = nil
    ) {
        self.id                  = id
        self.name                = name
        self.songCount           = songCount
        self.duration            = duration
        self.artist              = artist
        self.artistId            = artistId
        self.coverArt            = coverArt
        self.playCount           = playCount
        self.created             = created
        self.starred             = starred
        self.year                = year
        self.genre               = genre
        self.played              = played
        self.userRating          = userRating
        self.musicBrainzId       = musicBrainzId
        self.genres              = genres
        self.artists             = artists
        self.displayArtist       = displayArtist
        self.releaseTypes        = releaseTypes
        self.moods               = moods
        self.sortName            = sortName
        self.originalReleaseDate = originalReleaseDate
        self.releaseDate         = releaseDate
        self.isCompilation       = isCompilation
        self.discTitles          = discTitles
        self.recordLabels        = recordLabels
        self.explicitStatus      = explicitStatus
        self.version             = version
        self.song                = song
    }

    public static func == (lhs: AlbumID3, rhs: AlbumID3) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - AlbumInfo

/// Biographical and external-link information about an album.
///
/// Returned by ``SwiftSonicClient/getAlbumInfo2(id:)``.
public struct AlbumInfo: Codable, Sendable {
    /// Notes or biography text.
    public let notes: String?

    /// MusicBrainz release identifier.
    public let musicBrainzId: String?

    /// Last.fm URL for this album.
    public let lastFmUrl: String?

    /// Small image URL.
    public let smallImageUrl: String?

    /// Medium image URL.
    public let mediumImageUrl: String?

    /// Large image URL.
    public let largeImageUrl: String?
}
