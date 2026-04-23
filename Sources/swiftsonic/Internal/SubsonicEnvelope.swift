// SubsonicEnvelope.swift — SwiftSonic (Internal)
//
// Handles decoding of the Subsonic/OpenSubsonic JSON response envelope.
//
// Every API response is wrapped in a "subsonic-response" key (note the hyphen),
// which prevents automatic Codable synthesis. Inside, each endpoint places its
// payload under a unique key (e.g. "artists", "album", "song").
//
// Strategy:
//   1. SubsonicPayload: a protocol that lets each response type declare its key.
//   2. SubsonicEnvelope<P>: a generic Decodable that unwraps the outer
//      "subsonic-response" container and decodes the inner payload using P.payloadKey.
//   3. RawErrorBody: decodes the optional "error" field from the envelope.

import Foundation

// MARK: - Payload protocol

/// Marks a type as the payload of a Subsonic API response and declares the JSON key
/// under which it is nested inside the `"subsonic-response"` envelope.
///
/// Example:
/// ```swift
/// struct ArtistsPayload: SubsonicPayload {
///     static let payloadKey = "artists"
///     let index: [ArtistIndex]
/// }
/// ```
protocol SubsonicPayload: Decodable, Sendable {
    /// The JSON key for this payload within the `"subsonic-response"` container.
    static var payloadKey: String { get }
}

// MARK: - Empty payload (for void responses like ping, star, scrobble)

/// A payload type for endpoints that return no data on success (e.g. `ping`, `star`).
struct EmptyPayload: SubsonicPayload {
    static let payloadKey = "__empty__"
}

// MARK: - Dynamic coding key

/// A `CodingKey` backed by a runtime string, used to decode dynamic payload keys.
struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

// MARK: - Raw error body (Codable, internal)

struct RawErrorBody: Decodable, Sendable {
    let code: Int
    let message: String
    let helpUrl: String?
}

// MARK: - Response status

enum ResponseStatus: String, Decodable, Sendable {
    case ok
    case failed
}

// MARK: - Generic envelope

/// Decodes the Subsonic `"subsonic-response"` JSON envelope and extracts the typed payload.
struct SubsonicEnvelope<P: SubsonicPayload>: Decodable, Sendable {
    let status: ResponseStatus
    let version: String
    let serverType: String?
    let serverVersion: String?
    let isOpenSubsonic: Bool?
    let error: RawErrorBody?
    let payload: P?

    // Outer key
    private enum OuterKeys: String, CodingKey {
        case subsonicResponse = "subsonic-response"
    }

    // Inner fixed keys (always present)
    private enum InnerKeys: String, CodingKey {
        case status, version
        case serverType = "type"
        case serverVersion
        case openSubsonic
        case error
    }

    init(from decoder: any Decoder) throws {
        // 1. Unwrap the outer "subsonic-response" key
        let outer = try decoder.container(keyedBy: OuterKeys.self)
        let inner = try outer.nestedContainer(keyedBy: InnerKeys.self, forKey: .subsonicResponse)

        // 2. Decode fixed fields
        status = try inner.decode(ResponseStatus.self, forKey: .status)
        version = try inner.decode(String.self, forKey: .version)
        serverType = try inner.decodeIfPresent(String.self, forKey: .serverType)
        serverVersion = try inner.decodeIfPresent(String.self, forKey: .serverVersion)
        isOpenSubsonic = try inner.decodeIfPresent(Bool.self, forKey: .openSubsonic)
        error = try inner.decodeIfPresent(RawErrorBody.self, forKey: .error)

        // 3. Decode the dynamic payload key (skip for EmptyPayload)
        let payloadKey = P.payloadKey
        if payloadKey != EmptyPayload.payloadKey {
            let dynamic = try outer.nestedContainer(keyedBy: DynamicKey.self, forKey: .subsonicResponse)
            payload = try dynamic.decodeIfPresent(P.self, forKey: DynamicKey(stringValue: payloadKey))
        } else {
            payload = nil
        }
    }
}
