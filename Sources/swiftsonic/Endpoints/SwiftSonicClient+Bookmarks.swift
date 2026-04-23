// SwiftSonicClient+Bookmarks.swift — SwiftSonic
//
// Bookmark endpoints: get, create, delete.
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getbookmarks/
//
// Bookmarks are per-user playback positions, useful for audiobooks and long-form content.
// Position is expressed in seconds (TimeInterval) in the Swift API; converted to/from
// milliseconds when communicating with the server.

import Foundation

// MARK: - Bookmark endpoints

public extension SwiftSonicClient {

    /// Returns all bookmarks for the authenticated user.
    ///
    /// ```swift
    /// let bookmarks = try await client.getBookmarks()
    /// for bm in bookmarks {
    ///     print("\(bm.entry.title) — \(bm.position)s")
    /// }
    /// ```
    ///
    /// - Returns: An array of ``Bookmark`` objects, empty if none exist.
    func getBookmarks() async throws -> [Bookmark] {
        let envelope: SubsonicEnvelope<BookmarksPayload> =
            try await performDecode(endpoint: "getBookmarks", params: [:])
        return envelope.payload?.bookmarks.bookmark ?? []
    }

    /// Creates or overwrites a bookmark for the specified song.
    ///
    /// If a bookmark already exists for `songId`, it is replaced.
    ///
    /// ```swift
    /// try await client.createBookmark(songId: "42", position: 312.5)
    /// try await client.createBookmark(songId: "42", position: 312.5, comment: "Chapter 3")
    /// ```
    ///
    /// - Parameters:
    ///   - songId: The ID of the song to bookmark.
    ///   - position: The playback position to save, in seconds.
    ///   - comment: An optional note to attach to the bookmark.
    func createBookmark(
        songId: String,
        position: TimeInterval,
        comment: String? = nil
    ) async throws {
        var params: [String: String] = [
            "id": songId,
            // API expects milliseconds
            "position": String(Int64(position * 1000)),
        ]
        if let c = comment { params["comment"] = c }
        try await performVoid(endpoint: "createBookmark", params: params)
    }

    /// Deletes the bookmark for the specified song.
    ///
    /// ```swift
    /// try await client.deleteBookmark(songId: "42")
    /// ```
    ///
    /// - Parameter songId: The ID of the song whose bookmark should be deleted.
    func deleteBookmark(songId: String) async throws {
        try await performVoid(endpoint: "deleteBookmark", params: ["id": songId])
    }
}

// MARK: - Response payloads (internal)

struct BookmarksContainer: Decodable, Sendable {
    // Optional: absent when the server returns an empty object `{}`
    let bookmark: [Bookmark]?
}

struct BookmarksPayload: SubsonicPayload {
    static let payloadKey = "bookmarks"
    let bookmarks: BookmarksContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        bookmarks = try container.decode(BookmarksContainer.self)
    }
}
