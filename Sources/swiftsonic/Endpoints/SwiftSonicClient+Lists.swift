// SwiftSonicClient+Lists.swift — SwiftSonic
//
// List endpoints: curated and filtered collections of albums and songs.
//
// Covered: getAlbumList2, getRandomSongs, getSongsByGenre, getStarred2,
//          getAlbumList (folder-based legacy), getStarred (folder-based legacy)

import Foundation

// MARK: - Album list type

/// The ordering or filter strategy for ``SwiftSonicClient/getAlbumList2(type:size:offset:fromYear:toYear:genre:musicFolderId:)``.
public enum AlbumListType: String, Sendable {
    /// Randomly selected albums.
    case random
    /// Most recently added albums.
    case newest
    /// Highest rated albums.
    case highest
    /// Most frequently played albums.
    case frequent
    /// Most recently played albums.
    case recent
    /// Alphabetically by album name.
    case alphabeticalByName
    /// Alphabetically by artist name.
    case alphabeticalByArtist
    /// Albums starred by the current user.
    case starred
    /// Albums from a specific year range (requires `fromYear` and `toYear`).
    case byYear
    /// Albums tagged with a specific genre (requires `genre`).
    case byGenre
}

// MARK: - Lists endpoints

extension SwiftSonicClient {

    // MARK: getAlbumList2

    /// Returns a list of albums sorted or filtered by the given type (ID3-based).
    ///
    /// ```swift
    /// // 10 most recently added albums
    /// let recent = try await client.getAlbumList2(type: .newest, size: 10)
    ///
    /// // Albums from the 1970s
    /// let seventies = try await client.getAlbumList2(type: .byYear, fromYear: 1970, toYear: 1979)
    ///
    /// // Rock albums
    /// let rock = try await client.getAlbumList2(type: .byGenre, genre: "Rock")
    /// ```
    ///
    /// - Parameters:
    ///   - type: The list ordering strategy.
    ///   - size: Maximum number of albums to return (1–500). Defaults to 10.
    ///   - offset: Offset into the result set for pagination. Defaults to 0.
    ///   - fromYear: Start year (required when `type` is `.byYear`).
    ///   - toYear: End year (required when `type` is `.byYear`).
    ///   - genre: Genre filter (required when `type` is `.byGenre`).
    ///   - musicFolderId: Limit results to this music folder.
    public func getAlbumList2(
        type: AlbumListType,
        size: Int? = nil,
        offset: Int? = nil,
        fromYear: Int? = nil,
        toYear: Int? = nil,
        genre: String? = nil,
        musicFolderId: String? = nil
    ) async throws -> [AlbumID3] {
        var params: [String: String] = ["type": type.rawValue]
        if let size { params["size"] = String(size) }
        if let offset { params["offset"] = String(offset) }
        if let fromYear { params["fromYear"] = String(fromYear) }
        if let toYear { params["toYear"] = String(toYear) }
        if let genre { params["genre"] = genre }
        if let id = musicFolderId { params["musicFolderId"] = id }

        let envelope: SubsonicEnvelope<AlbumList2Payload> =
            try await performDecode(endpoint: "getAlbumList2", params: params)
        return envelope.payload?.albumList2.album ?? []
    }

    // MARK: getRandomSongs

    /// Returns a randomly selected set of songs.
    ///
    /// ```swift
    /// let songs = try await client.getRandomSongs(size: 20, genre: "Jazz")
    /// ```
    ///
    /// - Parameters:
    ///   - size: Number of songs to return (1–500). Defaults to 10.
    ///   - genre: Limit to songs of this genre.
    ///   - fromYear: Limit to songs released from this year.
    ///   - toYear: Limit to songs released up to this year.
    ///   - musicFolderId: Limit results to this music folder.
    public func getRandomSongs(
        size: Int? = nil,
        genre: String? = nil,
        fromYear: Int? = nil,
        toYear: Int? = nil,
        musicFolderId: String? = nil
    ) async throws -> [Song] {
        var params: [String: String] = [:]
        if let size { params["size"] = String(size) }
        if let genre { params["genre"] = genre }
        if let fromYear { params["fromYear"] = String(fromYear) }
        if let toYear { params["toYear"] = String(toYear) }
        if let id = musicFolderId { params["musicFolderId"] = id }

        let envelope: SubsonicEnvelope<RandomSongsPayload> =
            try await performDecode(endpoint: "getRandomSongs", params: params)
        return envelope.payload?.randomSongs.song ?? []
    }

    // MARK: getSongsByGenre

    /// Returns songs tagged with a specific genre.
    ///
    /// ```swift
    /// let songs = try await client.getSongsByGenre("Electronic", count: 50)
    /// ```
    ///
    /// - Parameters:
    ///   - genre: The genre name (case-sensitive, must match exactly).
    ///   - count: Number of songs to return (1–500). Defaults to 10.
    ///   - offset: Offset for pagination. Defaults to 0.
    ///   - musicFolderId: Limit results to this music folder.
    public func getSongsByGenre(
        _ genre: String,
        count: Int? = nil,
        offset: Int? = nil,
        musicFolderId: String? = nil
    ) async throws -> [Song] {
        var params: [String: String] = ["genre": genre]
        if let count { params["count"] = String(count) }
        if let offset { params["offset"] = String(offset) }
        if let id = musicFolderId { params["musicFolderId"] = id }

        let envelope: SubsonicEnvelope<SongsByGenrePayload> =
            try await performDecode(endpoint: "getSongsByGenre", params: params)
        return envelope.payload?.songsByGenre.song ?? []
    }

