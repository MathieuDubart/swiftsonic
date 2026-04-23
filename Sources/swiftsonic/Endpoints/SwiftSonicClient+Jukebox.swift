// SwiftSonicClient+Jukebox.swift — SwiftSonic
//
// Jukebox control endpoints.
// Spec: https://opensubsonic.netlify.app/docs/endpoints/jukeboxcontrol/
//
// The jukebox lets a client control audio playback on the server itself.
// All methods map to the single jukeboxControl endpoint with different
// action values.
//
// Methods that modify the playlist/state return JukeboxStatus.
// jukeboxGet() returns JukeboxPlaylist (includes the song list).

import Foundation

// MARK: - Jukebox endpoints

public extension SwiftSonicClient {

    /// Returns the current playlist and player state.
    ///
    /// ```swift
    /// let playlist = try await client.jukeboxGet()
    /// print("Now playing: \(playlist.entry[playlist.currentIndex].title)")
    /// ```
    ///
    /// - Returns: A ``JukeboxPlaylist`` containing songs and playback state.
    func jukeboxGet() async throws -> JukeboxPlaylist {
        let envelope: SubsonicEnvelope<JukeboxPlaylistPayload> =
            try await performDecode(
                endpoint: "jukeboxControl",
                params: ["action": "get"]
            )
        return try unwrapRequired(
            envelope.payload?.jukeboxPlaylist,
            endpoint: "jukeboxControl(get)"
        )
    }

    /// Returns the current player state without the song list.
    ///
    /// ```swift
    /// let status = try await client.jukeboxStatus()
    /// print("Playing: \(status.playing), gain: \(status.gain)")
    /// ```
    ///
    /// - Returns: A ``JukeboxStatus`` with playback state.
    func jukeboxStatus() async throws -> JukeboxStatus {
        try await jukeboxAction(["action": "status"])
    }

    /// Starts playback.
    @discardableResult
    func jukeboxStart() async throws -> JukeboxStatus {
        try await jukeboxAction(["action": "start"])
    }

    /// Stops playback.
    @discardableResult
    func jukeboxStop() async throws -> JukeboxStatus {
        try await jukeboxAction(["action": "stop"])
    }

    /// Skips to the specified track in the playlist.
    ///
    /// - Parameters:
    ///   - index: Zero-based index of the track to skip to.
    ///   - offset: Seconds into the track to start at (default 0).
    @discardableResult
    func jukeboxSkip(index: Int, offset: Int = 0) async throws -> JukeboxStatus {
        var params: [String: String] = ["action": "skip", "index": String(index)]
        if offset > 0 { params["offset"] = String(offset) }
        return try await jukeboxAction(params)
    }

    /// Appends songs to the end of the playlist.
    ///
    /// - Parameter ids: Song IDs to add.
    @discardableResult
    func jukeboxAdd(ids: [String]) async throws -> JukeboxStatus {
        try await jukeboxAction(["action": "add"], multiParams: ["id": ids])
    }

    /// Replaces the entire playlist with the given songs.
    ///
    /// - Parameter ids: Song IDs to set as the new playlist.
    @discardableResult
    func jukeboxSet(ids: [String]) async throws -> JukeboxStatus {
        try await jukeboxAction(["action": "set"], multiParams: ["id": ids])
    }

    /// Removes the track at the specified position from the playlist.
    ///
    /// - Parameter index: Zero-based index of the track to remove.
    @discardableResult
    func jukeboxRemove(index: Int) async throws -> JukeboxStatus {
        try await jukeboxAction(["action": "remove", "index": String(index)])
    }

    /// Clears the entire playlist.
    @discardableResult
    func jukeboxClear() async throws -> JukeboxStatus {
        try await jukeboxAction(["action": "clear"])
    }

    /// Shuffles the current playlist.
    @discardableResult
    func jukeboxShuffle() async throws -> JukeboxStatus {
        try await jukeboxAction(["action": "shuffle"])
    }

    /// Sets the playback volume.
    ///
    /// - Parameter gain: Volume level from `0.0` (silent) to `1.0` (full).
    @discardableResult
    func jukeboxSetGain(_ gain: Float) async throws -> JukeboxStatus {
        try await jukeboxAction(["action": "setGain", "gain": String(gain)])
    }
}

// MARK: - Private helpers

private extension SwiftSonicClient {

    func jukeboxAction(
        _ params: [String: String],
        multiParams: [String: [String]] = [:]
    ) async throws -> JukeboxStatus {
        let envelope: SubsonicEnvelope<JukeboxStatusPayload> =
            try await performDecode(
                endpoint: "jukeboxControl",
                params: params,
                multiParams: multiParams
            )
        return try unwrapRequired(
            envelope.payload?.jukeboxStatus,
            endpoint: "jukeboxControl(\(params["action"] ?? "?"))"
        )
    }
}

// MARK: - Response payloads (internal)

struct JukeboxStatusPayload: SubsonicPayload {
    static let payloadKey = "jukeboxStatus"
    let jukeboxStatus: JukeboxStatus
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        jukeboxStatus = try container.decode(JukeboxStatus.self)
    }
}

struct JukeboxPlaylistPayload: SubsonicPayload {
    static let payloadKey = "jukeboxPlaylist"
    let jukeboxPlaylist: JukeboxPlaylist
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        jukeboxPlaylist = try container.decode(JukeboxPlaylist.self)
    }
}
