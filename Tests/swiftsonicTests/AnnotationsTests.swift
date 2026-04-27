// AnnotationsTests.swift — SwiftSonicTests
//
// Tests for annotation endpoints: star, unstar, setRating, scrobble.

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - star

@Suite("star")
struct StarTests {

    @Test("star sends song ids as repeated id params")
    func sendsSongIds() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.star(songIds: ["101", "201"])

        let req = try #require(mock.lastRequest)
        let items = req.url?.query?.components(separatedBy: "&").filter { $0.hasPrefix("id=") }
        #expect(items?.count == 2)
        #expect(items?.contains("id=101") == true)
        #expect(items?.contains("id=201") == true)
        #expect(req.url?.path.hasSuffix("/rest/star.view") == true)
    }

    @Test("star sends albumId params")
    func sendsAlbumIds() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.star(albumIds: ["10"])

        let req = try #require(mock.lastRequest)
        let items = req.url?.query?.components(separatedBy: "&").filter { $0.hasPrefix("albumId=") }
        #expect(items?.count == 1)
        #expect(items?.contains("albumId=10") == true)
    }

    @Test("star sends artistId params")
    func sendsArtistIds() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.star(artistIds: ["1"])

        let req = try #require(mock.lastRequest)
        let items = req.url?.query?.components(separatedBy: "&").filter { $0.hasPrefix("artistId=") }
        #expect(items?.count == 1)
    }
}

// MARK: - unstar

@Suite("unstar")
struct UnstarTests {

    @Test("unstar sends ids and calls correct endpoint")
    func sendsIdsToCorrectEndpoint() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.unstar(songIds: ["101"])

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/unstar.view") == true)
        let items = req.url?.query?.components(separatedBy: "&").filter { $0.hasPrefix("id=") }
        #expect(items?.contains("id=101") == true)
    }

    @Test("unstar sends albumId params")
    func sendsAlbumIds() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.unstar(albumIds: ["10"])

        let items = mock.lastRequest?.url?.query?.components(separatedBy: "&").filter { $0.hasPrefix("albumId=") }
        #expect(items?.count == 1)
        #expect(items?.contains("albumId=10") == true)
    }

    @Test("unstar sends artistId params")
    func sendsArtistIds() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.unstar(artistIds: ["1"])

        let items = mock.lastRequest?.url?.query?.components(separatedBy: "&").filter { $0.hasPrefix("artistId=") }
        #expect(items?.count == 1)
    }
}

// MARK: - star convenience overloads

@Suite("star convenience")
struct StarConvenienceTests {

    @Test("star(songId:) sends single id param")
    func sendsSingleSongId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.star(songId: "101")

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/star.view") == true)
        let items = req.url?.query?.components(separatedBy: "&").filter { $0.hasPrefix("id=") }
        #expect(items?.count == 1)
        #expect(items?.contains("id=101") == true)
    }

    @Test("star(albumId:) sends single albumId param")
    func sendsSingleAlbumId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.star(albumId: "10")

        let items = mock.lastRequest?.url?.query?.components(separatedBy: "&").filter { $0.hasPrefix("albumId=") }
        #expect(items?.count == 1)
        #expect(items?.contains("albumId=10") == true)
    }

    @Test("star(artistId:) sends single artistId param")
    func sendsSingleArtistId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.star(artistId: "1")

        let items = mock.lastRequest?.url?.query?.components(separatedBy: "&").filter { $0.hasPrefix("artistId=") }
        #expect(items?.count == 1)
        #expect(items?.contains("artistId=1") == true)
    }
}

// MARK: - unstar convenience overloads

@Suite("unstar convenience")
struct UnstarConvenienceTests {

    @Test("unstar(songId:) sends single id param")
    func sendsSingleSongId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.unstar(songId: "101")

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/unstar.view") == true)
        let items = req.url?.query?.components(separatedBy: "&").filter { $0.hasPrefix("id=") }
        #expect(items?.count == 1)
        #expect(items?.contains("id=101") == true)
    }

    @Test("unstar(albumId:) sends single albumId param")
    func sendsSingleAlbumId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.unstar(albumId: "10")

        let items = mock.lastRequest?.url?.query?.components(separatedBy: "&").filter { $0.hasPrefix("albumId=") }
        #expect(items?.count == 1)
        #expect(items?.contains("albumId=10") == true)
    }

    @Test("unstar(artistId:) sends single artistId param")
    func sendsSingleArtistId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.unstar(artistId: "1")

        let items = mock.lastRequest?.url?.query?.components(separatedBy: "&").filter { $0.hasPrefix("artistId=") }
        #expect(items?.count == 1)
        #expect(items?.contains("artistId=1") == true)
    }
}

// MARK: - setRating

@Suite("setRating")
struct SetRatingTests {

    @Test("setRating sends id and rating params")
    func sendsIdAndRating() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.setRating(id: "101", rating: 4)

        #expect(mock.queryItem(named: "id")     == "101")
        #expect(mock.queryItem(named: "rating") == "4")

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/setRating.view") == true)
    }

    @Test("setRating sends 0 to remove rating")
    func sendsZeroToRemoveRating() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.setRating(id: "101", rating: 0)

        #expect(mock.queryItem(named: "rating") == "0")
    }
}

// MARK: - scrobble

@Suite("scrobble")
struct ScrobbleTests {

    @Test("scrobble sends id and submission params")
    func sendsIdAndSubmission() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.scrobble(id: "101")

        #expect(mock.queryItem(named: "id")         == "101")
        #expect(mock.queryItem(named: "submission") == "true")

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/scrobble.view") == true)
    }

    @Test("scrobble sends nowPlaying when submission is false")
    func sendsNowPlaying() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.scrobble(id: "101", submission: false)

        #expect(mock.queryItem(named: "submission") == "false")
    }

    @Test("scrobble sends time param when provided")
    func sendsTimeParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        try await client.scrobble(id: "101", time: fixedDate)

        #expect(mock.queryItem(named: "time") == "1700000000000")
    }
}
