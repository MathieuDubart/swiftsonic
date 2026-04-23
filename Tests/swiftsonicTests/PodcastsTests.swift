// PodcastsTests.swift — SwiftSonicTests
//
// Tests for podcast endpoints: getPodcasts, getNewestPodcasts, refreshPodcasts,
// createPodcastChannel, deletePodcastChannel, downloadPodcastEpisode, deletePodcastEpisode.
//
// Fixtures are manual (Navidrome does not support podcasts — returns HTTP 501).
//
// Fixtures:
//   getPodcasts.json       — 2 channels: 1 completed with 2 episodes, 1 in error state
//   getPodcasts_empty.json — empty channels container
//   getNewestPodcasts.json — 2 episodes sorted newest first
//
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getpodcasts/

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getPodcasts

@Suite("getPodcasts")
struct GetPodcastsTests {

    @Test("getPodcasts decodes channels and their episodes")
    func decodesChannels() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getPodcasts")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let channels = try await client.getPodcasts()

        #expect(channels.count == 2)

        // First channel — completed, 2 episodes
        let first = try #require(channels.first)
        #expect(first.id == "ch-1")
        #expect(first.title == "Darknet Diaries")
        #expect(first.status == .completed)
        #expect(first.errorMessage == nil)
        #expect(first.episode.count == 2)

        let ep = first.episode[0]
        #expect(ep.id == "ep-101")
        #expect(ep.channelId == "ch-1")
        #expect(ep.streamId == "stream-101")
        #expect(ep.title == "EP 101: Anonymity")
        #expect(ep.status == .completed)
        #expect(ep.duration == 3120)
        #expect(ep.publishDate != nil)

        // Second channel — error state with message, no episodes
        let second = channels[1]
        #expect(second.id == "ch-2")
        #expect(second.status == .error)
        #expect(second.errorMessage == "Feed unreachable")
        #expect(second.episode.isEmpty)
    }

    @Test("getPodcasts returns empty array when there are no channels")
    func returnsEmptyArray() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getPodcasts_empty")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let channels = try await client.getPodcasts()

        #expect(channels.isEmpty)
    }

    @Test("getPodcasts sends includeEpisodes and optional id params")
    func sendsParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getPodcasts")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getPodcasts(id: "ch-1", includeEpisodes: false)

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/getPodcasts.view") == true)
        #expect(mock.queryItem(named: "id") == "ch-1")
        #expect(mock.queryItem(named: "includeEpisodes") == "false")
    }
}

// MARK: - getNewestPodcasts

@Suite("getNewestPodcasts")
struct GetNewestPodcastsTests {

    @Test("getNewestPodcasts decodes episodes")
    func decodesEpisodes() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getNewestPodcasts")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let episodes = try await client.getNewestPodcasts()

        #expect(episodes.count == 2)
        // Newest first
        #expect(episodes[0].id == "ep-102")
        #expect(episodes[0].status == .new)
        #expect(episodes[1].id == "ep-101")
        #expect(episodes[1].status == .completed)
    }

    @Test("getNewestPodcasts sends count param")
    func sendsCountParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getNewestPodcasts")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getNewestPodcasts(count: 5)

        #expect(mock.queryItem(named: "count") == "5")
    }
}

// MARK: - Management endpoints (void)

@Suite("podcast management")
struct PodcastManagementTests {

    @Test("refreshPodcasts sends the correct path")
    func refreshPodcasts() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.refreshPodcasts()

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/refreshPodcasts.view") == true)
    }

    @Test("createPodcastChannel sends the feed url")
    func createPodcastChannel() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.createPodcastChannel(url: "https://feeds.example.com/show.rss")

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/createPodcastChannel.view") == true)
        #expect(mock.queryItem(named: "url") == "https://feeds.example.com/show.rss")
    }

    @Test("deletePodcastChannel sends the channel id")
    func deletePodcastChannel() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.deletePodcastChannel(id: "ch-1")

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/deletePodcastChannel.view") == true)
        #expect(mock.queryItem(named: "id") == "ch-1")
    }

    @Test("downloadPodcastEpisode sends the episode id")
    func downloadPodcastEpisode() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.downloadPodcastEpisode(id: "ep-101")

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/downloadPodcastEpisode.view") == true)
        #expect(mock.queryItem(named: "id") == "ep-101")
    }

    @Test("deletePodcastEpisode sends the episode id")
    func deletePodcastEpisode() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.deletePodcastEpisode(id: "ep-101")

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/deletePodcastEpisode.view") == true)
        #expect(mock.queryItem(named: "id") == "ep-101")
    }
}
