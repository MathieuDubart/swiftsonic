// Directory.swift — SwiftSonic
//
// Data model for music directories, returned by getMusicDirectory.
//
// A directory contains child entries which can be either subdirectories
// or audio files — both are represented by the Song type (with isDir: Bool).

import Foundation

// MARK: - MusicDirectory

/// A music library directory, as returned by ``SwiftSonicClient/getMusicDirectory(id:)``.
public struct MusicDirectory: Codable, Sendable, Identifiable {
    /// The unique identifier for this directory.
    public let id: String

    /// The parent directory ID, if any.
    public let parent: String?

    /// The directory name.
    public let name: String

    /// Date starred by the current user, if starred.
    public let starred: Date?

    /// User rating (1–5).
    public let userRating: Int?

    /// Average community rating.
    public let averageRating: Double?

    /// Play count for this directory node.
    public let playCount: Int?

    /// Child entries (subdirectories and/or audio files).
    ///
    /// Check ``Song/isDir`` on each child to distinguish directories from files.
    public let child: [Song]?
}
