// NowPlayingTests.swift — SwiftSonicTests
//
// Tests for the getNowPlaying endpoint.

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getNowPlaying

@Suite("getNowPlaying")
struct GetNowPlayingTests {

    @Test("getNowPlaying decodes entries with all fields")
    func decodesEntries() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getNowPlaying")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let entries = try await client.getNowPlaying()

        #expect(entries.count == 2)

        let first = entries[0]
        #expect(first.id == "rF7kG3QpkR3tBqT8GwGiKF")
        #expect(first.title == "Hurt")
        #expect(first.artist == "Nine Inch Nails")
        #expect(first.album == "The Downward Spiral")
        #expect(first.duration == 237)
        #expect(first.contentType == "audio/mpeg")
        #expect(first.username == "alice")
        #expect(first.minutesAgo == 2)
        #expect(first.playerId == 1)
        #expect(first.playerName == "iPhone")
    }

    @Test("getNowPlaying decodes second entry")
    func decodesSecondEntry() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getNowPlaying")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let entries = try await client.getNowPlaying()

        let second = entries[1]
        #expect(second.id == "pQ9aH2RmjS5vCwU7LxLjNG")
        #expect(second.title == "Closer")
        #expect(second.username == "bob")
        #expect(second.minutesAgo == 0)
        #expect(second.playerId == 2)
        #expect(second.playerName == "Web Player")
        #expect(second.contentType == "audio/flac")
    }

    @Test("getNowPlaying sends correct endpoint")
    func sendsCorrectEndpoint() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getNowPlaying")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getNowPlaying()

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/getNowPlaying.view") == true)
    }

    @Test("getNowPlaying returns empty array when nothing is playing")
    func returnsEmptyWhenNothingPlaying() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getNowPlaying_empty")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let entries = try await client.getNowPlaying()

        #expect(entries.isEmpty)
    }

    @Test("getNowPlaying entry coverArt is optional")
    func coverArtIsOptional() async throws {
        let noArtFixture = """
        {"subsonic-response":{"status":"ok","version":"1.16.1","nowPlaying":{"entry":[{"id":"s1","title":"Track","username":"user","minutesAgo":1,"playerId":1}]}}}
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(noArtFixture)

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let entries = try await client.getNowPlaying()

        #expect(entries.count == 1)
        #expect(entries[0].coverArt == nil)
        #expect(entries[0].playerName == nil)
    }
}
