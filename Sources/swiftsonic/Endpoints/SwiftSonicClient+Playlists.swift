// SwiftSonicClient+Playlists.swift — SwiftSonic
//
// Playlist endpoints: getPlaylists, getPlaylist, createPlaylist,
// updatePlaylist, deletePlaylist.

import Foundation

// MARK: - Private payloads

private struct PlaylistsPayload: SubsonicPayload {
    static let payloadKey = "playlists"
    let playlists: [Playlist]

    init(from decoder: any Decoder) throws {
        struct Container: Decodable {
            let playlist: [Playlist]?
        }
        let container = try decoder.singleValueContainer().decode(Container.self)
        playlists = container.playlist ?? []
    }
}

private struct PlaylistPayload: SubsonicPayload {
    static let payloadKey = "playlist"
    let playlist: PlaylistWithSongs

    init(from decoder: any Decoder) throws {
        playlist = try decoder.singleValueContainer().decode(PlaylistWithSongs.self)
    }
}

// MARK: - Playlist endpoints

public extension SwiftSonicClient {

    /// Returns all playlists accessible by the current user.
    ///
    /// - Parameter username: If specified, returns playlists for that user (admin only).
    /// - Returns: An array of ``Playlist`` objects.
    func getPlaylists(username: String? = nil) async throws -> [Playlist] {
        var params: [String: String] = [:]
        if let v = username { params["username"] = v }

        let envelope: SubsonicEnvelope<PlaylistsPayload> =
            try await performDecode(endpoint: "getPlaylists", params: params)
        return envelope.payload?.playlists ?? []
    }

    /// Returns a playlist with its full track list.
    ///
    /// - Parameter id: The ID of the playlist to fetch.
    /// - Returns: A ``PlaylistWithSongs`` containing the playlist metadata and its entries.
    func getPlaylist(id: String) async throws -> PlaylistWithSongs {
        let envelope: SubsonicEnvelope<PlaylistPayload> =
            try await performDecode(endpoint: "getPlaylist", params: ["id": id])

        guard let playlist = envelope.payload?.playlist else {
            throw SwiftSonicError.decoding(
                DecodingError.valueNotFound(
                    PlaylistWithSongs.self,
                    DecodingError.Context(codingPath: [], debugDescription: "Missing payload in getPlaylist response")
                ),
                rawData: Data()
            )
        }
        return playlist
    }

    /// Creates a new playlist.
    ///
    /// - Parameters:
    ///   - name: The name of the playlist to create.
    ///   - songIds: Optional list of song IDs to add to the new playlist.
    /// - Returns: The newly created ``PlaylistWithSongs``.
    @discardableResult
    func createPlaylist(name: String, songIds: [String] = []) async throws -> PlaylistWithSongs {
        let params: [String: String] = ["name": name]
        let multiParams: [String: [String]] = songIds.isEmpty ? [:] : ["songId": songIds]

        let envelope: SubsonicEnvelope<PlaylistPayload> =
            try await performDecode(endpoint: "createPlaylist", params: params, multiParams: multiParams)

        guard let playlist = envelope.payload?.playlist else {
            throw SwiftSonicError.decoding(
                DecodingError.valueNotFound(
                    PlaylistWithSongs.self,
                    DecodingError.Context(codingPath: [], debugDescription: "Missing payload in createPlaylist response")
                ),
                rawData: Data()
            )
        }
        return playlist
    }

    /// Updates an existing playlist.
    ///
    /// All parameters except `id` are optional. Only the provided parameters are sent.
    ///
    /// - Parameters:
    ///   - id: The ID of the playlist to update.
    ///   - name: New name for the playlist.
    ///   - comment: New comment/description.
    ///   - isPublic: Whether the playlist should be publicly visible.
    ///   - songIdsToAdd: Song IDs to append to the playlist.
    ///   - songIndexesToRemove: Zero-based indexes of songs to remove.
    func updatePlaylist(
        id: String,
        name: String? = nil,
        comment: String? = nil,
        isPublic: Bool? = nil,
        songIdsToAdd: [String] = [],
        songIndexesToRemove: [Int] = []
    ) async throws {
        var params: [String: String] = ["playlistId": id]
        if let v = name      { params["name"]    = v }
        if let v = comment   { params["comment"] = v }
        if let v = isPublic  { params["public"]  = v ? "true" : "false" }

        var multiParams: [String: [String]] = [:]
        if !songIdsToAdd.isEmpty         { multiParams["songIdToAdd"]         = songIdsToAdd }
        if !songIndexesToRemove.isEmpty  { multiParams["songIndexToRemove"]   = songIndexesToRemove.map(String.init) }

        try await performVoid(endpoint: "updatePlaylist", params: params, multiParams: multiParams)
    }

    /// Deletes a playlist.
    ///
    /// - Parameter id: The ID of the playlist to delete.
    func deletePlaylist(id: String) async throws {
        try await performVoid(endpoint: "deletePlaylist", params: ["id": id])
    }
}
