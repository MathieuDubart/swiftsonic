// SwiftSonicClient+Browsing.swift — SwiftSonic
//
// Browsing endpoints: methods for navigating the music library.
//
// Covered here: getArtists, getMusicFolders
// (getArtist, getAlbum, getSong, getGenres, etc. will be added in Step 3)

import Foundation

// MARK: - Browsing endpoints

extension SwiftSonicClient {

    // MARK: getArtists

    /// Returns all artists, grouped by index letter.
    ///
    /// Uses ID3-tagged metadata. Equivalent to browsing "Artists" in a music app.
    ///
    /// ```swift
    /// let indexes = try await client.getArtists()
    /// for index in indexes {
    ///     print("\(index.name): \(index.artist.map(\.name).joined(separator: ", "))")
    /// }
    /// ```
    ///
    /// - Parameter musicFolderId: If provided, limits results to the given music folder.
    /// - Returns: An array of ``ArtistIndex`` buckets, one per index letter.
    public func getArtists(musicFolderId: String? = nil) async throws -> [ArtistIndex] {
        var params: [String: String] = [:]
        if let id = musicFolderId { params["musicFolderId"] = id }

        let envelope: SubsonicEnvelope<ArtistsPayload> =
            try await performDecode(endpoint: "getArtists", params: params)
        return envelope.payload?.artists.index ?? []
    }

    // MARK: getMusicFolders

    /// Returns all music folders configured on the server.
    ///
    /// Use the folder ID to scope other browsing calls (e.g. ``getArtists(musicFolderId:)``).
    ///
    /// ```swift
    /// let folders = try await client.getMusicFolders()
    /// ```
    public func getMusicFolders() async throws -> [MusicFolder] {
        let envelope: SubsonicEnvelope<MusicFoldersPayload> =
            try await performDecode(endpoint: "getMusicFolders", params: [:])
        return envelope.payload?.musicFolders.musicFolder ?? []
    }
}

// MARK: - Response payloads (internal)

// getArtists response structure:
// { "artists": { "ignoredArticles": "The ...", "index": [ { "name": "A", "artist": [...] } ] } }
struct ArtistsContainer: Decodable {
    let ignoredArticles: String?
    let index: [ArtistIndex]
}

struct ArtistsPayload: SubsonicPayload {
    static let payloadKey = "artists"
    let artists: ArtistsContainer
    // Custom decoding: the payload key maps to the container directly
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        artists = try container.decode(ArtistsContainer.self)
    }
}

// getMusicFolders response structure:
// { "musicFolders": { "musicFolder": [ { "id": "1", "name": "Music" } ] } }
struct MusicFoldersContainer: Decodable {
    let musicFolder: [MusicFolder]
}

struct MusicFoldersPayload: SubsonicPayload {
    static let payloadKey = "musicFolders"
    let musicFolders: MusicFoldersContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        musicFolders = try container.decode(MusicFoldersContainer.self)
    }
}
