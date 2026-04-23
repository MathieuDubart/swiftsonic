// SwiftSonicClient+Podcasts.swift — SwiftSonic
//
// Podcast endpoints: getPodcasts, getNewestPodcasts, refreshPodcasts,
// createPodcastChannel, deletePodcastChannel,
// downloadPodcastEpisode, deletePodcastEpisode.
//
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getpodcasts/
//
// Note: Podcast administration (create/delete/download) requires the user to
// have podcast admin privileges on the server.

import Foundation

// MARK: - Podcast endpoints

public extension SwiftSonicClient {

    /// Returns all podcast channels, optionally filtered to a single channel.
    ///
    /// ```swift
    /// let channels = try await client.getPodcasts()
    /// for channel in channels {
    ///     print("\(channel.title): \(channel.episode.count) episodes")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - id: If provided, returns only the channel with this ID.
    ///   - includeEpisodes: When `true` (default), episodes are included in the response.
    /// - Returns: An array of ``PodcastChannel`` objects, empty if none exist.
    func getPodcasts(
        id: String? = nil,
        includeEpisodes: Bool = true
    ) async throws -> [PodcastChannel] {
        var params: [String: String] = [
            "includeEpisodes": includeEpisodes ? "true" : "false",
        ]
        if let id { params["id"] = id }
        let envelope: SubsonicEnvelope<PodcastsPayload> =
            try await performDecode(endpoint: "getPodcasts", params: params)
        return envelope.payload?.podcasts.channel ?? []
    }

    /// Returns the most recently published podcast episodes across all channels.
    ///
    /// ```swift
    /// let latest = try await client.getNewestPodcasts(count: 10)
    /// for ep in latest {
    ///     print("\(ep.title) — \(ep.publishDate?.description ?? "no date")")
    /// }
    /// ```
    ///
    /// - Parameter count: Maximum number of episodes to return (default 20).
    /// - Returns: An array of ``PodcastEpisode`` objects sorted by publication date.
    func getNewestPodcasts(count: Int = 20) async throws -> [PodcastEpisode] {
        let params: [String: String] = ["count": String(count)]
        let envelope: SubsonicEnvelope<NewestPodcastsPayload> =
            try await performDecode(endpoint: "getNewestPodcasts", params: params)
        return envelope.payload?.newestPodcasts.episode ?? []
    }

    /// Triggers a server-side refresh of all podcast channel feeds.
    ///
    /// ```swift
    /// try await client.refreshPodcasts()
    /// ```
    func refreshPodcasts() async throws {
        try await performVoid(endpoint: "refreshPodcasts", params: [:])
    }

    /// Subscribes the server to a new podcast feed.
    ///
    /// ```swift
    /// try await client.createPodcastChannel(url: "https://feeds.example.com/show.rss")
    /// ```
    ///
    /// - Parameter url: The RSS feed URL to subscribe to.
    func createPodcastChannel(url: String) async throws {
        try await performVoid(endpoint: "createPodcastChannel", params: ["url": url])
    }

    /// Deletes a podcast channel and all its downloaded episodes.
    ///
    /// ```swift
    /// try await client.deletePodcastChannel(id: "42")
    /// ```
    ///
    /// - Parameter id: The ID of the channel to delete.
    func deletePodcastChannel(id: String) async throws {
        try await performVoid(endpoint: "deletePodcastChannel", params: ["id": id])
    }

    /// Queues a podcast episode for download on the server.
    ///
    /// ```swift
    /// try await client.downloadPodcastEpisode(id: "ep-7")
    /// ```
    ///
    /// - Parameter id: The ID of the episode to download.
    func downloadPodcastEpisode(id: String) async throws {
        try await performVoid(endpoint: "downloadPodcastEpisode", params: ["id": id])
    }

    /// Deletes a downloaded podcast episode from the server.
    ///
    /// ```swift
    /// try await client.deletePodcastEpisode(id: "ep-7")
    /// ```
    ///
    /// - Parameter id: The ID of the episode to delete.
    func deletePodcastEpisode(id: String) async throws {
        try await performVoid(endpoint: "deletePodcastEpisode", params: ["id": id])
    }
}

// MARK: - Response payloads (internal)

struct PodcastsContainer: Decodable, Sendable {
    // Optional: absent when server returns empty object `{}`
    let channel: [PodcastChannel]?
}

struct PodcastsPayload: SubsonicPayload {
    static let payloadKey = "podcasts"
    let podcasts: PodcastsContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        podcasts = try container.decode(PodcastsContainer.self)
    }
}

struct NewestPodcastsContainer: Decodable, Sendable {
    let episode: [PodcastEpisode]?
}

struct NewestPodcastsPayload: SubsonicPayload {
    static let payloadKey = "newestPodcasts"
    let newestPodcasts: NewestPodcastsContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        newestPodcasts = try container.decode(NewestPodcastsContainer.self)
    }
}
