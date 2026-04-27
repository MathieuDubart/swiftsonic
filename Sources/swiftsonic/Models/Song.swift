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

    /// Media type (e.g. `"music"`, `"podcast"`, `"audiobook"`, `"video"`).
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

    public static func == (lhs: Song, rhs: Song) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
