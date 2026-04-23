// SwiftSonicClient+Lyrics.swift — SwiftSonic
//
// Lyrics endpoint: fetch plain-text lyrics for a song.
//
// Covered: getLyrics

import Foundation

// MARK: - Lyrics endpoint

extension SwiftSonicClient {

    // MARK: getLyrics

    /// Returns the lyrics for a song, or `nil` if no lyrics are available.
    ///
    /// Both parameters are optional — pass at least one to get meaningful results.
    /// Returns `nil` when the server cannot match the query or returns an empty
    /// lyrics body.
    ///
    /// ```swift
    /// if let lyrics = try await client.getLyrics(artist: "Nine Inch Nails", title: "Hurt") {
    ///     print(lyrics.value ?? "")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - artist: The artist name to look up.
    ///   - title: The song title to look up.
    /// - Returns: A ``Lyrics`` value when the server returns non-empty lyrics text,
    ///   otherwise `nil`.
    public func getLyrics(artist: String? = nil, title: String? = nil) async throws -> Lyrics? {
        var params: [String: String] = [:]
        if let artist { params["artist"] = artist }
        if let title  { params["title"]  = title  }

        let envelope: SubsonicEnvelope<LyricsPayload> =
            try await performDecode(endpoint: "getLyrics", params: params)

        guard let lyrics = envelope.payload?.lyrics,
              let value  = lyrics.value, !value.isEmpty else {
            return nil
        }
        return lyrics
    }
}

// MARK: - Response payload (internal)

struct LyricsPayload: SubsonicPayload {
    static let payloadKey = "lyrics"
    let lyrics: Lyrics
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        lyrics = try container.decode(Lyrics.self)
    }
}
