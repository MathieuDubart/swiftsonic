// LyricsTests.swift — SwiftSonicTests
//
// Tests for the getLyrics endpoint.

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
