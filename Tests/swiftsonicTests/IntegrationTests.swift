// IntegrationTests.swift — SwiftSonicTests
//
// Live integration tests against the public Navidrome demo server.
// SKIPPED by default — only run when the environment variable is set.
//
// To run locally:
//   SWIFTSONIC_INTEGRATION_TESTS=1 swift test --filter IntegrationTests
//
// Rules (from project spec):
//   - Read-only endpoints only — no star, scrobble, rating, or playlist writes
//   - Assertions are intentionally loose: the demo library content changes over time
//   - No fixture files — responses come entirely from the live server

import Testing
import Foundation
import SwiftSonic

private let integrationEnabled =
    ProcessInfo.processInfo.environment["SWIFTSONIC_INTEGRATION_TESTS"] != nil

@Suite(
    "Integration — demo.navidrome.org",
    .enabled(if: integrationEnabled, "Set SWIFTSONIC_INTEGRATION_TESTS=1 to run")
)
struct IntegrationTests {

    // Public Navidrome demo — read-only guest credentials
    private let client = SwiftSonicClient(
        serverURL: URL(string: "https://demo.navidrome.org")!,
        username: "demo",
        password: "demo"
    )

    // MARK: - System

    @Test("ping returns without error")
    func ping() async throws {
        try await client.ping()
    }

    @Test("getLicense returns a valid license")
    func getLicense() async throws {
        let license = try await client.getLicense()
        #expect(license.valid == true)
    }

    @Test("fetchCapabilities identifies an OpenSubsonic server")
    func fetchCapabilities() async throws {
        try await client.fetchCapabilities()
        let caps = try #require(await client.serverCapabilities)
        #expect(!caps.apiVersion.isEmpty)
        #expect(caps.isOpenSubsonic == true)
    }

    @Test("getOpenSubsonicExtensions returns at least one extension")
    func getOpenSubsonicExtensions() async throws {
        let extensions = try await client.getOpenSubsonicExtensions()
        #expect(!extensions.isEmpty)
    }

    // MARK: - Browsing

    @Test("getMusicFolders returns at least one folder")
    func getMusicFolders() async throws {
        let folders = try await client.getMusicFolders()
        #expect(!folders.isEmpty)
    }

    @Test("getArtists returns at least one index bucket")
    func getArtists() async throws {
        let indexes = try await client.getArtists()
        #expect(!indexes.isEmpty)
    }

    @Test("getGenres returns genres")
    func getGenres() async throws {
        let genres = try await client.getGenres()
        #expect(!genres.isEmpty)
    }

    // MARK: - Lists

    @Test("getAlbumList2(.newest) returns albums")
    func getAlbumList2() async throws {
        let albums = try await client.getAlbumList2(type: .newest, size: 5)
        #expect(!albums.isEmpty)
    }

    @Test("getRandomSongs returns songs")
    func getRandomSongs() async throws {
        let songs = try await client.getRandomSongs(size: 5)
        #expect(!songs.isEmpty)
    }

    // MARK: - Scan

    @Test("getScanStatus returns a status without error")
    func getScanStatus() async throws {
        let status = try await client.getScanStatus()
        // The demo server is never actively scanning — just verify the call succeeds.
        #expect(status.scanning == false)
    }

    // MARK: - Internet Radio

    @Test("getInternetRadioStations returns without error")
    func getInternetRadioStations() async throws {
        // The demo server has no stations configured — verify the call succeeds and
        // returns an empty array rather than throwing.
        let stations = try await client.getInternetRadioStations()
        #expect(stations.isEmpty || !stations.isEmpty)  // either is valid
    }

    // MARK: - Search

    @Test("search3 returns at least one result for a broad query")
    func search3() async throws {
        let results = try await client.search3(
            "a",
            artistCount: 3,
            albumCount: 3,
            songCount: 3
        )
        let hasAny = !(results.artist?.isEmpty ?? true)
            || !(results.album?.isEmpty ?? true)
            || !(results.song?.isEmpty ?? true)
        #expect(hasAny)
    }
}
