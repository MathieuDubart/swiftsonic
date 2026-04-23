// SearchTests.swift — SwiftSonicTests
//
// Tests for search2 (folder-based legacy) and search3 (ID3-based, preferred) endpoints.

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - search2 (folder-based)

@Suite("search2")
struct Search2Tests {

    @Test("search2 decodes folder-based artists, albums, and songs")
    func decodesAllThreeKinds() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "search2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let results = try await client.search2("bohemian")

        #expect(results.artist?.count == 1)
        #expect(results.artist?[0].title == "Queen")
        #expect(results.artist?[0].isDir == true)

        #expect(results.album?.count == 1)
        #expect(results.album?[0].title == "A Night at the Opera")

        #expect(results.song?.count == 1)
        #expect(results.song?[0].title == "Bohemian Rhapsody")
        #expect(results.song?[0].duration == 354)
    }

    @Test("search2 sends query param")
    func sendsQueryParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "search2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.search2("queen")

        #expect(mock.queryItem(named: "query") == "queen")
    }

    @Test("search2 sends all optional params")
    func sendsOptionalParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "search2")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.search2(
            "rock",
            artistCount: 5, artistOffset: 10,
            albumCount: 15, albumOffset: 20,
            songCount: 25, songOffset: 30,
            musicFolderId: "1"
        )

        #expect(mock.queryItem(named: "artistCount")   == "5")
        #expect(mock.queryItem(named: "artistOffset")  == "10")
        #expect(mock.queryItem(named: "albumCount")    == "15")
        #expect(mock.queryItem(named: "albumOffset")   == "20")
        #expect(mock.queryItem(named: "songCount")     == "25")
        #expect(mock.queryItem(named: "songOffset")    == "30")
        #expect(mock.queryItem(named: "musicFolderId") == "1")
    }

    @Test("search2 handles empty results gracefully")
    func handlesEmptyResults() async throws {
        let emptyFixture = """
        {"subsonic-response":{"status":"ok","version":"1.16.1","searchResult2":{}}}
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(emptyFixture)

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let results = try await client.search2("zzz")

        #expect(results.artist == nil)
        #expect(results.album == nil)
        #expect(results.song == nil)
    }
}

// MARK: - search3

@Suite("search3")
struct Search3Tests {

    @Test("search3 decodes artists, albums, and songs")
    func decodesAllThreeKinds() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "search3")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let results = try await client.search3("bohemian")

        #expect(results.artist?.count == 1)
        #expect(results.artist?[0].name == "Queen")

        #expect(results.album?.count == 1)
        #expect(results.album?[0].name == "A Night at the Opera")

        #expect(results.song?.count == 1)
        #expect(results.song?[0].title == "Bohemian Rhapsody")
        #expect(results.song?[0].duration == 354)
    }

    @Test("search3 sends query param")
    func sendsQueryParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "search3")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.search3("queen")

        #expect(mock.queryItem(named: "query") == "queen")
    }

    @Test("search3 sends all optional params")
    func sendsOptionalParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "search3")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.search3(
            "rock",
            artistCount: 5,
            artistOffset: 10,
            albumCount: 15,
            albumOffset: 20,
            songCount: 25,
            songOffset: 30,
            musicFolderId: "1"
        )

        #expect(mock.queryItem(named: "artistCount")   == "5")
        #expect(mock.queryItem(named: "artistOffset")  == "10")
        #expect(mock.queryItem(named: "albumCount")    == "15")
        #expect(mock.queryItem(named: "albumOffset")   == "20")
        #expect(mock.queryItem(named: "songCount")     == "25")
        #expect(mock.queryItem(named: "songOffset")    == "30")
        #expect(mock.queryItem(named: "musicFolderId") == "1")
    }

    @Test("search3 sends no optional params by default")
    func sendsNoOptionalParamsByDefault() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "search3")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.search3("pop")

        #expect(mock.queryItem(named: "artistCount")  == nil)
        #expect(mock.queryItem(named: "albumCount")   == nil)
        #expect(mock.queryItem(named: "songCount")    == nil)
        #expect(mock.queryItem(named: "musicFolderId") == nil)
    }

    @Test("search3 handles empty results gracefully")
    func handlesEmptyResults() async throws {
        let emptyFixture = """
        {"subsonic-response":{"status":"ok","version":"1.16.1","searchResult3":{}}}
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(emptyFixture)

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let results = try await client.search3("zzz")

        #expect(results.artist == nil)
        #expect(results.album == nil)
        #expect(results.song == nil)
    }
}
