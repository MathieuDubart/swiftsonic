// Song.swift — SwiftSonic
//
// Data model for songs and directory entries (the "Child" type in the Subsonic spec).
//
// A Song can represent either a media file (isDir == false) or a directory node
// (isDir == true) when returned from getMusicDirectory.

import Foundation

// MARK: - Song

/// A media file or directory entry.
///
/// This type maps to the `Child` element in the Subsonic spec.
/// When returned from ``SwiftSonicClient/getMusicDirectory(id:)``, check ``isDir``
/// to distinguish between folders and audio files.
///
/// Returned by ``SwiftSonicClient/getAlbum(id:)``, ``SwiftSonicClient/getSong(id:)``,
/// ``SwiftSonicClient/getRandomSongs(size:genre:fromYear:toYear:musicFolderId:)``, etc.
public struct Song: Codable, Sendable, Identifiable, Equatable, Hashable {
    // MARK: Core fields

    /// The unique server-assigned identifier.
    public let id: String

    /// The parent directory ID.
    public let parent: String?

    /// `true` if this entry represents a directory rather than a media file.
    public let isDir: Bool?

    /// The song title (or directory name when `isDir` is `true`).
    public let title: String

    /// The album name.
    public let album: String?

    /// The primary artist name.
    public let artist: String?

    /// The track number on the album.
    public let track: Int?

    /// The release year.
    public let year: Int?

    /// The primary genre (legacy; see also ``genres``).
    public let genre: String?

    /// The ID used to fetch cover art via ``SwiftSonicClient/coverArtURL(id:size:)``.
    public let coverArt: String?

    /// File size in bytes.
    public let size: Int?

    /// MIME type (e.g. `"audio/mpeg"`).
    public let contentType: String?

    /// File extension (e.g. `"mp3"`, `"flac"`).
    public let suffix: String?

    /// Transcoded MIME type when a different format was requested.
    public let transcodedContentType: String?

    /// Transcoded file extension.
    public let transcodedSuffix: String?

    /// Duration in seconds.
    public let duration: Int?

    /// Bitrate in kbps.
    public let bitRate: Int?

    /// Server-relative file path.
    public let path: String?

    /// `true` if this is a video file.
    public let isVideo: Bool?

    /// User rating (1–5).
    public let userRating: Int?

    /// Average community rating.
    public let averageRating: Double?

    /// Total play count.
    public let playCount: Int?

    /// Disc number for multi-disc albums.
    public let discNumber: Int?

    /// Date added to the library.
    public let created: Date?

    /// Date starred by the current user, if starred.
    public let starred: Date?

    /// The album ID.
    public let albumId: String?

    /// The artist ID.
    public let artistId: String?

    /// Generic media category (legacy Subsonic field).
    ///
    /// Values: `"music"`, `"podcast"`, `"audiobook"`, `"video"`.
    /// See also ``mediaType`` (OpenSubsonic) for a more granular classification.
    public let type: String?

    // MARK: OpenSubsonic fields

    /// Date last played by the current user (OpenSubsonic).
    public let played: Date?

    /// Beats per minute (OpenSubsonic).
    public let bpm: Int?

    /// User comment (OpenSubsonic).
    public let comment: String?

    /// Sort name for alphabetical ordering (OpenSubsonic).
    public let sortName: String?

    /// MusicBrainz recording identifier (OpenSubsonic).
    public let musicBrainzId: String?

    /// All genres for this track (OpenSubsonic).
    public let genres: [ItemGenre]?

    /// All contributing artists (OpenSubsonic).
    public let artists: [ArtistID3]?

    /// Display string for multiple artists (OpenSubsonic).
    public let displayArtist: String?

    /// Album artists (OpenSubsonic).
    public let albumArtists: [ArtistID3]?

    /// Display string for multiple album artists (OpenSubsonic).
    public let displayAlbumArtist: String?

    /// Detailed contributor credits (OpenSubsonic).
    public let contributors: [Contributor]?

    /// Composer display string (OpenSubsonic).
    public let displayComposer: String?

    /// Replay gain data for volume normalisation (OpenSubsonic).
    public let replayGain: ReplayGain?

