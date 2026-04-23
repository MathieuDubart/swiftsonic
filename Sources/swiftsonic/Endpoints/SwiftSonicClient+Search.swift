// SwiftSonicClient+Search.swift — SwiftSonic
//
// Search endpoints: search2 (folder-based legacy) and search3 (ID3-based, preferred).

import Foundation

// MARK: - Private payloads

private struct Search2Payload: SubsonicPayload {
    static let payloadKey = "searchResult2"
    let searchResult2: SearchResult2
    init(from decoder: any Decoder) throws {
        searchResult2 = try decoder.singleValueContainer().decode(SearchResult2.self)
    }
}

private struct Search3Payload: SubsonicPayload {
    static let payloadKey = "searchResult3"
    let searchResult3: SearchResult3

    init(from decoder: any Decoder) throws {
        searchResult3 = try decoder.singleValueContainer().decode(SearchResult3.self)
    }
}

// MARK: - Search endpoints

public extension SwiftSonicClient {

    /// Searches for artists, albums, and songs using folder-based organisation.
    ///
    /// > Important: Prefer ``search3(_:artistCount:artistOffset:albumCount:albumOffset:songCount:songOffset:musicFolderId:)``
    /// > unless you specifically need folder-structure browsing. `search3` uses ID3-tagged
    /// > metadata and returns typed ``ArtistID3`` and ``AlbumID3`` values.
    ///
    /// ```swift
    /// let results = try await client.search2("bohemian")
    /// print(results.song?.first?.title) // "Bohemian Rhapsody"
    /// ```
    ///
    /// - Parameters:
    ///   - query: The search query string.
    ///   - artistCount: Maximum number of artists to return. Default: 20.
    ///   - artistOffset: Search offset for artists (for paging). Default: 0.
    ///   - albumCount: Maximum number of albums to return. Default: 20.
    ///   - albumOffset: Search offset for albums (for paging). Default: 0.
    ///   - songCount: Maximum number of songs to return. Default: 20.
    ///   - songOffset: Search offset for songs (for paging). Default: 0.
    ///   - musicFolderId: Only return results in the music folder with the given ID.
    /// - Returns: A ``SearchResult2`` containing folder-based artists, albums, and songs.
    func search2(
        _ query: String,
        artistCount: Int? = nil,
        artistOffset: Int? = nil,
        albumCount: Int? = nil,
        albumOffset: Int? = nil,
        songCount: Int? = nil,
        songOffset: Int? = nil,
        musicFolderId: String? = nil
    ) async throws -> SearchResult2 {
        var params: [String: String] = ["query": query]
        if let v = artistCount   { params["artistCount"]   = String(v) }
        if let v = artistOffset  { params["artistOffset"]  = String(v) }
        if let v = albumCount    { params["albumCount"]    = String(v) }
        if let v = albumOffset   { params["albumOffset"]   = String(v) }
        if let v = songCount     { params["songCount"]     = String(v) }
        if let v = songOffset    { params["songOffset"]    = String(v) }
        if let v = musicFolderId { params["musicFolderId"] = v }

        let envelope: SubsonicEnvelope<Search2Payload> =
            try await performDecode(endpoint: "search2", params: params)

        guard let result = envelope.payload?.searchResult2 else {
            throw SwiftSonicError.decoding(
                DecodingError.valueNotFound(
                    SearchResult2.self,
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Missing payload in search2 response"
                    )
                ),
                rawData: Data()
            )
        }
        return result
    }

    /// Searches for artists, albums, and songs matching the given query.
    ///
    /// All count/offset parameters default to the Subsonic server defaults when omitted.
    ///
    /// ```swift
    /// let results = try await client.search3("bohemian")
    /// print(results.artist?.first?.name)  // "Queen"
    /// print(results.song?.first?.title)   // "Bohemian Rhapsody"
    /// ```
    ///
    /// - Parameters:
    ///   - query: The search query string.
    ///   - artistCount: Maximum number of artists to return. Default: 20.
    ///   - artistOffset: Search offset for artists (for paging). Default: 0.
    ///   - albumCount: Maximum number of albums to return. Default: 20.
    ///   - albumOffset: Search offset for albums (for paging). Default: 0.
    ///   - songCount: Maximum number of songs to return. Default: 20.
    ///   - songOffset: Search offset for songs (for paging). Default: 0.
    ///   - musicFolderId: Only return results in the music folder with the given ID.
    /// - Returns: A ``SearchResult3`` containing matched artists, albums, and songs.
    func search3(
        _ query: String,
        artistCount: Int? = nil,
        artistOffset: Int? = nil,
        albumCount: Int? = nil,
        albumOffset: Int? = nil,
        songCount: Int? = nil,
        songOffset: Int? = nil,
        musicFolderId: String? = nil
    ) async throws -> SearchResult3 {
        var params: [String: String] = ["query": query]
        if let v = artistCount    { params["artistCount"]    = String(v) }
        if let v = artistOffset   { params["artistOffset"]   = String(v) }
        if let v = albumCount     { params["albumCount"]     = String(v) }
        if let v = albumOffset    { params["albumOffset"]    = String(v) }
        if let v = songCount      { params["songCount"]      = String(v) }
        if let v = songOffset     { params["songOffset"]     = String(v) }
        if let v = musicFolderId  { params["musicFolderId"]  = v }

        let envelope: SubsonicEnvelope<Search3Payload> =
            try await performDecode(endpoint: "search3", params: params)

        guard let result = envelope.payload?.searchResult3 else {
            throw SwiftSonicError.decoding(
                DecodingError.valueNotFound(
                    SearchResult3.self,
                    DecodingError.Context(codingPath: [], debugDescription: "Missing payload in search3 response")
                ),
                rawData: Data()
            )
        }
        return result
    }
}
