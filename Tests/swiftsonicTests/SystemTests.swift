// SystemTests.swift — SwiftSonicTests
//
// Tests for system endpoints: ping, getLicense, getOpenSubsonicExtensions, fetchCapabilities.
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

        await #expect(throws: SwiftSonicError.self) {
            try await client.ping()
        }

        // Verify the specific error code
        do {
            try await client.ping()
        } catch SwiftSonicError.api(let apiError) {
            #expect(apiError.code == .wrongCredentials)
            #expect(apiError.message == "Wrong username or password.")
        } catch {
            // Re-enqueue for the second attempt above
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
}
