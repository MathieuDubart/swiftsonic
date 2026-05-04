// SwiftSonicClient+Lyrics.swift — SwiftSonic
//
// Lyrics endpoints: plain-text and structured (OpenSubsonic songLyrics extension).
//
// Covered: getLyrics, getLyricsBySongId

import Foundation

// MARK: - Lyrics endpoints

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

    // MARK: getLyricsBySongId

    /// Returns structured, optionally time-synced lyrics for a song by its ID.
    ///
    /// This endpoint is part of the OpenSubsonic `songLyrics` extension.
    /// The returned ``LyricsList`` may contain multiple lyric sets (e.g. different
    /// languages). Each ``StructuredLyrics`` indicates whether timing data is
    /// available via ``StructuredLyrics/synced``.
    ///
    /// SwiftSonic does not check server capability before calling this endpoint.
    /// Check support in your own code before calling if needed:
    /// ```swift
    /// let caps = try await client.loadCapabilities()
    /// guard caps.supports(.songLyrics) else { return }
    /// let list = try await client.getLyricsBySongId(id: song.id)
    /// for set in list.structuredLyrics {
    ///     print(set.lang, set.synced, set.line.count)
    /// }
    /// ```
    ///
    /// - Parameter id: The song ID (from ``Song/id``).
    /// - Returns: A ``LyricsList`` with zero or more ``StructuredLyrics`` sets.
    public func getLyricsBySongId(id: String) async throws -> LyricsList {
        let envelope: SubsonicEnvelope<LyricsListPayload> =
            try await performDecode(endpoint: "getLyricsBySongId", params: ["id": id])
        return try unwrapRequired(envelope.payload?.lyricsList, endpoint: "getLyricsBySongId")
    }
}

// MARK: - Response payloads (internal)

struct LyricsPayload: SubsonicPayload {
    static let payloadKey = "lyrics"
    let lyrics: Lyrics
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        lyrics = try container.decode(Lyrics.self)
    }
}

struct LyricsListPayload: SubsonicPayload {
    static let payloadKey = "lyricsList"
    let lyricsList: LyricsList
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        lyricsList = try container.decode(LyricsList.self)
    }
}
