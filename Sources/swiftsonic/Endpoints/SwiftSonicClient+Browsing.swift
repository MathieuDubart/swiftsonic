// SwiftSonicClient+Browsing.swift — SwiftSonic
//
// Browsing endpoints: navigate the music library by artists, albums, songs,
// directories, and genres.
//
// Covered: getMusicFolders, getArtists, getArtist, getAlbum, getSong,
//          getGenres, getIndexes, getMusicDirectory, getArtistInfo2, getAlbumInfo2

import Foundation

// MARK: - Browsing endpoints

extension SwiftSonicClient {

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

    // MARK: getArtists

    /// Returns all artists grouped by index letter (ID3-based).
    ///
    /// ```swift
    /// let indexes = try await client.getArtists()
    /// for index in indexes {
    ///     print("\(index.name): \(index.artist.map(\.name).joined(separator: ", "))")
    /// }
    /// ```
    ///
    /// - Parameter musicFolderId: Limit results to this music folder.
    public func getArtists(musicFolderId: String? = nil) async throws -> [ArtistIndex] {
        var params: [String: String] = [:]
        if let id = musicFolderId { params["musicFolderId"] = id }

        let envelope: SubsonicEnvelope<ArtistsPayload> =
            try await performDecode(endpoint: "getArtists", params: params)
        return envelope.payload?.artists.index ?? []
    }

    // MARK: getArtist

    /// Returns details and album list for a single artist (ID3-based).
    ///
    /// ```swift
    /// let artist = try await client.getArtist(id: "ar-1")
    /// for album in artist.album ?? [] {
    ///     print(album.name)
    /// }
    /// ```
    ///
    /// - Parameter id: The artist ID (from ``ArtistID3/id``).
    public func getArtist(id: String) async throws -> ArtistID3 {
        let envelope: SubsonicEnvelope<ArtistPayload> =
            try await performDecode(endpoint: "getArtist", params: ["id": id])
        return try unwrapPayload(envelope.payload?.artist, endpoint: "getArtist")
    }

    // MARK: getAlbum

    /// Returns details and song list for a single album (ID3-based).
    ///
    /// ```swift
    /// let album = try await client.getAlbum(id: "al-5")
    /// for song in album.song ?? [] {
    ///     print(song.title)
    /// }
    /// ```
    ///
    /// - Parameter id: The album ID (from ``AlbumID3/id``).
    public func getAlbum(id: String) async throws -> AlbumID3 {
        let envelope: SubsonicEnvelope<AlbumPayload> =
            try await performDecode(endpoint: "getAlbum", params: ["id": id])
        return try unwrapPayload(envelope.payload?.album, endpoint: "getAlbum")
    }

    // MARK: getSong

    /// Returns metadata for a single song.
    ///
    /// ```swift
    /// let song = try await client.getSong(id: "so-42")
    /// print("\(song.title) — \(song.artist ?? "Unknown")")
    /// ```
    ///
    /// - Parameter id: The song ID (from ``Song/id``).
    public func getSong(id: String) async throws -> Song {
        let envelope: SubsonicEnvelope<SongPayload> =
            try await performDecode(endpoint: "getSong", params: ["id": id])
        return try unwrapPayload(envelope.payload?.song, endpoint: "getSong")
    }

    // MARK: getGenres

    /// Returns all genres with song and album counts.
    ///
    /// ```swift
    /// let genres = try await client.getGenres()
    /// for genre in genres.sorted(by: { $0.songCount > $1.songCount }) {
    ///     print("\(genre.value): \(genre.songCount) songs")
    /// }
    /// ```
    public func getGenres() async throws -> [Genre] {
        let envelope: SubsonicEnvelope<GenresPayload> =
            try await performDecode(endpoint: "getGenres", params: [:])
        return envelope.payload?.genres.genre ?? []
    }

    // MARK: getIndexes

    /// Returns all artists using folder-based (non-ID3) browsing.
    ///
    /// Prefer ``getArtists(musicFolderId:)`` for ID3-tagged metadata.
    ///
    /// - Parameters:
    ///   - musicFolderId: Limit results to this music folder.
    ///   - ifModifiedSince: Only return results modified after this date.
    public func getIndexes(
        musicFolderId: String? = nil,
        ifModifiedSince: Date? = nil
    ) async throws -> Indexes {
        var params: [String: String] = [:]
        if let id = musicFolderId { params["musicFolderId"] = id }
        if let date = ifModifiedSince {
            params["ifModifiedSince"] = String(Int(date.timeIntervalSince1970 * 1000))
        }
        let envelope: SubsonicEnvelope<IndexesPayload> =
            try await performDecode(endpoint: "getIndexes", params: params)
        return try unwrapPayload(envelope.payload?.indexes, endpoint: "getIndexes")
    }

