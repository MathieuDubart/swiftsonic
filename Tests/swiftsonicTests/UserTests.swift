// UserTests.swift — SwiftSonicTests
//
// Tests for user management endpoints:
// getUser, getUsers, createUser, updateUser, deleteUser, changePassword

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getUser

@Suite("getUser")
struct GetUserTests {

    @Test("getUser decodes all user fields")
    func decodesFields() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getUser")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let user = try await client.getUser(username: "alice")

        #expect(user.username == "alice")
        #expect(user.email == "alice@example.com")
        #expect(user.scrobblingEnabled == true)
        #expect(user.adminRole == true)
        #expect(user.streamRole == true)
        #expect(user.downloadRole == true)
        #expect(user.jukeboxRole == false)
        #expect(user.folder == [1])
    }

    @Test("getUser sends username param")
    func sendsUsernameParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getUser")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getUser(username: "alice")

        #expect(mock.queryItem(named: "username") == "alice")
    }

    @Test("getUser sends correct endpoint")
    func sendsCorrectEndpoint() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getUser")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getUser(username: "alice")

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/getUser.view") == true)
    }

    @Test("getUser role fields default to false when absent")
    func roleFieldsDefaultToFalse() async throws {
        let minimalFixture = """
        {"subsonic-response":{"status":"ok","version":"1.16.1","user":{"username":"charlie"}}}
        """.data(using: .utf8)!

        let mock = MockHTTPTransport()
        mock.enqueue(minimalFixture)

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let user = try await client.getUser(username: "charlie")

        #expect(user.adminRole == false)
        #expect(user.streamRole == false)
        #expect(user.email == nil)
        #expect(user.folder == nil)
    }
}

// MARK: - getUsers

@Suite("getUsers")
struct GetUsersTests {

    @Test("getUsers decodes user list")
    func decodesUserList() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getUsers")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let users = try await client.getUsers()

        #expect(users.count == 2)
        #expect(users[0].username == "alice")
        #expect(users[0].adminRole == true)
        #expect(users[1].username == "bob")
        #expect(users[1].adminRole == false)
    }

    @Test("getUsers sends correct endpoint")
    func sendsCorrectEndpoint() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getUsers")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getUsers()

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/getUsers.view") == true)
    }
}

// MARK: - createUser

@Suite("createUser")
struct CreateUserTests {

    @Test("createUser sends username, email, and hex-encoded password")
    func sendsRequiredParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let user = NewUser(username: "dave", password: "secret", email: "dave@example.com")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.createUser(user)

        #expect(mock.queryItem(named: "username") == "dave")
        #expect(mock.queryItem(named: "email") == "dave@example.com")
        // "secret" → UTF-8 bytes → hex → "enc:736563726574"
        #expect(mock.queryItem(named: "password") == "enc:736563726574")
    }

    @Test("createUser sends role params when set")
    func sendsRoleParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        var user = NewUser(username: "dave", password: "pw", email: "dave@example.com")
        user.adminRole = true
        user.streamRole = false

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.createUser(user)

        #expect(mock.queryItem(named: "adminRole") == "true")
        #expect(mock.queryItem(named: "streamRole") == "false")
    }

    @Test("createUser sends correct endpoint")
    func sendsCorrectEndpoint() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let user = NewUser(username: "dave", password: "pw", email: "dave@example.com")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.createUser(user)

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/createUser.view") == true)
    }
}

// MARK: - updateUser

@Suite("updateUser")
struct UpdateUserTests {

    @Test("updateUser sends username param")
    func sendsUsernameParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let update = UserUpdate(username: "alice")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.updateUser(update)

        #expect(mock.queryItem(named: "username") == "alice")
    }

    @Test("updateUser hex-encodes password when provided")
    func hexEncodesPassword() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        var update = UserUpdate(username: "alice")
        update.password = "secret"

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.updateUser(update)

        #expect(mock.queryItem(named: "password") == "enc:736563726574")
    }

    @Test("updateUser omits password when not set")
    func omitsPasswordWhenNotSet() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let update = UserUpdate(username: "alice")
        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.updateUser(update)

        #expect(mock.queryItem(named: "password") == nil)
    }

    @Test("updateUser sends email when provided")
    func sendsEmailWhenProvided() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        var update = UserUpdate(username: "alice")
        update.email = "new@example.com"

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.updateUser(update)

        #expect(mock.queryItem(named: "email") == "new@example.com")
    }
}

// MARK: - deleteUser

@Suite("deleteUser")
struct DeleteUserTests {

    @Test("deleteUser sends username param")
    func sendsUsernameParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.deleteUser(username: "bob")

        #expect(mock.queryItem(named: "username") == "bob")
    }

    @Test("deleteUser sends correct endpoint")
    func sendsCorrectEndpoint() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.deleteUser(username: "bob")

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/deleteUser.view") == true)
    }
}

// MARK: - changePassword

@Suite("changePassword")
struct ChangePasswordTests {

    @Test("changePassword hex-encodes the new password")
    func hexEncodesPassword() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.changePassword(username: "alice", newPassword: "secret")

        #expect(mock.queryItem(named: "password") == "enc:736563726574")
    }

    @Test("changePassword sends username param")
    func sendsUsernameParam() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.changePassword(username: "alice", newPassword: "pw")

        #expect(mock.queryItem(named: "username") == "alice")
    }

    @Test("changePassword sends correct endpoint")
    func sendsCorrectEndpoint() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.changePassword(username: "alice", newPassword: "pw")

        #expect(mock.lastRequest?.url?.path.hasSuffix("/rest/changePassword.view") == true)
    }
}
