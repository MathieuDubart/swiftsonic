// Jukebox.swift — SwiftSonic
//
// Models for the jukebox control API.
// Spec: https://opensubsonic.netlify.app/docs/endpoints/jukeboxcontrol/
//
// The jukebox allows the client to control media playback on the server itself
// (e.g. a headless NAS with speakers attached).

import Foundation

/// The current state of the server-side jukebox player.
///
/// Returned by every jukebox action except ``SwiftSonicClient/jukeboxGet()``.
public struct JukeboxStatus: Decodable, Sendable {

    /// Zero-based index of the currently playing track in the playlist.
    public let currentIndex: Int

    /// Whether the jukebox is currently playing.
    public let playing: Bool

    /// The current volume level, from `0.0` (silent) to `1.0` (full).
    public let gain: Float

    /// The playback position within the current track, in seconds.
    public let position: Int
}

/// The current state of the server-side jukebox player, including its playlist.
///
/// Returned by ``SwiftSonicClient/jukeboxGet()``.
public struct JukeboxPlaylist: Decodable, Sendable {

    /// Zero-based index of the currently playing track.
    public let currentIndex: Int

    /// Whether the jukebox is currently playing.
    public let playing: Bool

    /// The current volume level, from `0.0` (silent) to `1.0` (full).
    public let gain: Float

    /// The playback position within the current track, in seconds.
    public let position: Int

    /// The songs currently in the jukebox playlist.
    public let entry: [Song]

    private enum CodingKeys: String, CodingKey {
        case currentIndex, playing, gain, position, entry
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentIndex = try c.decode(Int.self, forKey: .currentIndex)
        playing      = try c.decode(Bool.self, forKey: .playing)
        gain         = try c.decode(Float.self, forKey: .gain)
        position     = try c.decode(Int.self, forKey: .position)
        // entry is absent when the playlist is empty
        entry        = try c.decodeIfPresent([Song].self, forKey: .entry) ?? []
    }
}