    // MARK: getStarred2

    /// Returns all items (artists, albums, songs) starred by the current user (ID3-based).
    ///
    /// ```swift
    /// let starred = try await client.getStarred2()
    /// print("Starred songs: \(starred.song?.count ?? 0)")
    /// ```
    ///
    /// - Parameter musicFolderId: Limit results to this music folder.
    public func getStarred2(musicFolderId: String? = nil) async throws -> Starred2 {
        var params: [String: String] = [:]
        if let id = musicFolderId { params["musicFolderId"] = id }

        let envelope: SubsonicEnvelope<Starred2Payload> =
            try await performDecode(endpoint: "getStarred2", params: params)
        return try unwrapListPayload(envelope.payload?.starred2, endpoint: "getStarred2")
    }

    // MARK: getAlbumList (folder-based)

    /// Returns a list of albums sorted or filtered by the given type (folder-based).
    ///
    /// Album entries are represented as ``Song`` values with ``Song/isDir`` set to `true`.
    ///
    /// > Important: Prefer ``getAlbumList2(type:size:offset:fromYear:toYear:genre:musicFolderId:)``
    /// > unless you specifically need folder-structure browsing. The "2" variant uses
    /// > ID3-tagged metadata and returns typed ``AlbumID3`` values.
    ///
    /// - Parameters:
    ///   - type: The list ordering strategy.
    ///   - size: Maximum number of albums to return (1–500). Defaults to 10.
    ///   - offset: Offset into the result set for pagination. Defaults to 0.
    ///   - fromYear: Start year (required when `type` is `.byYear`).
    ///   - toYear: End year (required when `type` is `.byYear`).
    ///   - genre: Genre filter (required when `type` is `.byGenre`).
    ///   - musicFolderId: Limit results to this music folder.
    public func getAlbumList(
        type: AlbumListType,
        size: Int? = nil,
        offset: Int? = nil,
        fromYear: Int? = nil,
        toYear: Int? = nil,
        genre: String? = nil,
        musicFolderId: String? = nil
    ) async throws -> [Song] {
        var params: [String: String] = ["type": type.rawValue]
        if let size { params["size"] = String(size) }
        if let offset { params["offset"] = String(offset) }
        if let fromYear { params["fromYear"] = String(fromYear) }
        if let toYear { params["toYear"] = String(toYear) }
        if let genre { params["genre"] = genre }
        if let id = musicFolderId { params["musicFolderId"] = id }

        let envelope: SubsonicEnvelope<AlbumListPayload> =
            try await performDecode(endpoint: "getAlbumList", params: params)
        return envelope.payload?.albumList.album ?? []
    }

    // MARK: getStarred (folder-based)

    /// Returns all items (artists, albums, songs) starred by the current user (folder-based).
    ///
    /// Artist and album entries are represented as ``Song`` values with ``Song/isDir``
    /// set to `true`, consistent with the folder-based browsing model.
    ///
    /// > Important: Prefer ``getStarred2(musicFolderId:)`` unless you specifically need
    /// > folder-structure browsing. The "2" variant returns typed ``ArtistID3`` and
    /// > ``AlbumID3`` values.
    ///
    /// - Parameter musicFolderId: Limit results to this music folder.
    public func getStarred(musicFolderId: String? = nil) async throws -> Starred {
        var params: [String: String] = [:]
        if let id = musicFolderId { params["musicFolderId"] = id }

        let envelope: SubsonicEnvelope<StarredPayload> =
            try await performDecode(endpoint: "getStarred", params: params)
        return try unwrapListPayload(envelope.payload?.starred, endpoint: "getStarred")
    }

    // MARK: - Private helpers

    private func unwrapListPayload<T>(_ value: T?, endpoint: String) throws -> T {
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

struct AlbumList2Container: Decodable, Sendable {
    let album: [AlbumID3]?
}

struct AlbumList2Payload: SubsonicPayload {
    static let payloadKey = "albumList2"
    let albumList2: AlbumList2Container
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        albumList2 = try container.decode(AlbumList2Container.self)
    }
}

struct SongsContainer: Decodable, Sendable {
    let song: [Song]?
}

struct RandomSongsPayload: SubsonicPayload {
    static let payloadKey = "randomSongs"
    let randomSongs: SongsContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        randomSongs = try container.decode(SongsContainer.self)
    }
}

struct SongsByGenrePayload: SubsonicPayload {
    static let payloadKey = "songsByGenre"
    let songsByGenre: SongsContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        songsByGenre = try container.decode(SongsContainer.self)
    }
}

struct Starred2Payload: SubsonicPayload {
    static let payloadKey = "starred2"
    let starred2: Starred2
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        starred2 = try container.decode(Starred2.self)
    }
}

struct AlbumListContainer: Decodable, Sendable {
    let album: [Song]?
}

struct AlbumListPayload: SubsonicPayload {
    static let payloadKey = "albumList"
    let albumList: AlbumListContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        albumList = try container.decode(AlbumListContainer.self)
    }
}

struct StarredPayload: SubsonicPayload {
    static let payloadKey = "starred"
    let starred: Starred
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        starred = try container.decode(Starred.self)
    }
}
