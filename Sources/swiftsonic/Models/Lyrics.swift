// Lyrics.swift — SwiftSonic
//
// Data model for song lyrics returned by the getLyrics endpoint.

import Foundation

// MARK: - Lyrics

/// Song lyrics returned by ``SwiftSonicClient/getLyrics(artist:title:)``.
///
/// If the server cannot find lyrics for the requested song, the method returns `nil`
/// rather than a `Lyrics` value with an empty ``value``.
public struct Lyrics: Decodable, Sendable {

    /// The artist name associated with these lyrics.
    public let artist: String?

    /// The song title associated with these lyrics.
    public let title: String?

    /// The full lyrics text.
    ///
    /// This is always non-empty when returned from
    /// ``SwiftSonicClient/getLyrics(artist:title:)`` — the method returns `nil`
    /// when the server responds with an absent or empty value.
    public let value: String?
}
