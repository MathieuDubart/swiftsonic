// DiscoveryTests.swift — SwiftSonicTests
//
// Tests for discovery endpoints: getArtistInfo, getAlbumInfo, getSimilarSongs,
// getSimilarSongs2, getTopSongs.

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getArtistInfo

@Suite("getArtistInfo")
struct GetArtistInfoTests {

    @Test("getArtistInfo decodes biography and similar artists")
    func decodesArtistInfo() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getArtistInfo")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let info = try await client.getArtistInfo(id: "3GSnSEURz17ltddsamzmSD")

        #expect(info.biography?.contains("Nine Inch Nails") == true)
        #expect(info.musicBrainzId == "b7ffd2af-418f-4be2-bdd1-22f8b48613da")
        #expect(info.lastFmUrl?.contains("last.fm") == true)
        #expect(info.similarArtist?.count == 1)
        #expect(info.similarArtist?[0].name == "Marilyn Manson")
    }

    @Test("getArtistInfo sends correct endpoint and id param")
    func sendsCorrectParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getArtistInfo")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getArtistInfo(id: "ar-42")

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/getArtistInfo.view") == true)
        #expect(mock.queryItem(named: "id") == "ar-42")
    }

    @Test("getArtistInfo sends optional count and includeNotPresent params")
    func sendsOptionalParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getArtistInfo")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getArtistInfo(id: "ar-1", count: 5, includeNotPresent: true)

        #expect(mock.queryItem(named: "count") == "5")
        #expect(mock.queryItem(named: "includeNotPresent") == "true")
    }

    @Test("getArtistInfo sends no optional params by default")
    func sendsNoOptionalParamsByDefault() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getArtistInfo")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getArtistInfo(id: "ar-1")

        #expect(mock.queryItem(named: "count") == nil)
        #expect(mock.queryItem(named: "includeNotPresent") == nil)
    }
}

// MARK: - getAlbumInfo

@Suite("getAlbumInfo")
struct GetAlbumInfoTests {

    @Test("getAlbumInfo decodes notes and external links")
    func decodesAlbumInfo() async throws {
        // Reuse the existing getAlbumInfo2 fixture — same JSON structure, same key "albumInfo"
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getAlbumInfo2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let info = try await client.getAlbumInfo(id: "al-5")

        #expect(info.notes != nil || info.musicBrainzId != nil || info.lastFmUrl != nil)
    }

    @Test("getAlbumInfo sends correct endpoint and id param")
    func sendsCorrectParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getAlbumInfo2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getAlbumInfo(id: "al-99")

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/getAlbumInfo.view") == true)
        #expect(mock.queryItem(named: "id") == "al-99")
    }
}

// MARK: - getSimilarSongs

@Suite("getSimilarSongs")
struct GetSimilarSongsTests {

    @Test("getSimilarSongs decodes song list")
    func decodesSongs() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getSimilarSongs")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let songs = try await client.getSimilarSongs(id: "3GSnSEURz17ltddsamzmSD")

        #expect(songs.count == 1)
        #expect(songs[0].id == "rF7kG3QpkR3tBqT8GwGiKF")
        #expect(songs[0].title == "999,999")
        #expect(songs[0].artist == "Nine Inch Nails")
    }

    @Test("getSimilarSongs sends correct endpoint and id param")
    func sendsCorrectParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getSimilarSongs")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getSimilarSongs(id: "ar-1", count: 10)

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/getSimilarSongs.view") == true)
        #expect(mock.queryItem(named: "id") == "ar-1")
        #expect(mock.queryItem(named: "count") == "10")
    }

    @Test("getSimilarSongs returns empty array on empty response")
    func returnsEmptyOnEmpty() async throws {
        let emptyFixture = """
        {"subsonic-response":{"status":"ok","version":"1.16.1","similarSongs":{}}}
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(emptyFixture)

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let songs = try await client.getSimilarSongs(id: "ar-1")
        #expect(songs.isEmpty)
    }
}

// MARK: - getSimilarSongs2

@Suite("getSimilarSongs2")
struct GetSimilarSongs2Tests {

    @Test("getSimilarSongs2 decodes song list")
    func decodesSongs() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getSimilarSongs2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let songs = try await client.getSimilarSongs2(id: "3GSnSEURz17ltddsamzmSD")

        #expect(songs.count == 2)
        #expect(songs[0].title == "999,999")
        #expect(songs[1].title == "Closer")
    }

    @Test("getSimilarSongs2 sends correct endpoint and id param")
    func sendsCorrectParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getSimilarSongs2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getSimilarSongs2(id: "ar-2", count: 20)

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/getSimilarSongs2.view") == true)
        #expect(mock.queryItem(named: "id") == "ar-2")
        #expect(mock.queryItem(named: "count") == "20")
    }

    @Test("getSimilarSongs2 returns empty array on empty response")
    func returnsEmptyOnEmpty() async throws {
        let emptyFixture = """
        {"subsonic-response":{"status":"ok","version":"1.16.1","similarSongs2":{}}}
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(emptyFixture)

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let songs = try await client.getSimilarSongs2(id: "ar-1")
        #expect(songs.isEmpty)
    }
}

// MARK: - getTopSongs

@Suite("getTopSongs")
struct GetTopSongsTests {

    @Test("getTopSongs decodes song list")
    func decodesSongs() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getTopSongs")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let songs = try await client.getTopSongs(artist: "Nine Inch Nails")

        #expect(songs.count == 2)
        #expect(songs[0].title == "Hurt")
        #expect(songs[1].title == "Closer")
        #expect(songs[0].duration == 237)
    }

    @Test("getTopSongs sends artist param and optional count")
    func sendsParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getTopSongs")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getTopSongs(artist: "ABBA", count: 5)

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/getTopSongs.view") == true)
        #expect(mock.queryItem(named: "artist") == "ABBA")
        #expect(mock.queryItem(named: "count") == "5")
    }

    @Test("getTopSongs sends no count param by default")
    func sendsNoCountByDefault() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getTopSongs")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getTopSongs(artist: "ABBA")

        #expect(mock.queryItem(named: "count") == nil)
    }

    @Test("getTopSongs returns empty array on empty response")
    func returnsEmptyOnEmpty() async throws {
        let emptyFixture = """
        {"subsonic-response":{"status":"ok","version":"1.16.1","topSongs":{}}}
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(emptyFixture)

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let songs = try await client.getTopSongs(artist: "Unknown")
        #expect(songs.isEmpty)
    }
}
