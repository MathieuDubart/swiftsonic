// BrowsingTests.swift — SwiftSonicTests
//
// Tests for browsing endpoints: getArtists, getMusicFolders.

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getArtists

@Suite("getArtists")
struct GetArtistsTests {

    @Test("getArtists decodes index buckets and artists")
    func decodesArtists() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getArtists")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let indexes = try await client.getArtists()

        #expect(indexes.count == 2)

        let aIndex = try #require(indexes.first(where: { $0.name == "A" }))
        #expect(aIndex.artist.count == 1)
        #expect(aIndex.artist[0].name == "ABBA")
        #expect(aIndex.artist[0].id == "1")
        #expect(aIndex.artist[0].albumCount == 5)
        #expect(aIndex.artist[0].starred != nil)

        let bIndex = try #require(indexes.first(where: { $0.name == "B" }))
        #expect(bIndex.artist.count == 2)
        #expect(bIndex.artist[0].name == "Beatles, The")
        #expect(bIndex.artist[1].name == "Bob Dylan")
    }

    @Test("getArtists sends correct request path and params")
    func sendsCorrectRequest() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getArtists")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getArtists()

        let request = try #require(mock.lastRequest)
        #expect(request.url?.path.hasSuffix("/rest/getArtists.view") == true)
        #expect(mock.queryItem(named: "musicFolderId") == nil)
    }

    @Test("getArtists sends musicFolderId when provided")
    func sendsMusicFolderId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getArtists")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getArtists(musicFolderId: "42")

        #expect(mock.queryItem(named: "musicFolderId") == "42")
    }

    @Test("getArtists returns empty array on empty index")
    func returnsEmptyOnEmptyIndex() async throws {
        let emptyFixture = """
        {
          "subsonic-response": {
            "status": "ok",
            "version": "1.16.1",
            "artists": {
              "ignoredArticles": "The",
              "index": []
            }
          }
        }
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(emptyFixture)

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let indexes = try await client.getArtists()
        #expect(indexes.isEmpty)
    }
}

// MARK: - RequestBuilder auth tests

@Suite("RequestBuilder")
struct RequestBuilderTests {

    @Test("token auth params are all present")
    func tokenAuthParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.ping()

        #expect(mock.queryItem(named: "u") == "testuser")
        #expect(mock.queryItem(named: "t") != nil)   // MD5 hash
        #expect(mock.queryItem(named: "s") != nil)   // salt
        #expect(mock.queryItem(named: "apiKey") == nil)
    }

    @Test("apiKey auth sends apiKey param, no u/t/s")
    func apiKeyAuth() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let config = ServerConfiguration(
            serverURL: URL(string: "https://test.example.com")!,
            auth: .apiKey("my-secret-key")
        )
        let client = SwiftSonicClient(configuration: config, transport: mock)
        try await client.ping()

        #expect(mock.queryItem(named: "apiKey") == "my-secret-key")
        #expect(mock.queryItem(named: "u") == nil)
        #expect(mock.queryItem(named: "t") == nil)
        #expect(mock.queryItem(named: "s") == nil)
    }

    @Test("reusesSalt uses same salt across requests")
    func reusesSaltIsConsistent() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")
        mock.enqueue(fixture: "ping_ok")

        let config = ServerConfiguration(
            serverURL: URL(string: "https://test.example.com")!,
            username: "user",
            password: "pass",
            reusesSalt: true
        )
        let client = SwiftSonicClient(configuration: config, transport: mock)
        try await client.ping()
        try await client.ping()

        let salt1 = mock.queryItem(named: "s", in: mock.capturedRequests[0])
        let salt2 = mock.queryItem(named: "s", in: mock.capturedRequests[1])
        #expect(salt1 == salt2)
    }
}
