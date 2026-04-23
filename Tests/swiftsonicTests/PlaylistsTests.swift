// PlaylistsTests.swift — SwiftSonicTests
//
// Tests for playlist endpoints: getPlaylists, getPlaylist, createPlaylist,
// updatePlaylist, deletePlaylist.

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getPlaylists

@Suite("getPlaylists")
struct GetPlaylistsTests {

    @Test("getPlaylists decodes playlist list")
    func decodesPlaylists() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getPlaylists")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let playlists = try await client.getPlaylists()

        #expect(playlists.count == 2)
        #expect(playlists[0].id == "1")
        #expect(playlists[0].name == "My Favourites")
        #expect(playlists[0].isPublic == true)
        #expect(playlists[0].songCount == 42)
        #expect(playlists[1].name == "Workout Mix")
        #expect(playlists[1].isPublic == false)
    }

    @Test("getPlaylists sends username when provided")
    func sendsUsername() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getPlaylists")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getPlaylists(username: "alice")

        #expect(mock.queryItem(named: "username") == "alice")
    }

    @Test("getPlaylists sends no username by default")
    func sendsNoUsernameByDefault() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getPlaylists")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getPlaylists()

        #expect(mock.queryItem(named: "username") == nil)
    }

    @Test("getPlaylists returns empty array on empty response")
    func returnsEmptyArray() async throws {
        let emptyFixture = """
        {"subsonic-response":{"status":"ok","version":"1.16.1","playlists":{}}}
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(emptyFixture)

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let playlists = try await client.getPlaylists()
        #expect(playlists.isEmpty)
    }
}

// MARK: - getPlaylist

@Suite("getPlaylist")
struct GetPlaylistTests {

    @Test("getPlaylist decodes playlist with songs")
    func decodesPlaylistWithSongs() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getPlaylist")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let playlist = try await client.getPlaylist(id: "1")

        #expect(playlist.id == "1")
        #expect(playlist.name == "My Favourites")
        #expect(playlist.isPublic == true)
        #expect(playlist.songCount == 2)
        #expect(playlist.entry?.count == 2)
        #expect(playlist.entry?[0].title == "Ring Ring")
        #expect(playlist.entry?[1].title == "Bohemian Rhapsody")

        #expect(mock.queryItem(named: "id") == "1")
    }
}

// MARK: - createPlaylist

@Suite("createPlaylist")
struct CreatePlaylistTests {

    @Test("createPlaylist sends name and returns new playlist")
    func sendsNameAndReturnsPlaylist() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "createPlaylist")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let playlist = try await client.createPlaylist(name: "New Playlist")

        #expect(playlist.id == "99")
        #expect(playlist.name == "New Playlist")
        #expect(mock.queryItem(named: "name") == "New Playlist")
    }

    @Test("createPlaylist sends songIds as repeated params")
    func sendsSongIds() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "createPlaylist")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.createPlaylist(name: "Mix", songIds: ["101", "201"])

        let req = try #require(mock.lastRequest)
        let items = req.url?.query?.components(separatedBy: "&")
            .filter { $0.hasPrefix("songId=") }
        #expect(items?.count == 2)
        #expect(items?.contains("songId=101") == true)
        #expect(items?.contains("songId=201") == true)
    }
}

// MARK: - updatePlaylist

@Suite("updatePlaylist")
struct UpdatePlaylistTests {

    @Test("updatePlaylist sends playlistId")
    func sendsPlaylistId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.updatePlaylist(id: "1")

        #expect(mock.queryItem(named: "playlistId") == "1")
    }

    @Test("updatePlaylist sends optional scalar params")
    func sendsScalarParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.updatePlaylist(id: "1", name: "Renamed", comment: "Nice", isPublic: true)

        #expect(mock.queryItem(named: "name")    == "Renamed")
        #expect(mock.queryItem(named: "comment") == "Nice")
        #expect(mock.queryItem(named: "public")  == "true")
    }

    @Test("updatePlaylist sends songIdToAdd as repeated params")
    func sendsSongIdsToAdd() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.updatePlaylist(id: "1", songIdsToAdd: ["101", "201", "301"])

        let req = try #require(mock.lastRequest)
        let items = req.url?.query?.components(separatedBy: "&")
            .filter { $0.hasPrefix("songIdToAdd=") }
        #expect(items?.count == 3)
    }

    @Test("updatePlaylist sends songIndexToRemove as repeated params")
    func sendsSongIndexesToRemove() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.updatePlaylist(id: "1", songIndexesToRemove: [0, 2])

        let req = try #require(mock.lastRequest)
        let items = req.url?.query?.components(separatedBy: "&")
            .filter { $0.hasPrefix("songIndexToRemove=") }
        #expect(items?.count == 2)
        #expect(items?.contains("songIndexToRemove=0") == true)
        #expect(items?.contains("songIndexToRemove=2") == true)
    }
}

// MARK: - deletePlaylist

@Suite("deletePlaylist")
struct DeletePlaylistTests {

    @Test("deletePlaylist sends id param")
    func sendsId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.deletePlaylist(id: "42")

        #expect(mock.queryItem(named: "id") == "42")

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/deletePlaylist.view") == true)
    }
}
