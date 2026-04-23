// Podcast.swift — SwiftSonic
//
// Models for podcast channels and episodes.
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getpodcasts/
//
// Note: PodcastEpisode is an autonomous model — it does not share a protocol
// with Song. App-level code is responsible for any abstraction over both.

import Foundation

// MARK: - Status enums

/// The download/sync status of a podcast channel.
public enum PodcastChannelStatus: String, Decodable, Sendable {
    case new, downloading, completed, error, deleted
    /// Fallback for future or unrecognised status values.
    case unknown

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = PodcastChannelStatus(rawValue: raw) ?? .unknown
    }
}

/// The download/sync status of a podcast episode.
public enum PodcastEpisodeStatus: String, Decodable, Sendable {
    case new, downloading, completed, error, deleted, skipped
    /// Fallback for future or unrecognised status values.
    case unknown

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = PodcastEpisodeStatus(rawValue: raw) ?? .unknown
    }
}

// MARK: - PodcastEpisode

/// A single episode within a podcast channel.
public struct PodcastEpisode: Decodable, Sendable {

    /// The episode identifier.
    public let id: String

    /// The ID of the parent podcast channel.
    public let channelId: String

    /// The ID used to stream this episode, if available.
    public let streamId: String?

    /// The episode title.
    public let title: String

    /// An optional episode summary or show notes.
    public let description: String?

    /// The original publication date of this episode.
    public let publishDate: Date?

    /// The download/sync status of this episode.
    public let status: PodcastEpisodeStatus

    /// The cover art identifier for this episode.
    public let coverArt: String?

    /// Duration of the episode in seconds.
    public let duration: Int?

    /// File size in bytes.
    public let size: Int?

    /// MIME type (e.g. `"audio/mpeg"`).
    public let contentType: String?

    /// File extension (e.g. `"mp3"`).
    public let suffix: String?

    /// Bitrate in kbps.
    public let bitRate: Int?
}

// MARK: - PodcastChannel

/// A podcast feed subscribed to on the server.
public struct PodcastChannel: Decodable, Sendable {

    /// The channel identifier.
    public let id: String

    /// The RSS feed URL.
    public let url: String?

    /// The podcast title.
    public let title: String

    /// An optional channel description.
    public let description: String?

    /// The cover art identifier for this channel.
    public let coverArt: String?

    /// The sync status of this channel.
    public let status: PodcastChannelStatus

    /// An error message present when `status == .error`.
    public let errorMessage: String?

    /// The episodes belonging to this channel.
    ///
    /// Populated only when `includeEpisodes` is `true` (the default).
    public let episode: [PodcastEpisode]

    private enum CodingKeys: String, CodingKey {
        case id, url, title, description, coverArt, status, errorMessage, episode
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(String.self, forKey: .id)
        url          = try c.decodeIfPresent(String.self, forKey: .url)
        title        = try c.decode(String.self, forKey: .title)
        description  = try c.decodeIfPresent(String.self, forKey: .description)
        coverArt     = try c.decodeIfPresent(String.self, forKey: .coverArt)
        status       = try c.decode(PodcastChannelStatus.self, forKey: .status)
        errorMessage = try c.decodeIfPresent(String.self, forKey: .errorMessage)
        // episodes may be absent when includeEpisodes=false, or when there are none
        episode      = try c.decodeIfPresent([PodcastEpisode].self, forKey: .episode) ?? []
    }
}
