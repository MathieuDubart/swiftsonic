// ListsTests.swift — SwiftSonicTests
//
// Tests for list endpoints: getAlbumList2, getRandomSongs, getSongsByGenre, getStarred2.

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getAlbumList2

@Suite("getAlbumList2")
struct GetAlbumList2Tests {

    @Test("getAlbumList2 decodes album list")
    func decodesAlbumList() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getAlbumList2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let albums = try await client.getAlbumList2(type: .newest)

        #expect(albums.count == 2)
        #expect(albums[0].id == "10")
        #expect(albums[0].name == "Ring Ring")
        #expect(albums[1].name == "Waterloo")
    }

    @Test("getAlbumList2 sends type param")
    func sendsTypeParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getAlbumList2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getAlbumList2(type: .random, size: 20, offset: 10)

        #expect(mock.queryItem(named: "type") == "random")
        #expect(mock.queryItem(named: "size") == "20")
        #expect(mock.queryItem(named: "offset") == "10")
    }

    @Test("getAlbumList2 sends byYear params")
    func sendsByYearParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getAlbumList2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getAlbumList2(type: .byYear, fromYear: 1970, toYear: 1979)

        #expect(mock.queryItem(named: "type") == "byYear")
        #expect(mock.queryItem(named: "fromYear") == "1970")
        #expect(mock.queryItem(named: "toYear") == "1979")
    }

    @Test("getAlbumList2 sends genre param for byGenre type")
    func sendsByGenreParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getAlbumList2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getAlbumList2(type: .byGenre, genre: "Rock")

        #expect(mock.queryItem(named: "type") == "byGenre")
        #expect(mock.queryItem(named: "genre") == "Rock")
    }

    @Test("getAlbumList2 returns empty array on empty response")
    func returnsEmptyArray() async throws {
        let emptyFixture = """
        {"subsonic-response":{"status":"ok","version":"1.16.1","albumList2":{}}}
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(emptyFixture)

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let albums = try await client.getAlbumList2(type: .random)
        #expect(albums.isEmpty)
    }
}

// MARK: - getRandomSongs

@Suite("getRandomSongs")
struct GetRandomSongsTests {

    @Test("getRandomSongs decodes song list")
    func decodesSongs() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getRandomSongs")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let songs = try await client.getRandomSongs()

        #expect(songs.count == 2)
        #expect(songs[0].title == "Ring Ring")
        #expect(songs[1].title == "Bohemian Rhapsody")
        #expect(songs[1].duration == 354)
    }

    @Test("getRandomSongs sends optional params")
    func sendsOptionalParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getRandomSongs")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getRandomSongs(size: 25, genre: "Jazz", fromYear: 1960, toYear: 1969)

        #expect(mock.queryItem(named: "size") == "25")
        #expect(mock.queryItem(named: "genre") == "Jazz")
        #expect(mock.queryItem(named: "fromYear") == "1960")
        #expect(mock.queryItem(named: "toYear") == "1969")
    }

    @Test("getRandomSongs sends no params when called with defaults")
    func sendsNoParamsByDefault() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getRandomSongs")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getRandomSongs()

        #expect(mock.queryItem(named: "size") == nil)
        #expect(mock.queryItem(named: "genre") == nil)
    }
}

// MARK: - getSongsByGenre

@Suite("getSongsByGenre")
struct GetSongsByGenreTests {

    @Test("getSongsByGenre decodes song list")
    func decodesSongs() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getSongsByGenre")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let songs = try await client.getSongsByGenre("Rock")

        #expect(songs.count == 1)
        #expect(songs[0].title == "Bohemian Rhapsody")
        #expect(songs[0].genre == "Rock")

        #expect(mock.queryItem(named: "genre") == "Rock")
    }

    @Test("getSongsByGenre sends count and offset")
    func sendsCountAndOffset() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getSongsByGenre")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getSongsByGenre("Rock", count: 50, offset: 100)

        #expect(mock.queryItem(named: "count") == "50")
        #expect(mock.queryItem(named: "offset") == "100")
    }
}

// MARK: - getStarred2

@Suite("getStarred2")
struct GetStarred2Tests {

    @Test("getStarred2 decodes starred artists, albums, and songs")
    func decodesStarred() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getStarred2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let starred = try await client.getStarred2()

        #expect(starred.artist?.count == 1)
        #expect(starred.artist?[0].name == "ABBA")
        #expect(starred.artist?[0].starred != nil)

        #expect(starred.album?.count == 1)
        #expect(starred.album?[0].name == "Ring Ring")

        #expect(starred.song?.count == 1)
        #expect(starred.song?[0].title == "Ring Ring")
        #expect(starred.song?[0].starred != nil)
    }

    @Test("getStarred2 sends musicFolderId when provided")
    func sendsMusicFolderId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getStarred2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getStarred2(musicFolderId: "1")

        #expect(mock.queryItem(named: "musicFolderId") == "1")
    }
}
