// SwiftSonicClient+Discovery.swift — SwiftSonic
//
// Discovery endpoints: artist/album info (folder-based variants) and
// recommendation endpoints powered by last.fm data.
//
// Covered: getArtistInfo, getAlbumInfo, getSimilarSongs, getSimilarSongs2, getTopSongs
//
// Spec: http://www.subsonic.org/pages/api.jsp

import Foundation

// MARK: - Discovery endpoints

public extension SwiftSonicClient {

    // MARK: getArtistInfo

    /// Returns biographical information for an artist (folder-based).
    ///
    /// > Important: Prefer ``getArtistInfo2(id:count:includeNotPresent:)`` unless you
    /// > specifically need folder-structure browsing. The "2" variant uses ID3-tagged
    /// > metadata and is better supported by modern servers.
    ///
    /// ```swift
    /// let info = try await client.getArtistInfo(id: "ar-1")
    /// print(info.biography ?? "No bio")
    /// ```
    ///
    /// - Parameters:
    ///   - id: The artist ID, from a folder-based browsing call such as ``getIndexes()``.
    ///   - count: Maximum number of similar artists to return. Defaults to 20.
    ///   - includeNotPresent: Also include similar artists not in the library. Defaults to false.
    func getArtistInfo(
        id: String,
        count: Int? = nil,
        includeNotPresent: Bool? = nil
    ) async throws -> ArtistInfo {
        var params: [String: String] = ["id": id]
        if let count { params["count"] = String(count) }
        if let inc = includeNotPresent { params["includeNotPresent"] = inc ? "true" : "false" }

        let envelope: SubsonicEnvelope<ArtistInfoPayload> =
            try await performDecode(endpoint: "getArtistInfo", params: params)
        return try unwrapRequired(envelope.payload?.artistInfo, endpoint: "getArtistInfo")
    }

    // MARK: getAlbumInfo

    /// Returns biographical information for an album (folder-based).
    ///
    /// > Important: Prefer ``getAlbumInfo2(id:)`` unless you specifically need
    /// > folder-structure browsing. The "2" variant uses ID3-tagged metadata.
    ///
    /// ```swift
    /// let info = try await client.getAlbumInfo(id: "al-5")
    /// print(info.notes ?? "No notes")
    /// ```
    ///
    /// - Parameter id: The album or song ID, from a folder-based browsing call.
    func getAlbumInfo(id: String) async throws -> AlbumInfo {
        // Both getAlbumInfo and getAlbumInfo2 return the same JSON key "albumInfo",
        // so AlbumInfo2Payload (payloadKey = "albumInfo") can be reused.
        let envelope: SubsonicEnvelope<AlbumInfo2Payload> =
            try await performDecode(endpoint: "getAlbumInfo", params: ["id": id])
        return try unwrapRequired(envelope.payload?.albumInfo, endpoint: "getAlbumInfo")
    }

    // MARK: getSimilarSongs

    /// Returns songs similar to the given artist, album, or song (folder-based).
    ///
    /// Similar songs are drawn from the same artist and from similar artists via last.fm.
    ///
    /// > Important: Prefer ``getSimilarSongs2(id:count:)`` when targeting servers with
    /// > ID3-tagged libraries. The non-"2" variant uses folder-based organisation.
    ///
    /// ```swift
    /// let songs = try await client.getSimilarSongs(id: "ar-1", count: 10)
    /// ```
    ///
    /// - Parameters:
    ///   - id: An artist, album, or song ID (folder-based).
    ///   - count: Maximum number of songs to return. Defaults to 50.
    func getSimilarSongs(id: String, count: Int? = nil) async throws -> [Song] {
        var params: [String: String] = ["id": id]
        if let count { params["count"] = String(count) }

        let envelope: SubsonicEnvelope<SimilarSongsPayload> =
            try await performDecode(endpoint: "getSimilarSongs", params: params)
        return envelope.payload?.similarSongs.song ?? []
    }

    // MARK: getSimilarSongs2

    /// Returns songs similar to the given artist (ID3-based).
    ///
    /// ```swift
    /// let songs = try await client.getSimilarSongs2(id: "3GSnSEURz17ltddsamzmSD", count: 10)
    /// ```
    ///
    /// - Parameters:
    ///   - id: An artist ID (from ``ArtistID3/id``).
    ///   - count: Maximum number of songs to return. Defaults to 50.
    func getSimilarSongs2(id: String, count: Int? = nil) async throws -> [Song] {
        var params: [String: String] = ["id": id]
        if let count { params["count"] = String(count) }

        let envelope: SubsonicEnvelope<SimilarSongs2Payload> =
            try await performDecode(endpoint: "getSimilarSongs2", params: params)
        return envelope.payload?.similarSongs2.song ?? []
    }

    // MARK: getTopSongs

    /// Returns top songs for a given artist name, sourced from last.fm play counts.
    ///
    /// ```swift
    /// let songs = try await client.getTopSongs(artist: "Nine Inch Nails", count: 5)
    /// ```
    ///
    /// - Parameters:
    ///   - artist: The exact artist name (case-sensitive, must match the server's library).
    ///   - count: Maximum number of songs to return. Defaults to 50.
    func getTopSongs(artist: String, count: Int? = nil) async throws -> [Song] {
        var params: [String: String] = ["artist": artist]
        if let count { params["count"] = String(count) }

        let envelope: SubsonicEnvelope<TopSongsPayload> =
            try await performDecode(endpoint: "getTopSongs", params: params)
        return envelope.payload?.topSongs.song ?? []
    }
}

// MARK: - Response payloads (internal)

struct ArtistInfoPayload: SubsonicPayload {
    static let payloadKey = "artistInfo"
    let artistInfo: ArtistInfo
    init(from decoder: any Decoder) throws {
        artistInfo = try decoder.singleValueContainer().decode(ArtistInfo.self)
    }
}

struct SimilarSongsPayload: SubsonicPayload {
    static let payloadKey = "similarSongs"
    let similarSongs: SongsContainer
    init(from decoder: any Decoder) throws {
        similarSongs = try decoder.singleValueContainer().decode(SongsContainer.self)
    }
}

struct SimilarSongs2Payload: SubsonicPayload {
    static let payloadKey = "similarSongs2"
    let similarSongs2: SongsContainer
    init(from decoder: any Decoder) throws {
        similarSongs2 = try decoder.singleValueContainer().decode(SongsContainer.self)
    }
}

struct TopSongsPayload: SubsonicPayload {
    static let payloadKey = "topSongs"
    let topSongs: SongsContainer
    init(from decoder: any Decoder) throws {
        topSongs = try decoder.singleValueContainer().decode(SongsContainer.self)
    }
}
