// Bookmark.swift — SwiftSonic
//
// Model for a media playback bookmark.
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getbookmarks/

import Foundation

/// A saved playback position for a media file.
///
/// Bookmarks let users resume listening across sessions and devices.
/// Useful for long-form audio like audiobooks or podcast episodes.
public struct Bookmark: Codable, Sendable {

    /// The saved playback position, in seconds.
    ///
    /// Stored as milliseconds on the wire; converted internally.
    public let position: TimeInterval

    /// The username that owns this bookmark.
    public let username: String

    /// An optional note attached to this bookmark.
    public let comment: String?

    /// The date this bookmark was first created.
    public let created: Date

    /// The date this bookmark was last updated.
    public let changed: Date

    /// The bookmarked media file.
    public let entry: Song

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case position, username, comment, created, changed, entry
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // API sends position in milliseconds; expose as TimeInterval (seconds)
        let ms = try c.decode(Int64.self, forKey: .position)
        position = TimeInterval(ms) / 1000

        username = try c.decode(String.self, forKey: .username)
        comment  = try c.decodeIfPresent(String.self, forKey: .comment)
        created  = try c.decode(Date.self, forKey: .created)
        changed  = try c.decode(Date.self, forKey: .changed)
        entry    = try c.decode(Song.self, forKey: .entry)
    }
}
