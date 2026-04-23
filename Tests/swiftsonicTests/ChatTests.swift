// ChatTests.swift — SwiftSonicTests
//
// Tests for the getChatMessages and addChatMessage endpoints.

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getChatMessages

@Suite("getChatMessages")
struct GetChatMessagesTests {

    @Test("getChatMessages decodes messages with correct fields")
    func decodesMessages() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getChatMessages")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let messages = try await client.getChatMessages()

        #expect(messages.count == 2)

        let first = messages[0]
        #expect(first.username == "alice")
        #expect(first.message == "Hello everyone!")
        // 1714000000000 ms == 1714000000 s since epoch
        #expect(first.time.timeIntervalSince1970 == 1_714_000_000)
    }

    @Test("getChatMessages decodes second message")
    func decodesSecondMessage() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getChatMessages")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let messages = try await client.getChatMessages()

        let second = messages[1]
        #expect(second.username == "bob")
        #expect(second.message == "Hey Alice!")
        #expect(second.time.timeIntervalSince1970 == 1_714_000_060)
    }

    @Test("getChatMessages sends correct endpoint")
    func sendsCorrectEndpoint() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getChatMessages")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getChatMessages()

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/getChatMessages.view") == true)
    }

    @Test("getChatMessages sends no since param by default")
    func sendsNoSinceByDefault() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getChatMessages")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getChatMessages()

        #expect(mock.queryItem(named: "since") == nil)
    }

    @Test("getChatMessages converts since Date to milliseconds")
    func convertsSinceToMs() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getChatMessages")

        let since = Date(timeIntervalSince1970: 1_714_000_000)
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getChatMessages(since: since)

        #expect(mock.queryItem(named: "since") == "1714000000000")
    }

    @Test("getChatMessages returns empty array when there are no messages")
    func returnsEmptyArray() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getChatMessages_empty")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let messages = try await client.getChatMessages()

        #expect(messages.isEmpty)
    }
}

// MARK: - addChatMessage

@Suite("addChatMessage")
struct AddChatMessageTests {

    @Test("addChatMessage sends the message param")
    func sendsMessageParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.addChatMessage("Hello!")

        #expect(mock.queryItem(named: "message") == "Hello!")
    }

    @Test("addChatMessage sends correct endpoint")
    func sendsCorrectEndpoint() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.addChatMessage("Test")

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/addChatMessage.view") == true)
    }
}
