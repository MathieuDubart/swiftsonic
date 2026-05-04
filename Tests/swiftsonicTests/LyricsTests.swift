// LyricsTests.swift — SwiftSonicTests
//
// Tests for getLyrics (legacy) and getLyricsBySongId (OpenSubsonic songLyrics extension).

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getLyrics

@Suite("getLyrics")
struct GetLyricsTests {

    @Test("getLyrics decodes artist, title, and value")
    func decodesFields() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getLyrics")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let lyrics = try await client.getLyrics(artist: "Nine Inch Nails", title: "Hurt")

        let result = try #require(lyrics)
        #expect(result.artist == "Nine Inch Nails")
        #expect(result.title == "Hurt")
        #expect(result.value?.hasPrefix("I hurt myself today") == true)
    }

    @Test("getLyrics sends artist and title params")
    func sendsArtistAndTitleParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getLyrics")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getLyrics(artist: "Nine Inch Nails", title: "Hurt")

        #expect(mock.queryItem(named: "artist") == "Nine Inch Nails")
        #expect(mock.queryItem(named: "title") == "Hurt")
    }

    @Test("getLyrics sends correct endpoint")
    func sendsCorrectEndpoint() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getLyrics")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getLyrics(artist: "Nine Inch Nails", title: "Hurt")

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/getLyrics.view") == true)
    }

    @Test("getLyrics sends no params when both are nil")
    func sendsNoParamsWhenBothNil() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getLyrics_notfound")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getLyrics()

        #expect(mock.queryItem(named: "artist") == nil)
        #expect(mock.queryItem(named: "title") == nil)
    }

    @Test("getLyrics returns nil when server returns empty lyrics object")
    func returnsNilWhenNotFound() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getLyrics_notfound")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let lyrics = try await client.getLyrics(artist: "Unknown", title: "Unknown")

        #expect(lyrics == nil)
    }

    @Test("getLyrics returns nil when value is empty string")
    func returnsNilWhenValueIsEmpty() async throws {
        let emptyValueFixture = """
        {"subsonic-response":{"status":"ok","version":"1.16.1","lyrics":{"artist":"NIN","title":"Hurt","value":""}}}
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(emptyValueFixture)

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let lyrics = try await client.getLyrics(artist: "NIN", title: "Hurt")

        #expect(lyrics == nil)
    }
}

// MARK: - getLyricsBySongId

@Suite("getLyricsBySongId")
struct GetLyricsBySongIdTests {

    @Test("getLyricsBySongId decodes synced lyrics with start times")
    func decodesSyncedLyrics() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getLyricsBySongId_synced")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let list = try await client.getLyricsBySongId(id: "song-1")

        #expect(list.structuredLyrics.count == 1)

        let set = try #require(list.structuredLyrics.first)
        #expect(set.lang == "en")
        #expect(set.synced == true)
        #expect(set.displayArtist == "Nine Inch Nails")
        #expect(set.displayTitle == "Hurt")
        #expect(set.offset == 0)
        #expect(set.line.count == 4)

        let firstLine = try #require(set.line.first)
        #expect(firstLine.value == "I hurt myself today")
        #expect(firstLine.start == 0)

        let secondLine = set.line[1]
        #expect(secondLine.value == "To see if I still feel")
        #expect(secondLine.start == 3500)
    }

    @Test("getLyricsBySongId decodes unsynced lyrics without start times")
    func decodesUnsyncedLyrics() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getLyricsBySongId_unsynced")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let list = try await client.getLyricsBySongId(id: "song-2")

        let set = try #require(list.structuredLyrics.first)
        #expect(set.lang == "en")
        #expect(set.synced == false)
        #expect(set.line.count == 4)

        // Unsynced lines must not carry start timestamps
        for line in set.line {
            #expect(line.start == nil)
        }

        #expect(set.line[0].value == "I hurt myself today")
        #expect(set.line[3].value == "The only thing that's real")
    }

    @Test("getLyricsBySongId decodes multiple language sets")
    func decodesMultipleLangSets() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getLyricsBySongId_multilang")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let list = try await client.getLyricsBySongId(id: "song-3")

        #expect(list.structuredLyrics.count == 2)

        let langs = Set(list.structuredLyrics.map(\.lang))
        #expect(langs.contains("en"))
        #expect(langs.contains("fr"))
    }

    @Test("getLyricsBySongId returns empty structuredLyrics when absent from response")
    func returnsEmptyWhenAbsent() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getLyricsBySongId_empty")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let list = try await client.getLyricsBySongId(id: "song-4")

        #expect(list.structuredLyrics.isEmpty)
    }

    @Test("getLyricsBySongId sends correct endpoint")
    func sendsCorrectEndpoint() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getLyricsBySongId_unsynced")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getLyricsBySongId(id: "song-1")

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/getLyricsBySongId.view") == true)
    }

    @Test("getLyricsBySongId sends id param")
    func sendsIdParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getLyricsBySongId_unsynced")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getLyricsBySongId(id: "track-42")

        #expect(mock.queryItem(named: "id") == "track-42")
    }
}
