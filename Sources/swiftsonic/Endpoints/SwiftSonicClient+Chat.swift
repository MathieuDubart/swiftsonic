// SwiftSonicClient+Chat.swift — SwiftSonic
//
// Chat endpoints: read and post server-wide chat messages.
//
// Covered: getChatMessages, addChatMessage

import Foundation

// MARK: - Chat endpoints

extension SwiftSonicClient {

    // MARK: getChatMessages

    /// Returns a list of the current chat messages.
    ///
    /// ```swift
    /// let messages = try await client.getChatMessages()
    /// for msg in messages {
    ///     print("\(msg.username): \(msg.message)")
    /// }
    /// ```
    ///
    /// - Parameter since: When provided, only messages posted *after* this date
    ///   are returned. Pass `nil` to retrieve all recent messages.
    /// - Returns: An array of ``ChatMessage`` values in chronological order,
    ///   or an empty array when there are no messages.
    public func getChatMessages(since: Date? = nil) async throws -> [ChatMessage] {
        var params: [String: String] = [:]
        if let since {
            params["since"] = String(Int64(since.timeIntervalSince1970 * 1000))
        }
        let envelope: SubsonicEnvelope<ChatMessagesPayload> =
            try await performDecode(endpoint: "getChatMessages", params: params)
        return envelope.payload?.chatMessages.chatMessage ?? []
    }

    // MARK: addChatMessage

    /// Posts a new message to the server's chat.
    ///
    /// ```swift
    /// try await client.addChatMessage("Hello everyone!")
    /// ```
    ///
    /// - Parameter message: The text of the message to post.
    public func addChatMessage(_ message: String) async throws {
        let _: SubsonicEnvelope<EmptyPayload> =
            try await performDecode(endpoint: "addChatMessage", params: ["message": message])
    }
}

// MARK: - Response payloads (internal)

struct ChatMessagesContainer: Decodable, Sendable {
    let chatMessage: [ChatMessage]?
}

struct ChatMessagesPayload: SubsonicPayload {
    static let payloadKey = "chatMessages"
    let chatMessages: ChatMessagesContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        chatMessages = try container.decode(ChatMessagesContainer.self)
    }
}
