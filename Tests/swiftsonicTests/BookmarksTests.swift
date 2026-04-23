// BookmarksTests.swift — SwiftSonicTests
//
// Tests for bookmark endpoints: getBookmarks, createBookmark, deleteBookmark.
//
// Fixtures:
//   getBookmarks.json       — real Navidrome response, dates normalized to ms precision
//   getBookmarks_empty.json — empty bookmarks container
//     Spec: https://opensubsonic.netlify.app/docs/endpoints/getbookmarks/
//
// Note: dates in the fixture are truncated from Navidrome's nanosecond precision
// (e.g. "2025-08-21T19:20:52.319099239Z") to millisecond precision
// ("2025-08-21T19:20:52.319Z") for standard ISO8601DateFormatter compatibility.
// Integration tests exercise the real nanosecond format.

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getBookmarks

@Suite("getBookmarks")
struct GetBookmarksTests {

    @Test("getBookmarks decodes a bookmark with its entry song")
    func decodesBookmark() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getBookmarks")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let bookmarks = try await client.getBookmarks()

        #expect(bookmarks.count == 1)

        let bm = try #require(bookmarks.first)
        // position: 59962 ms → 59.962 s
        #expect(abs(bm.position - 59.962) < 0.001)
        #expect(bm.username == "demo")
        #expect(bm.comment == "Auto created by DSub")
        #expect(bm.created != Date(timeIntervalSince1970: 0))
        #expect(bm.changed != Date(timeIntervalSince1970: 0))

        // entry (the bookmarked song)
        #expect(bm.entry.id == "PjP3avpOkcOlJb6YvGxsl6")
        #expect(bm.entry.title == "Together")
        #expect(bm.entry.artist == "Nine Inch Nails")
        #expect(bm.entry.duration == 603)
    }

    @Test("getBookmarks returns empty array when there are no bookmarks")
    func returnsEmptyArray() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getBookmarks_empty")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let bookmarks = try await client.getBookmarks()

        #expect(bookmarks.isEmpty)
    }

    @Test("getBookmarks sends the correct request path")
    func sendsCorrectPath() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getBookmarks")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getBookmarks()

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/getBookmarks.view") == true)
    }
}

// MARK: - createBookmark

@Suite("createBookmark")
struct CreateBookmarkTests {

    @Test("createBookmark converts position from seconds to milliseconds")
    func convertsPositionToMs() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        // 120.5 seconds → 120500 milliseconds
        try await client.createBookmark(songId: "42", position: 120.5)

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/createBookmark.view") == true)
        #expect(mock.queryItem(named: "id") == "42")
        #expect(mock.queryItem(named: "position") == "120500")
        #expect(mock.queryItem(named: "comment") == nil)
    }

    @Test("createBookmark sends optional comment when provided")
    func sendsComment() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.createBookmark(songId: "7", position: 0, comment: "Chapter 5")

        #expect(mock.queryItem(named: "comment") == "Chapter 5")
    }
}

// MARK: - deleteBookmark

@Suite("deleteBookmark")
struct DeleteBookmarkTests {

    @Test("deleteBookmark sends the song id")
    func sendsId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.deleteBookmark(songId: "99")

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/deleteBookmark.view") == true)
        #expect(mock.queryItem(named: "id") == "99")
    }
}
