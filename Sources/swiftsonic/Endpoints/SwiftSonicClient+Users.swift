// SwiftSonicClient+Users.swift — SwiftSonic
//
// User management endpoints: read, create, update, delete, change password.
//
// Covered: getUser, getUsers, createUser, updateUser, deleteUser, changePassword

import Foundation

// MARK: - User management endpoints

extension SwiftSonicClient {

    // MARK: getUser

    /// Returns details for a specific user.
    ///
    /// - Parameter username: The username of the account to fetch.
    /// - Returns: The ``User`` for the given username.
    public func getUser(username: String) async throws -> User {
        let envelope: SubsonicEnvelope<UserPayload> =
            try await performDecode(endpoint: "getUser", params: ["username": username])
        return try unwrapRequired(envelope.payload?.user, endpoint: "getUser")
    }

    // MARK: getUsers

    /// Returns all users on the server.
    ///
    /// Requires admin privileges on most servers.
    ///
    /// - Returns: An array of ``User`` values, or an empty array when there are no users.
    public func getUsers() async throws -> [User] {
        let envelope: SubsonicEnvelope<UsersPayload> =
            try await performDecode(endpoint: "getUsers", params: [:])
        return envelope.payload?.users.user ?? []
    }

    // MARK: createUser

    /// Creates a new user account.
    ///
    /// - Parameter user: A ``NewUser`` describing the account to create.
    public func createUser(_ user: NewUser) async throws {
        var params: [String: String] = [
            "username": user.username,
            "password": hexEncodePassword(user.password),
            "email":    user.email,
        ]
        if let v = user.ldapAuthenticated   { params["ldapAuthenticated"]   = String(v) }
        if let v = user.adminRole           { params["adminRole"]           = String(v) }
        if let v = user.settingsRole        { params["settingsRole"]        = String(v) }
        if let v = user.streamRole          { params["streamRole"]          = String(v) }
        if let v = user.jukeboxRole         { params["jukeboxRole"]         = String(v) }
        if let v = user.downloadRole        { params["downloadRole"]        = String(v) }
        if let v = user.uploadRole          { params["uploadRole"]          = String(v) }
        if let v = user.playlistRole        { params["playlistRole"]        = String(v) }
        if let v = user.coverArtRole        { params["coverArtRole"]        = String(v) }
        if let v = user.commentRole         { params["commentRole"]         = String(v) }
        if let v = user.podcastRole         { params["podcastRole"]         = String(v) }
        if let v = user.shareRole           { params["shareRole"]           = String(v) }
        if let v = user.videoConversionRole { params["videoConversionRole"] = String(v) }

        var multi: [String: [String]] = [:]
        if let ids = user.musicFolderIds { multi["musicFolderId"] = ids }

        try await performVoid(endpoint: "createUser", params: params, multiParams: multi)
    }

    // MARK: updateUser

    /// Updates an existing user account.
    ///
    /// Only the fields set on the ``UserUpdate`` are sent in the request.
    ///
    /// - Parameter update: A ``UserUpdate`` with the fields to change.
    public func updateUser(_ update: UserUpdate) async throws {
        var params: [String: String] = ["username": update.username]
        if let v = update.password             { params["password"]            = hexEncodePassword(v) }
        if let v = update.email                { params["email"]               = v }
        if let v = update.ldapAuthenticated    { params["ldapAuthenticated"]   = String(v) }
        if let v = update.adminRole            { params["adminRole"]           = String(v) }
        if let v = update.settingsRole         { params["settingsRole"]        = String(v) }
        if let v = update.streamRole           { params["streamRole"]          = String(v) }
        if let v = update.jukeboxRole          { params["jukeboxRole"]         = String(v) }
        if let v = update.downloadRole         { params["downloadRole"]        = String(v) }
        if let v = update.uploadRole           { params["uploadRole"]          = String(v) }
        if let v = update.playlistRole         { params["playlistRole"]        = String(v) }
        if let v = update.coverArtRole         { params["coverArtRole"]        = String(v) }
        if let v = update.commentRole          { params["commentRole"]         = String(v) }
        if let v = update.podcastRole          { params["podcastRole"]         = String(v) }
        if let v = update.shareRole            { params["shareRole"]           = String(v) }
        if let v = update.videoConversionRole  { params["videoConversionRole"] = String(v) }

        var multi: [String: [String]] = [:]
        if let ids = update.musicFolderIds { multi["musicFolderId"] = ids }

        try await performVoid(endpoint: "updateUser", params: params, multiParams: multi)
    }

    // MARK: deleteUser

    /// Deletes an existing user account.
    ///
    /// - Parameter username: The username of the account to delete.
    public func deleteUser(username: String) async throws {
        try await performVoid(endpoint: "deleteUser", params: ["username": username])
    }

    // MARK: changePassword

    /// Changes the password for a user account.
    ///
    /// The password is transmitted as a hex-encoded value with an `enc:` prefix;
    /// SwiftSonic handles this encoding automatically.
    ///
    /// - Parameters:
    ///   - username: The account whose password to change.
    ///   - newPassword: The new plain-text password.
    public func changePassword(username: String, newPassword: String) async throws {
        try await performVoid(endpoint: "changePassword", params: [
            "username": username,
            "password": hexEncodePassword(newPassword),
        ])
    }
}

// MARK: - Response payloads (internal)

struct UserPayload: SubsonicPayload {
    static let payloadKey = "user"
    let user: User
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        user = try container.decode(User.self)
    }
}

struct UsersContainer: Decodable, Sendable {
    let user: [User]?
}

struct UsersPayload: SubsonicPayload {
    static let payloadKey = "users"
    let users: UsersContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        users = try container.decode(UsersContainer.self)
    }
}

// MARK: - Private helpers

/// Returns the password in Subsonic hex-encoded wire format: `enc:<hexBytes>`.
private func hexEncodePassword(_ password: String) -> String {
    let hex = password.utf8.map { String(format: "%02x", $0) }.joined()
    return "enc:\(hex)"
}
