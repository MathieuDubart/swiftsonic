// SavedPlayQueue.swift — SwiftSonic
//
// Model for a saved play queue (multi-device sync).
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getplayqueue/

import Foundation

/// A play queue saved by the server for the authenticated user.
///
/// Play queues allow resuming playback across sessions and devices.
///
/// - Note: Available since Subsonic API v1.12.0.
public struct SavedPlayQueue: Codable, Sendable {

    /// The songs in the queue, in playback order.
    public let entry: [Song]

    /// The ID of the currently playing song, if any.
    public let current: String?

    /// The playback position within the current song, in seconds.
    ///
    /// Stored as milliseconds on the wire; converted internally.
    public let position: TimeInterval?

    /// The username that saved the queue.
    public let username: String

    /// The date the queue was last saved.
    public let changed: Date

    /// The client name that last saved the queue (e.g. "Navidrome", "DSub").
    public let changedBy: String

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case entry, current, position, username, changed, changedBy
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        entry    = try c.decodeIfPresent([Song].self, forKey: .entry) ?? []
        current  = try c.decodeIfPresent(String.self, forKey: .current)
        username = try c.decode(String.self, forKey: .username)
        changed  = try c.decode(Date.self, forKey: .changed)
        changedBy = try c.decode(String.self, forKey: .changedBy)
        // API sends position in milliseconds; expose as TimeInterval (seconds)
        if let ms = try c.decodeIfPresent(Int64.self, forKey: .position) {
            position = TimeInterval(ms) / 1000
        } else {
            position = nil
        }
    }
}
