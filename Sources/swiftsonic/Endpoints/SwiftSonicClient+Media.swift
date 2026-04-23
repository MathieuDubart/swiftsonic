// SwiftSonicClient+Media.swift — SwiftSonic
//
// Media URL helpers: stream, download, getCoverArt, hls.
//
// These methods do NOT make a network request. They return a fully-authenticated
// URL that you can pass directly to AVPlayer, AVAsset, or an image loading system.
// The server will authenticate the request using the same token/salt/apiKey params
// that are embedded in the URL.

import Foundation

// MARK: - Media URL helpers

public extension SwiftSonicClient {

    /// Returns an authenticated streaming URL for a song.
    ///
    /// Pass the returned URL directly to `AVPlayer` or `AVAudioPlayer`.
    ///
    /// ```swift
    /// if let url = client.streamURL(id: "101") {
    ///     let player = AVPlayer(url: url)
    ///     player.play()
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - id: The ID of the song to stream.
    ///   - maxBitRate: The maximum bit rate for transcoding, in kilobits per second.
    ///   - format: The preferred audio format (e.g. `"mp3"`, `"opus"`). Use `"raw"` to disable transcoding.
    ///   - timeOffset: Start the stream at this offset (seconds). Useful for seeking.
    ///   - size: Only for video streams — the requested resolution (`"WxH"`).
    ///   - estimateContentLength: Whether the server should estimate `Content-Length` for transcoded streams.
    ///   - converted: Whether to request the converted version of the file.
    /// - Returns: An authenticated `URL`, or `nil` if the URL cannot be constructed.
    nonisolated func streamURL(
        id: String,
        maxBitRate: Int? = nil,
        format: String? = nil,
        timeOffset: Int? = nil,
        size: String? = nil,
        estimateContentLength: Bool? = nil,
        converted: Bool? = nil
    ) -> URL? {
        var params: [String: String] = ["id": id]
        if let v = maxBitRate            { params["maxBitRate"]            = String(v) }
        if let v = format                { params["format"]                = v }
        if let v = timeOffset            { params["timeOffset"]            = String(v) }
        if let v = size                  { params["size"]                  = v }
        if let v = estimateContentLength { params["estimateContentLength"] = v ? "true" : "false" }
        if let v = converted             { params["converted"]             = v ? "true" : "false" }
        return requestBuilder.mediaURL(endpoint: "stream", params: params)
    }

    /// Returns an authenticated download URL for a song.
    ///
    /// - Parameter id: The ID of the song to download.
    /// - Returns: An authenticated `URL`, or `nil` if the URL cannot be constructed.
    nonisolated func downloadURL(id: String) -> URL? {
        requestBuilder.mediaURL(endpoint: "download", params: ["id": id])
    }

    /// Returns an authenticated cover art URL.
    ///
    /// ```swift
    /// if let url = client.coverArtURL(id: "al-10", size: 300) {
    ///     // Pass url to AsyncImage or your image loading library
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - id: The cover art ID (typically from `Album.coverArt`, `Artist.coverArt`, etc.).
    ///   - size: Desired image dimension in pixels. If omitted, the server returns the full-size image.
    /// - Returns: An authenticated `URL`, or `nil` if the URL cannot be constructed.
    nonisolated func coverArtURL(id: String, size: Int? = nil) -> URL? {
        var params: [String: String] = ["id": id]
        if let v = size { params["size"] = String(v) }
        return requestBuilder.mediaURL(endpoint: "getCoverArt", params: params)
    }

    /// Returns an authenticated HLS playlist URL for adaptive streaming.
    ///
    /// - Parameters:
    ///   - id: The ID of the song or video.
    ///   - audioBitRate: Desired audio bit rate for the HLS stream.
    ///   - audioTrack: The `id` of the audio track to use for videos with multiple tracks.
    /// - Returns: An authenticated `URL`, or `nil` if the URL cannot be constructed.
    nonisolated func hlsURL(
        id: String,
        audioBitRate: Int? = nil,
        audioTrack: String? = nil
    ) -> URL? {
        var params: [String: String] = ["id": id]
        if let v = audioBitRate { params["audioBitRate"] = String(v) }
        if let v = audioTrack   { params["audioTrack"]  = v }
        return requestBuilder.mediaURL(endpoint: "hls", params: params)
    }
}