    // MARK: getMusicDirectory

    /// Returns the contents of a music directory.
    ///
    /// ```swift
    /// let dir = try await client.getMusicDirectory(id: "dir-1")
    /// for child in dir.child ?? [] {
    ///     print(child.isDir == true ? "📁 \(child.title)" : "🎵 \(child.title)")
    /// }
    /// ```
    ///
    /// - Parameter id: The directory ID.
    public func getMusicDirectory(id: String) async throws -> MusicDirectory {
        let envelope: SubsonicEnvelope<MusicDirectoryPayload> =
            try await performDecode(endpoint: "getMusicDirectory", params: ["id": id])
        return try unwrapPayload(envelope.payload?.directory, endpoint: "getMusicDirectory")
    }

    // MARK: getArtistInfo2

    /// Returns biographical information for an artist (ID3-based).
    ///
    /// - Parameters:
    ///   - id: The artist ID.
    ///   - count: Maximum number of similar artists to return. Defaults to 20.
    ///   - includeNotPresent: Also include similar artists not in the library.
    public func getArtistInfo2(
        id: String,
        count: Int? = nil,
        includeNotPresent: Bool? = nil
    ) async throws -> ArtistInfo {
        var params: [String: String] = ["id": id]
        if let count { params["count"] = String(count) }
        if let inc = includeNotPresent { params["includeNotPresent"] = inc ? "true" : "false" }

        let envelope: SubsonicEnvelope<ArtistInfo2Payload> =
            try await performDecode(endpoint: "getArtistInfo2", params: params)
        return try unwrapPayload(envelope.payload?.artistInfo2, endpoint: "getArtistInfo2")
    }

    // MARK: getAlbumInfo2

    /// Returns biographical information for an album (ID3-based).
    ///
    /// - Parameter id: The album ID.
    public func getAlbumInfo2(id: String) async throws -> AlbumInfo {
        let envelope: SubsonicEnvelope<AlbumInfo2Payload> =
            try await performDecode(endpoint: "getAlbumInfo2", params: ["id": id])
        return try unwrapPayload(envelope.payload?.albumInfo, endpoint: "getAlbumInfo2")
    }

    // MARK: - Private helpers

    private func unwrapPayload<T>(_ value: T?, endpoint: String) throws -> T {
        guard let value else {
            throw SwiftSonicError.decoding(
                DecodingError.valueNotFound(
                    T.self,
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Missing payload in \(endpoint) response"
                    )
                ),
                rawData: Data()
            )
        }
        return value
    }
}

// MARK: - Response payloads (internal)

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

struct ArtistsContainer: Decodable {
    let ignoredArticles: String?
    let index: [ArtistIndex]
}

struct ArtistsPayload: SubsonicPayload {
    static let payloadKey = "artists"
    let artists: ArtistsContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        artists = try container.decode(ArtistsContainer.self)
    }
}

struct ArtistPayload: SubsonicPayload {
    static let payloadKey = "artist"
    let artist: ArtistID3
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        artist = try container.decode(ArtistID3.self)
    }
}

struct AlbumPayload: SubsonicPayload {
    static let payloadKey = "album"
    let album: AlbumID3
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        album = try container.decode(AlbumID3.self)
    }
}

struct SongPayload: SubsonicPayload {
    static let payloadKey = "song"
    let song: Song
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        song = try container.decode(Song.self)
    }
}

struct GenresContainer: Decodable {
    let genre: [Genre]
}

struct GenresPayload: SubsonicPayload {
    static let payloadKey = "genres"
    let genres: GenresContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        genres = try container.decode(GenresContainer.self)
    }
}

struct IndexesPayload: SubsonicPayload {
    static let payloadKey = "indexes"
    let indexes: Indexes
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        indexes = try container.decode(Indexes.self)
    }
}

struct MusicDirectoryPayload: SubsonicPayload {
    static let payloadKey = "directory"
    let directory: MusicDirectory
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        directory = try container.decode(MusicDirectory.self)
    }
}

struct ArtistInfo2Payload: SubsonicPayload {
    static let payloadKey = "artistInfo2"
    let artistInfo2: ArtistInfo
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        artistInfo2 = try container.decode(ArtistInfo.self)
    }
}

struct AlbumInfo2Payload: SubsonicPayload {
    static let payloadKey = "albumInfo"
    let albumInfo: AlbumInfo
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        albumInfo = try container.decode(AlbumInfo.self)
    }
}
