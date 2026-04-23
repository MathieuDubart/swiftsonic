// MusicFolder.swift — SwiftSonic
//
// Data model for a server-side music library folder, returned by getMusicFolders.

import Foundation

/// A top-level music library folder on the server.
///
/// Returned by ``SwiftSonicClient/getMusicFolders()``.
public struct MusicFolder: Codable, Sendable, Identifiable {
    /// The unique identifier for this music folder.
    public let id: String

    /// The display name of the music folder.
    public let name: String?
}
