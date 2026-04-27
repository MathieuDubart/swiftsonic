// SwiftSonicClient+Annotations.swift — SwiftSonic
//
// Annotation endpoints: star, unstar, setRating, scrobble.
//
// All four endpoints return an empty response on success.
// star/unstar accept multiple IDs so they use multiParams.

import Foundation

// MARK: - Annotation endpoints

public extension SwiftSonicClient {

    /// Stars one or more songs, albums, and/or artists.
    ///
    /// Starred items appear in `getStarred2` results.
    ///
    /// ```swift
    /// try await client.star(songIds: ["101", "201"])
    /// try await client.star(albumIds: ["10"])
    /// ```
    ///
    /// - Parameters:
    ///   - songIds: IDs of songs to star.
    ///   - albumIds: IDs of albums to star.
    ///   - artistIds: IDs of artists to star.
    func star(
        songIds: [String] = [],
        albumIds: [String] = [],
        artistIds: [String] = []
    ) async throws {
        var multiParams: [String: [String]] = [:]
        if !songIds.isEmpty    { multiParams["id"]       = songIds }
        if !albumIds.isEmpty   { multiParams["albumId"]  = albumIds }
        if !artistIds.isEmpty  { multiParams["artistId"] = artistIds }
        try await performVoid(endpoint: "star", multiParams: multiParams)
    }

    /// Removes the star from one or more songs, albums, and/or artists.
    ///
    /// - Parameters:
    ///   - songIds: IDs of songs to unstar.
    ///   - albumIds: IDs of albums to unstar.
    ///   - artistIds: IDs of artists to unstar.
    func unstar(
        songIds: [String] = [],
        albumIds: [String] = [],
        artistIds: [String] = []
    ) async throws {
        var multiParams: [String: [String]] = [:]
        if !songIds.isEmpty    { multiParams["id"]       = songIds }
        if !albumIds.isEmpty   { multiParams["albumId"]  = albumIds }
        if !artistIds.isEmpty  { multiParams["artistId"] = artistIds }
        try await performVoid(endpoint: "unstar", multiParams: multiParams)
    }

    // MARK: - Single-item convenience overloads

    /// Stars a single song.
    func star(songId: String) async throws {
        try await star(songIds: [songId], albumIds: [], artistIds: [])
    }

    /// Stars a single album.
    func star(albumId: String) async throws {
        try await star(songIds: [], albumIds: [albumId], artistIds: [])
    }

    /// Stars a single artist.
    func star(artistId: String) async throws {
        try await star(songIds: [], albumIds: [], artistIds: [artistId])
    }

    /// Removes the star from a single song.
    func unstar(songId: String) async throws {
        try await unstar(songIds: [songId], albumIds: [], artistIds: [])
    }

    /// Removes the star from a single album.
    func unstar(albumId: String) async throws {
        try await unstar(songIds: [], albumIds: [albumId], artistIds: [])
    }

    /// Removes the star from a single artist.
    func unstar(artistId: String) async throws {
        try await unstar(songIds: [], albumIds: [], artistIds: [artistId])
    }

    /// Sets the rating for a song, album, or other media item.
    ///
    /// - Parameters:
    ///   - id: The ID of the item to rate.
    ///   - rating: The rating, between 1 (lowest) and 5 (highest). Pass `0` to remove the rating.
    func setRating(id: String, rating: Int) async throws {
        try await performVoid(endpoint: "setRating", params: [
            "id": id,
            "rating": String(rating),
        ])
    }

    /// Registers a play event ("scrobble") for a song.
    ///
    /// Use this to report plays to Last.fm or to update the server's play statistics.
    ///
    /// - Parameters:
    ///   - id: The ID of the song that was played.
    ///   - time: The time at which the song was played. Defaults to the current time.
    ///   - submission: Whether to submit a "now playing" notification (`false`) or a
    ///     completed play ("submission", `true`). Default: `true`.
    func scrobble(id: String, time: Date? = nil, submission: Bool = true) async throws {
        var params: [String: String] = [
            "id": id,
            "submission": submission ? "true" : "false",
        ]
        if let t = time {
            // Subsonic expects milliseconds since epoch
            params["time"] = String(Int64(t.timeIntervalSince1970 * 1000))
        }
        try await performVoid(endpoint: "scrobble", params: params)
    }
}
