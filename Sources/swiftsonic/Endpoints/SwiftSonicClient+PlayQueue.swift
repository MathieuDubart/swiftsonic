// SwiftSonicClient+PlayQueue.swift — SwiftSonic
//
// Play queue sync endpoints: getPlayQueue, savePlayQueue.
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getplayqueue/
//
// Play queues enable resuming playback across devices and sessions.
// Position is expressed in seconds (TimeInterval) in the Swift API; converted
// to/from milliseconds when communicating with the server.
//
// Note: Available since Subsonic API v1.12.0.

import Foundation

// MARK: - Play Queue endpoints

public extension SwiftSonicClient {

    /// Returns the play queue saved by the authenticated user.
    ///
    /// Returns `nil` if the user has never saved a queue.
    ///
    /// ```swift
    /// if let queue = try await client.getPlayQueue() {
    ///     print("Resuming at \(queue.position ?? 0)s in \(queue.current ?? "—")")
    /// }
    /// ```
    ///
    /// - Returns: The saved ``SavedPlayQueue``, or `nil` if none exists.
    func getPlayQueue() async throws -> SavedPlayQueue? {
        let envelope: SubsonicEnvelope<PlayQueuePayload> =
            try await performDecode(endpoint: "getPlayQueue", params: [:])
        return envelope.payload?.playQueue
    }

    /// Saves the current play queue to the server.
    ///
    /// Call this periodically to persist the queue for multi-device sync.
    /// Pass an empty `ids` array to clear the saved queue.
    ///
    /// ```swift
    /// // Save the current queue with the current track and position
    /// try await client.savePlayQueue(
    ///     ids: songs.map(\.id),
    ///     current: currentSong.id,
    ///     position: player.currentTime
    /// )
    ///
    /// // Clear the queue
    /// try await client.savePlayQueue(ids: [])
    /// ```
    ///
    /// - Parameters:
    ///   - ids: The ordered song IDs in the queue.
    ///   - current: The ID of the currently playing song.
    ///   - position: The playback position in the current song, in seconds.
    ///
    /// - Note: On OpenSubsonic servers `ids` may be empty to clear the queue;
    ///   original Subsonic servers expect at least one entry.
    func savePlayQueue(
        ids: [String],
        current: String? = nil,
        position: TimeInterval? = nil
    ) async throws {
        var params: [String: String] = [:]
        if let current { params["current"] = current }
        if let pos = position {
            params["position"] = String(Int64(pos * 1000))
        }
        let multiParams: [String: [String]] = ids.isEmpty ? [:] : ["id": ids]
        try await performVoid(
            endpoint: "savePlayQueue",
            params: params,
            multiParams: multiParams
        )
    }
}

// MARK: - Response payload (internal)

struct PlayQueuePayload: SubsonicPayload {
    static let payloadKey = "playQueue"
    let playQueue: SavedPlayQueue
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        playQueue = try container.decode(SavedPlayQueue.self)
    }
}
