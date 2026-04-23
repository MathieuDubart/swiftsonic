// ChatMessage.swift — SwiftSonic
//
// Data model for chat messages returned by the getChatMessages endpoint.

import Foundation

// MARK: - ChatMessage

/// A chat message posted to the server.
///
/// Returned by ``SwiftSonicClient/getChatMessages(since:)``.
public struct ChatMessage: Decodable, Sendable {

    /// The username of the user who posted the message.
    public let username: String

    /// The time the message was posted.
    ///
    /// The wire value is milliseconds since Unix epoch; SwiftSonic converts it
    /// to a Swift `Date` automatically.
    public let time: Date

    /// The message text.
    public let message: String

    // MARK: Decoding (ms → Date)

    private enum CodingKeys: String, CodingKey {
        case username, time, message
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        let ms = try container.decode(Double.self, forKey: .time)
        time = Date(timeIntervalSince1970: ms / 1000)
        message = try container.decode(String.self, forKey: .message)
    }
}
