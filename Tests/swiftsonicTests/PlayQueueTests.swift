// PlayQueueTests.swift — SwiftSonicTests
//
// Tests for play queue endpoints: getPlayQueue, savePlayQueue.
//
// Fixtures:
//   getPlayQueue.json       — real Navidrome response (2 NIN songs), dates normalized to ms precision
//   getPlayQueue_empty.json — response with no playQueue key (server never saved a queue)
//
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getplayqueue/

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getPlayQueue

@Suite("getPlayQueue")
struct GetPlayQueueTests {

    @Test("getPlayQueue decodes the saved queue")
    func decodesQueue() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getPlayQueue")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let queue = try await client.getPlayQueue()

        let q = try #require(queue)

        // Two songs in the queue
        #expect(q.entry.count == 2)
        #expect(q.entry[0].id == "rF7kG3QpkR3tBqT8GwGiKF")
        #expect(q.entry[0].title == "999,999")
        #expect(q.entry[1].id == "TVqMwb9ALbg8fT3FKCAEDE")
        #expect(q.entry[1].title == "1,000,000")

        // current + position: 16696 ms → 16.696 s
        #expect(q.current == "rF7kG3QpkR3tBqT8GwGiKF")
        let pos = try #require(q.position)
        #expect(abs(pos - 16.696) < 0.001)

        // metadata
        #expect(q.username == "demo")
        #expect(q.changedBy == "Narjo")
        #expect(q.changed != Date(timeIntervalSince1970: 0))
    }

    @Test("getPlayQueue returns nil when no queue is saved")
    func returnsNilWhenAbsent() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getPlayQueue_empty")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let queue = try await client.getPlayQueue()

        #expect(queue == nil)
    }

    @Test("getPlayQueue sends the correct request path")
    func sendsCorrectPath() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getPlayQueue")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getPlayQueue()

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/getPlayQueue.view") == true)
    }
}

// MARK: - savePlayQueue

@Suite("savePlayQueue")
struct SavePlayQueueTests {

    @Test("savePlayQueue sends repeated id params for each song")
    func sendsRepeatedIds() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.savePlayQueue(ids: ["song1", "song2", "song3"])

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/savePlayQueue.view") == true)

        guard let url = req.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { Issue.record("Could not parse URL"); return }

        let ids = components.queryItems?
            .filter { $0.name == "id" }
            .compactMap(\.value) ?? []
        #expect(ids == ["song1", "song2", "song3"])
    }

    @Test("savePlayQueue converts position from seconds to milliseconds")
    func convertsPositionToMs() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        // 75.5 seconds → 75500 milliseconds
        try await client.savePlayQueue(
            ids: ["a"],
            current: "a",
            position: 75.5
        )

        #expect(mock.queryItem(named: "current") == "a")
        #expect(mock.queryItem(named: "position") == "75500")
    }

    @Test("savePlayQueue with empty ids sends no id param")
    func emptyIdsSendsNoIdParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.savePlayQueue(ids: [])

        let req = try #require(mock.lastRequest)
        guard let url = req.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { Issue.record("Could not parse URL"); return }

        let ids = components.queryItems?.filter { $0.name == "id" } ?? []
        #expect(ids.isEmpty)
    }
}
