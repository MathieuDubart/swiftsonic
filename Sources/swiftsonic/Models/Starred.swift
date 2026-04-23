// Starred.swift — SwiftSonic
//
// Data models for starred (favourited) items.
//
// Starred  — folder-based organisation, returned by getStarred.
// Starred2 — ID3-tagged organisation, returned by getStarred2.

import Foundation

// MARK: - Starred (folder-based)

/// The collection of items starred by the current user (folder-based).
///
/// Artist and album entries are represented as ``Song`` values with ``Song/isDir``
/// set to `true`, consistent with the folder-based browsing model.
///
/// > Important: Prefer ``Starred2`` (returned by ``SwiftSonicClient/getStarred2(musicFolderId:)``)
/// > unless you specifically need folder-structure browsing. ``Starred2`` returns typed
/// > ``ArtistID3`` and ``AlbumID3`` values.
///
/// Returned by ``SwiftSonicClient/getStarred(musicFolderId:)``.
public struct Starred: Codable, Sendable {
    /// Starred artists (represented as folder-based ``Song`` nodes with `isDir = true`).
    public let artist: [Song]?

    /// Starred albums (represented as folder-based ``Song`` nodes with `isDir = true`).
    public let album: [Song]?

    /// Starred songs.
    public let song: [Song]?
}

// MARK: - Starred2

/// The collection of items starred by the current user.
///
/// Returned by ``SwiftSonicClient/getStarred2(musicFolderId:)``.
public struct Starred2: Codable, Sendable {
    /// Starred artists.
    public let artist: [ArtistID3]?

    /// Starred albums.
    public let album: [AlbumID3]?

    /// Starred songs.
    public let song: [Song]?
}