    /// Bit depth (e.g. 16, 24) (OpenSubsonic).
    public let bitDepth: Int?

    /// Sampling rate in Hz (OpenSubsonic).
    public let samplingRate: Int?

    /// Number of audio channels (OpenSubsonic).
    public let channelCount: Int?

    /// Mood tags (OpenSubsonic).
    public let moods: [String]?

    /// ISRC codes (OpenSubsonic).
    public let isrc: [String]?

    /// Explicit content status (OpenSubsonic).
    ///
    /// Values: `"notExplicit"`, `"explicit"`, `"edited"`.
    public let explicitStatus: String?

    /// Actual media type for this item (OpenSubsonic).
    ///
    /// Distinct from ``type`` (legacy Subsonic field).
    /// Values: `"song"`, `"album"`, `"artist"`.
    public let mediaType: String?

    public init(
        id: String,
        title: String,
        parent: String? = nil,
        isDir: Bool? = nil,
        album: String? = nil,
        artist: String? = nil,
        track: Int? = nil,
        year: Int? = nil,
        genre: String? = nil,
        coverArt: String? = nil,
        size: Int? = nil,
        contentType: String? = nil,
        suffix: String? = nil,
        transcodedContentType: String? = nil,
        transcodedSuffix: String? = nil,
        duration: Int? = nil,
        bitRate: Int? = nil,
        path: String? = nil,
        isVideo: Bool? = nil,
        userRating: Int? = nil,
        averageRating: Double? = nil,
        playCount: Int? = nil,
        discNumber: Int? = nil,
        created: Date? = nil,
        starred: Date? = nil,
        albumId: String? = nil,
        artistId: String? = nil,
        type: String? = nil,
        played: Date? = nil,
        bpm: Int? = nil,
        comment: String? = nil,
        sortName: String? = nil,
        musicBrainzId: String? = nil,
        genres: [ItemGenre]? = nil,
        artists: [ArtistID3]? = nil,
        displayArtist: String? = nil,
        albumArtists: [ArtistID3]? = nil,
        displayAlbumArtist: String? = nil,
        contributors: [Contributor]? = nil,
        displayComposer: String? = nil,
        replayGain: ReplayGain? = nil,
        bitDepth: Int? = nil,
        samplingRate: Int? = nil,
        channelCount: Int? = nil,
        moods: [String]? = nil,
        isrc: [String]? = nil,
        explicitStatus: String? = nil,
        mediaType: String? = nil
    ) {
        self.id                    = id
        self.title                 = title
        self.parent                = parent
        self.isDir                 = isDir
        self.album                 = album
        self.artist                = artist
        self.track                 = track
        self.year                  = year
        self.genre                 = genre
        self.coverArt              = coverArt
        self.size                  = size
        self.contentType           = contentType
        self.suffix                = suffix
        self.transcodedContentType = transcodedContentType
        self.transcodedSuffix      = transcodedSuffix
        self.duration              = duration
        self.bitRate               = bitRate
        self.path                  = path
        self.isVideo               = isVideo
        self.userRating            = userRating
        self.averageRating         = averageRating
        self.playCount             = playCount
        self.discNumber            = discNumber
        self.created               = created
        self.starred               = starred
        self.albumId               = albumId
        self.artistId              = artistId
        self.type                  = type
        self.played                = played
        self.bpm                   = bpm
        self.comment               = comment
        self.sortName              = sortName
        self.musicBrainzId         = musicBrainzId
        self.genres                = genres
        self.artists               = artists
        self.displayArtist         = displayArtist
        self.albumArtists          = albumArtists
        self.displayAlbumArtist    = displayAlbumArtist
        self.contributors          = contributors
        self.displayComposer       = displayComposer
        self.replayGain            = replayGain
        self.bitDepth              = bitDepth
        self.samplingRate          = samplingRate
        self.channelCount          = channelCount
        self.moods                 = moods
        self.isrc                  = isrc
        self.explicitStatus        = explicitStatus
        self.mediaType             = mediaType
    }

    public static func == (lhs: Song, rhs: Song) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
