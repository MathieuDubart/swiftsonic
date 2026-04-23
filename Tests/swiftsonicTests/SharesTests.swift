// SharesTests.swift — SwiftSonicTests
//
// Tests for share endpoints: getShares, createShare, updateShare, deleteShare.
//
// Fixtures:
//   getShares.json       — manual fixture (Navidrome demo disables shares): 2 shares,
//                          first with 1 entry song, second with no entries and no expiry/description
//   getShares_empty.json — empty shares container
//
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getshares/

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getShares

@Suite("getShares")
struct GetSharesTests {

    @Test("getShares decodes shares with their entries")
    func decodesShares() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getShares")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let shares = try await client.getShares()

        #expect(shares.count == 2)

        let first = try #require(shares.first)
        #expect(first.id == "sh-abc123")
        #expect(first.url == "https://music.example.com/share/sh-abc123")
        #expect(first.description == "NIN collection")
        #expect(first.username == "alice")
        #expect(first.visitCount == 3)
        #expect(first.expires != nil)

        // entry song
        #expect(first.entry.count == 1)
        #expect(first.entry[0].id == "rF7kG3QpkR3tBqT8GwGiKF")
        #expect(first.entry[0].title == "999,999")
        #expect(first.entry[0].duration == 85)

        // second share has no description, no expiry, empty entries
        let second = shares[1]
        #expect(second.id == "sh-def456")
        #expect(second.description == nil)
        #expect(second.expires == nil)
        #expect(second.entry.isEmpty)
    }

    @Test("getShares returns empty array when there are no shares")
    func returnsEmptyArray() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getShares_empty")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let shares = try await client.getShares()

        #expect(shares.isEmpty)
    }

    @Test("getShares sends the correct request path")
    func sendsCorrectPath() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getShares")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getShares()

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/getShares.view") == true)
    }
}

// MARK: - createShare

@Suite("createShare")
struct CreateShareTests {

    @Test("createShare sends repeated id params")
    func sendsRepeatedIds() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getShares")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.createShare(ids: ["song1", "song2"])

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/createShare.view") == true)

        guard let url = req.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { Issue.record("Could not parse URL"); return }

        let ids = components.queryItems?
            .filter { $0.name == "id" }
            .compactMap(\.value) ?? []
        #expect(ids == ["song1", "song2"])
    }

    @Test("createShare converts expires from Date to milliseconds")
    func convertsExpiresToMs() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getShares")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        // Unix epoch + 1000 seconds → 1_000_000 ms
        let expiryDate = Date(timeIntervalSince1970: 1_000)
        _ = try await client.createShare(ids: ["x"], expires: expiryDate)

        #expect(mock.queryItem(named: "expires") == "1000000")
    }

    @Test("createShare sends optional description when provided")
    func sendsDescription() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getShares")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.createShare(ids: ["x"], description: "My share")

        #expect(mock.queryItem(named: "description") == "My share")
    }
}

// MARK: - updateShare

@Suite("updateShare")
struct UpdateShareTests {

    @Test("updateShare sends id and optional fields")
    func sendsParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let expiry = Date(timeIntervalSince1970: 2_000)
        try await client.updateShare(id: "sh-abc123", description: "Updated", expires: expiry)

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/updateShare.view") == true)
        #expect(mock.queryItem(named: "id") == "sh-abc123")
        #expect(mock.queryItem(named: "description") == "Updated")
        #expect(mock.queryItem(named: "expires") == "2000000")
    }
}

// MARK: - deleteShare

@Suite("deleteShare")
struct DeleteShareTests {

    @Test("deleteShare sends the share id")
    func sendsId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.deleteShare(id: "sh-abc123")

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/deleteShare.view") == true)
        #expect(mock.queryItem(named: "id") == "sh-abc123")
    }
}
