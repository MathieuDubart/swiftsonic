// SwiftSonicClient+Shares.swift — SwiftSonic
//
// Share management endpoints: getShares, createShare, updateShare, deleteShare.
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getshares/
//
// Shares let users expose media items via a public URL without requiring the
// recipient to have a server account.
//
// Note: expires is expressed as Date in the Swift API; converted to/from
// milliseconds-since-epoch when communicating with the server.

import Foundation

// MARK: - Share endpoints

public extension SwiftSonicClient {

    /// Returns all shares owned or accessible by the authenticated user.
    ///
    /// ```swift
    /// let shares = try await client.getShares()
    /// for share in shares {
    ///     print("\(share.url) — \(share.visitCount) visits")
    /// }
    /// ```
    ///
    /// - Returns: An array of ``Share`` objects, empty if none exist.
    func getShares() async throws -> [Share] {
        let envelope: SubsonicEnvelope<SharesPayload> =
            try await performDecode(endpoint: "getShares", params: [:])
        return envelope.payload?.shares.share ?? []
    }

    /// Creates a new share for the given media items.
    ///
    /// ```swift
    /// let shares = try await client.createShare(
    ///     ids: ["song1", "song2"],
    ///     description: "Weekend playlist",
    ///     expires: Date().addingTimeInterval(7 * 24 * 3600)
    /// )
    /// print(shares.first?.url ?? "—")
    /// ```
    ///
    /// - Parameters:
    ///   - ids: IDs of songs, albums, or videos to include in the share.
    ///   - description: An optional description shown to visitors.
    ///   - expires: An optional expiry date for the share.
    /// - Returns: The newly created ``Share`` objects as returned by the server.
    func createShare(
        ids: [String],
        description: String? = nil,
        expires: Date? = nil
    ) async throws -> [Share] {
        var params: [String: String] = [:]
        if let d = description { params["description"] = d }
        if let exp = expires {
            params["expires"] = String(Int64(exp.timeIntervalSince1970 * 1000))
        }
        let multiParams: [String: [String]] = ids.isEmpty ? [:] : ["id": ids]
        let envelope: SubsonicEnvelope<SharesPayload> =
            try await performDecode(
                endpoint: "createShare",
                params: params,
                multiParams: multiParams
            )
        return envelope.payload?.shares.share ?? []
    }

    /// Updates the description or expiry of an existing share.
    ///
    /// Pass `expires: Date(timeIntervalSince1970: 0)` to remove the expiry.
    ///
    /// ```swift
    /// try await client.updateShare(id: "42", description: "Updated title")
    /// ```
    ///
    /// - Parameters:
    ///   - id: The ID of the share to update.
    ///   - description: A new description, or `nil` to leave it unchanged.
    ///   - expires: A new expiry date, or `nil` to leave it unchanged.
    ///     Pass `Date(timeIntervalSince1970: 0)` to clear the expiry.
    func updateShare(
        id: String,
        description: String? = nil,
        expires: Date? = nil
    ) async throws {
        var params: [String: String] = ["id": id]
        if let d = description { params["description"] = d }
        if let exp = expires {
            params["expires"] = String(Int64(exp.timeIntervalSince1970 * 1000))
        }
        try await performVoid(endpoint: "updateShare", params: params)
    }

    /// Deletes the share with the given ID.
    ///
    /// ```swift
    /// try await client.deleteShare(id: "42")
    /// ```
    ///
    /// - Parameter id: The ID of the share to delete.
    func deleteShare(id: String) async throws {
        try await performVoid(endpoint: "deleteShare", params: ["id": id])
    }
}

// MARK: - Response payloads (internal)

struct SharesContainer: Decodable, Sendable {
    // Optional: absent when the server returns an empty object `{}`
    let share: [Share]?
}

struct SharesPayload: SubsonicPayload {
    static let payloadKey = "shares"
    let shares: SharesContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        shares = try container.decode(SharesContainer.self)
    }
}
