// JukeboxTests.swift — SwiftSonicTests
//
// Tests for jukebox control endpoints.
// All fixtures are manual (Navidrome does not support the jukebox API).
//
// Fixtures:
//   jukeboxGet.json    — jukeboxPlaylist: 2 NIN songs, playing, gain=0.75, position=42
//   jukeboxStatus.json — jukeboxStatus: stopped, gain=0.5, position=0
//
// Spec: https://opensubsonic.netlify.app/docs/endpoints/jukeboxcontrol/

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - jukeboxGet

@Suite("jukeboxGet")
struct JukeboxGetTests {

    @Test("jukeboxGet decodes the playlist and player state")
    func decodesPlaylist() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxGet")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let playlist = try await client.jukeboxGet()

        #expect(playlist.currentIndex == 0)
        #expect(playlist.playing == true)
        #expect(abs(playlist.gain - 0.75) < 0.001)
        #expect(playlist.position == 42)

        #expect(playlist.entry.count == 2)
        #expect(playlist.entry[0].id == "rF7kG3QpkR3tBqT8GwGiKF")
        #expect(playlist.entry[0].title == "999,999")
        #expect(playlist.entry[1].id == "TVqMwb9ALbg8fT3FKCAEDE")
    }

    @Test("jukeboxGet sends action=get")
    func sendsActionGet() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxGet")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.jukeboxGet()

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/jukeboxControl.view") == true)
        #expect(mock.queryItem(named: "action") == "get")
    }
}

// MARK: - jukeboxStatus

@Suite("jukeboxStatus")
struct JukeboxStatusTests {

    @Test("jukeboxStatus decodes the player state")
    func decodesStatus() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxStatus")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let status = try await client.jukeboxStatus()

        #expect(status.currentIndex == 0)
        #expect(status.playing == false)
        #expect(abs(status.gain - 0.5) < 0.001)
        #expect(status.position == 0)
    }

    @Test("jukeboxStatus sends action=status")
    func sendsActionStatus() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxStatus")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.jukeboxStatus()

        #expect(mock.queryItem(named: "action") == "status")
    }
}

// MARK: - Playback control actions

@Suite("jukebox playback control")
struct JukeboxPlaybackTests {

    @Test("jukeboxStart sends action=start")
    func start() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxStatus")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.jukeboxStart()
        #expect(mock.queryItem(named: "action") == "start")
    }

    @Test("jukeboxStop sends action=stop")
    func stop() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxStatus")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.jukeboxStop()
        #expect(mock.queryItem(named: "action") == "stop")
    }

    @Test("jukeboxClear sends action=clear")
    func clear() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxStatus")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.jukeboxClear()
        #expect(mock.queryItem(named: "action") == "clear")
    }

    @Test("jukeboxShuffle sends action=shuffle")
    func shuffle() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxStatus")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.jukeboxShuffle()
        #expect(mock.queryItem(named: "action") == "shuffle")
    }

    @Test("jukeboxSkip sends action=skip, index, and optional offset")
    func skip() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxStatus")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.jukeboxSkip(index: 2, offset: 30)
        #expect(mock.queryItem(named: "action") == "skip")
        #expect(mock.queryItem(named: "index") == "2")
        #expect(mock.queryItem(named: "offset") == "30")
    }

    @Test("jukeboxSkip omits offset when it is zero")
    func skipNoOffset() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxStatus")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.jukeboxSkip(index: 1)
        #expect(mock.queryItem(named: "offset") == nil)
    }

    @Test("jukeboxRemove sends action=remove and index")
    func remove() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxStatus")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.jukeboxRemove(index: 1)
        #expect(mock.queryItem(named: "action") == "remove")
        #expect(mock.queryItem(named: "index") == "1")
    }
}

// MARK: - Playlist mutation actions

@Suite("jukebox playlist mutation")
struct JukeboxPlaylistMutationTests {

    @Test("jukeboxAdd sends action=add with repeated id params")
    func add() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxStatus")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.jukeboxAdd(ids: ["s1", "s2"])

        #expect(mock.queryItem(named: "action") == "add")

        guard let url = mock.lastRequest?.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { Issue.record("Could not parse URL"); return }
        let ids = components.queryItems?.filter { $0.name == "id" }.compactMap(\.value) ?? []
        #expect(ids == ["s1", "s2"])
    }

    @Test("jukeboxSet sends action=set with repeated id params")
    func set() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxStatus")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.jukeboxSet(ids: ["a", "b", "c"])

        #expect(mock.queryItem(named: "action") == "set")

        guard let url = mock.lastRequest?.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { Issue.record("Could not parse URL"); return }
        let ids = components.queryItems?.filter { $0.name == "id" }.compactMap(\.value) ?? []
        #expect(ids == ["a", "b", "c"])
    }
}

// MARK: - Volume

@Suite("jukeboxSetGain")
struct JukeboxSetGainTests {

    @Test("jukeboxSetGain sends action=setGain and gain value")
    func setGain() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "jukeboxStatus")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.jukeboxSetGain(0.8)

        #expect(mock.queryItem(named: "action") == "setGain")
        // The gain is sent as a float string; verify it starts with "0.8"
        let gainStr = try #require(mock.queryItem(named: "gain"))
        #expect(gainStr.hasPrefix("0.8"))
    }
}
