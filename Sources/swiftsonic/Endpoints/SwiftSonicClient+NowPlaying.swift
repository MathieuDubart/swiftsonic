// SwiftSonicClient+NowPlaying.swift — SwiftSonic
//
// Now-playing endpoint: live view of currently active playback sessions.
//
// Covered: getNowPlaying

import Foundation

// MARK: - Now Playing endpoints

extension SwiftSonicClient {

    // MARK: getNowPlaying

    /// Returns what is currently being played by all users.
    ///
    /// ```swift
    /// let entries = try await client.getNowPlaying()
    /// for entry in entries {
    ///     print("\(entry.username) is playing \(entry.title) (\(entry.minutesAgo)m ago)")
    /// }
    /// ```
    ///
    /// - Returns: An array of ``NowPlayingEntry`` values, one per active playback session.
    ///   Returns an empty array when nothing is currently playing.
    public func getNowPlaying() async throws -> [NowPlayingEntry] {
        let envelope: SubsonicEnvelope<NowPlayingPayload> =
            try await performDecode(endpoint: "getNowPlaying", params: [:])
        return envelope.payload?.nowPlaying.entry ?? []
    }
}

// MARK: - Response payloads (internal)

struct NowPlayingContainer: Decodable, Sendable {
    let entry: [NowPlayingEntry]?
}

struct NowPlayingPayload: SubsonicPayload {
    static let payloadKey = "nowPlaying"
    let nowPlaying: NowPlayingContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        nowPlaying = try container.decode(NowPlayingContainer.self)
    }
}
