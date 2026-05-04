// SystemTests.swift — SwiftSonicTests
//
// Tests for system endpoints: ping, getLicense, getOpenSubsonicExtensions, fetchCapabilities,
// loadCapabilities, refreshCapabilities, ServerCapabilities (KnownExtension, legacy, extensionList).
//
// Each test verifies two things:
//   1. The outgoing URLRequest is correctly constructed (path, auth params, format)
//   2. The response is correctly decoded into the expected Swift type

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - ping

@Suite("ping")
struct PingTests {

    @Test("ping succeeds on status ok")
    func pingSucceeds() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.ping()

        let request = try #require(mock.lastRequest)
        #expect(request.url?.path.hasSuffix("/rest/ping.view") == true)
        #expect(mock.queryItem(named: "f") == "json")
        #expect(mock.queryItem(named: "v") == "1.16.1")
        #expect(mock.queryItem(named: "c") == "SwiftSonic")
        #expect(mock.queryItem(named: "u") == "testuser")
        // t and s are present (values are random per-request)
        #expect(mock.queryItem(named: "t") != nil)
        #expect(mock.queryItem(named: "s") != nil)
    }

    @Test("ping throws .api(.wrongCredentials) on error 40")
    func pingThrowsOnWrongCredentials() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_error_40")

        let client = SwiftSonicClient(configuration: .test, transport: mock)

        do {
            try await client.ping()
            Issue.record("Expected SwiftSonicError.api to be thrown")
        } catch SwiftSonicError.api(let apiError) {
            #expect(apiError.code == .wrongCredentials)
            #expect(apiError.message == "Wrong username or password.")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("ping throws .httpError on non-2xx response")
    func pingThrowsOnHTTPError() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(Data(), statusCode: 503)

        let client = SwiftSonicClient(configuration: .test, transport: mock)

        await #expect(throws: SwiftSonicError.self) {
            try await client.ping()
        }
    }
}

// MARK: - getLicense

@Suite("getLicense")
struct GetLicenseTests {

    @Test("getLicense decodes valid license")
    func getLicenseDecodes() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getLicense")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let license = try await client.getLicense()

        #expect(license.valid == true)
        #expect(license.email == "demo@navidrome.org")
        #expect(license.licenseExpires != nil)

        let request = try #require(mock.lastRequest)
        #expect(request.url?.path.hasSuffix("/rest/getLicense.view") == true)
    }
}

// MARK: - getOpenSubsonicExtensions

@Suite("getOpenSubsonicExtensions")
struct GetOpenSubsonicExtensionsTests {

    @Test("getOpenSubsonicExtensions decodes extension list")
    func decodesExtensions() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getOpenSubsonicExtensions")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let extensions = try await client.getOpenSubsonicExtensions()

        #expect(extensions.count == 5)

        let songLyrics = try #require(extensions.first(where: { $0.name == "songLyrics" }))
        #expect(songLyrics.versions == [1])

        let apiKey = try #require(extensions.first(where: { $0.name == "apiKeyAuthentication" }))
        #expect(apiKey.versions == [1])
    }
}

// MARK: - fetchCapabilities

@Suite("fetchCapabilities")
struct FetchCapabilitiesTests {

    @Test("fetchCapabilities populates serverCapabilities")
    func populatesCapabilities() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")                       // for ping
        mock.enqueue(fixture: "getOpenSubsonicExtensions")     // for getOpenSubsonicExtensions

        let client = SwiftSonicClient(configuration: .test, transport: mock)

        // Before fetch, capabilities are nil
        let before = await client.serverCapabilities
        #expect(before == nil)

        try await client.fetchCapabilities()

        let caps = try #require(await client.serverCapabilities)
        #expect(caps.apiVersion == "1.16.1")
        #expect(caps.isOpenSubsonic == true)
        #expect(caps.serverType == "navidrome")
        #expect(caps.supports("songLyrics") == true)
        #expect(caps.supports("apiKeyAuthentication") == true)
        #expect(caps.supports("nonExistentExtension") == false)
    }

    @Test("fetchCapabilities skips getOpenSubsonicExtensions on non-OS server")
    func skipsExtensionsOnNonOSServer() async throws {
        let nonOSPing = """
        {
          "subsonic-response": {
            "status": "ok",
            "version": "1.15.0"
          }
        }
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(nonOSPing)

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.fetchCapabilities()

        let caps = try #require(await client.serverCapabilities)
        #expect(caps.isOpenSubsonic == false)
        #expect(caps.extensions.isEmpty)
        // Only 1 request made (no getOpenSubsonicExtensions call)
        #expect(mock.capturedRequests.count == 1)
    }

    @Test("fetchCapabilities proceeds with empty extensions when getOpenSubsonicExtensions fails")
    func proceedsWithEmptyExtensionsOnGetExtensionsFailure() async throws {
        // Server claims OpenSubsonic but getOpenSubsonicExtensions returns an API error
        let osPing = """
        {"subsonic-response":{"status":"ok","version":"1.16.1","openSubsonic":true}}
        """.data(using: .utf8)!
        let apiError = """
        {"subsonic-response":{"status":"failed","version":"1.16.1","error":{"code":0,"message":"Method not found"}}}
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(osPing)     // ping succeeds
        mock.enqueue(apiError)   // getOpenSubsonicExtensions returns an error

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        // Must not throw
        try await client.fetchCapabilities()

        let caps = try #require(await client.serverCapabilities)
        #expect(caps.isOpenSubsonic == true)   // preserved from ping
        #expect(caps.extensions.isEmpty)        // empty because the call failed
    }
}

// MARK: - loadCapabilities

@Suite("loadCapabilities")
struct LoadCapabilitiesTests {

