// Share.swift — SwiftSonic
//
// Model for a public media share link.
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getshares/

import Foundation

/// A public share link created by a user.
///
/// Shares let users distribute media via a public URL without requiring
/// the recipient to have a server account.
public struct Share: Codable, Sendable {

    /// The share identifier.
    public let id: String

    /// The public URL that recipients use to access this share.
    public let url: String

    /// An optional description shown to visitors of the share.
    public let description: String?

    /// The username of the user who created this share.
    public let username: String

    /// The date this share was created.
    public let created: Date

    /// The date this share expires, if set.
    public let expires: Date?

    /// The number of times this share has been visited.
    public let visitCount: Int

    /// The media items included in this share.
    public let entry: [Song]

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case id, url, description, username, created, expires, visitCount, entry
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(String.self, forKey: .id)
        url         = try c.decode(String.self, forKey: .url)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        username    = try c.decode(String.self, forKey: .username)
        created     = try c.decode(Date.self, forKey: .created)
        expires     = try c.decodeIfPresent(Date.self, forKey: .expires)
        visitCount  = try c.decode(Int.self, forKey: .visitCount)
        // entry may be absent when the share has no media items
        entry       = try c.decodeIfPresent([Song].self, forKey: .entry) ?? []
    }
}