    @Test("loadCapabilities fetches on first call and caches on second")
    func fetchesAndCaches() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")
        mock.enqueue(fixture: "getOpenSubsonicExtensions")

        let client = SwiftSonicClient(configuration: .test, transport: mock)

        let caps1 = try await client.loadCapabilities()
        #expect(caps1.isOpenSubsonic == true)
        #expect(mock.capturedRequests.count == 2)  // ping + getOpenSubsonicExtensions

        // Second call must use cache — no new network requests
        let caps2 = try await client.loadCapabilities()
        #expect(caps2.isOpenSubsonic == true)
        #expect(mock.capturedRequests.count == 2)
    }

    @Test("loadCapabilities returns the cached serverCapabilities property value")
    func returnsSameValueAsProperty() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")
        mock.enqueue(fixture: "getOpenSubsonicExtensions")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let returned = try await client.loadCapabilities()
        let stored   = try #require(await client.serverCapabilities)

        #expect(returned.apiVersion == stored.apiVersion)
        #expect(returned.isOpenSubsonic == stored.isOpenSubsonic)
        #expect(returned.serverType == stored.serverType)
    }
}

// MARK: - refreshCapabilities

@Suite("refreshCapabilities")
struct RefreshCapabilitiesTests {

    @Test("refreshCapabilities forces a new fetch after initial load")
    func forcesNewFetch() async throws {
        let mock = MockHTTPTransport()
        // First load: 2 requests
        mock.enqueue(fixture: "ping_ok")
        mock.enqueue(fixture: "getOpenSubsonicExtensions")
        // Refresh: 2 more requests
        mock.enqueue(fixture: "ping_ok")
        mock.enqueue(fixture: "getOpenSubsonicExtensions")

        let client = SwiftSonicClient(configuration: .test, transport: mock)

        _ = try await client.loadCapabilities()
        #expect(mock.capturedRequests.count == 2)

        _ = try await client.refreshCapabilities()
        #expect(mock.capturedRequests.count == 4)
    }

    @Test("refreshCapabilities updates serverCapabilities")
    func updatesStoredCapabilities() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")
        mock.enqueue(fixture: "getOpenSubsonicExtensions")
        mock.enqueue(fixture: "ping_ok")
        mock.enqueue(fixture: "getOpenSubsonicExtensions")

        let client = SwiftSonicClient(configuration: .test, transport: mock)

        _ = try await client.loadCapabilities()
        let refreshed = try await client.refreshCapabilities()

        let stored = try #require(await client.serverCapabilities)
        #expect(refreshed.apiVersion == stored.apiVersion)
    }
}

// MARK: - ServerCapabilities

@Suite("ServerCapabilities")
struct ServerCapabilitiesTests {

    @Test("supports(KnownExtension) returns true for known supported extension")
    func supportsKnownExtensionTrue() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")
        mock.enqueue(fixture: "getOpenSubsonicExtensions")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let caps = try await client.loadCapabilities()

        #expect(caps.supports(.songLyrics) == true)
        #expect(caps.supports(.apiKeyAuthentication) == true)
    }

    @Test("supports(KnownExtension) returns false for unsupported extension")
    func supportsKnownExtensionFalse() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")
        mock.enqueue(fixture: "getOpenSubsonicExtensions")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let caps = try await client.loadCapabilities()

        #expect(caps.supports(.transcoding) == false)
        #expect(caps.supports(.sonicSimilarity) == false)
    }

    @Test("extensionList derives typed array from extensions dict")
    func extensionListDerivesFromDict() {
        let caps = ServerCapabilities(
            apiVersion: "1.16.1",
            isOpenSubsonic: true,
            serverType: nil,
            serverVersion: nil,
            extensions: ["songLyrics": [1], "playbackReport": [1]]
        )
        #expect(caps.extensionList.count == 2)
        let songLyricsEntry = caps.extensionList.first { $0.name == "songLyrics" }
        #expect(songLyricsEntry?.versions == [1])
    }

    @Test("legacy() returns non-OS capabilities with empty extensions")
    func legacyFactory() {
        let legacy = ServerCapabilities.legacy()
        #expect(legacy.isOpenSubsonic == false)
        #expect(legacy.extensions.isEmpty)
        #expect(legacy.extensionList.isEmpty)
        #expect(legacy.serverType == nil)
        #expect(legacy.serverVersion == nil)
        #expect(legacy.supports("songLyrics") == false)
        #expect(legacy.supports(.songLyrics) == false)
    }

    @Test("KnownExtension raw values match OpenSubsonic spec names")
    func knownExtensionRawValues() {
        #expect(KnownExtension.songLyrics.rawValue == "songLyrics")
        #expect(KnownExtension.apiKeyAuthentication.rawValue == "apiKeyAuthentication")
        #expect(KnownExtension.playbackReport.rawValue == "playbackReport")
        #expect(KnownExtension.transcodeOffset.rawValue == "transcodeOffset")
    }

    @Test("public init sets all fields correctly")
    func publicInit() {
        let caps = ServerCapabilities(
            apiVersion: "1.16.1",
            isOpenSubsonic: true,
            serverType: "gonic",
            serverVersion: "0.15.0",
            extensions: ["songLyrics": [1], "transcodeOffset": [1]]
        )
        #expect(caps.apiVersion == "1.16.1")
        #expect(caps.isOpenSubsonic == true)
        #expect(caps.serverType == "gonic")
        #expect(caps.serverVersion == "0.15.0")
        #expect(caps.supports(.songLyrics) == true)
        #expect(caps.supports(.transcodeOffset) == true)
        #expect(caps.supports(.sonicSimilarity) == false)
    }
}
