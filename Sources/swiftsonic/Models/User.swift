// User.swift — SwiftSonic
//
// Data models for user management: User (read), NewUser (create), UserUpdate (update).

import Foundation

// MARK: - User

/// A Subsonic server user account.
///
/// Returned by ``SwiftSonicClient/getUser(username:)`` and ``SwiftSonicClient/getUsers()``.
public struct User: Decodable, Sendable {

    // MARK: Identity

    /// The account username.
    public let username: String

    /// The user's email address.
    public let email: String?

    // MARK: Preferences

    /// Whether Last.fm scrobbling is enabled for this user.
    public let scrobblingEnabled: Bool?

    /// The maximum bitrate (in kbps) the server will stream to this user.
    public let maxBitRate: Int?

    // MARK: Roles

    /// The user has administrator access.
    public let adminRole: Bool

    /// The user can change server settings.
    public let settingsRole: Bool

    /// The user can download media files.
    public let downloadRole: Bool

    /// The user can upload media files.
    public let uploadRole: Bool

    /// The user can create and manage playlists.
    public let playlistRole: Bool

    /// The user can change cover art.
    public let coverArtRole: Bool

    /// The user can create and edit comments.
    public let commentRole: Bool

    /// The user can administrate podcasts.
    public let podcastRole: Bool

    /// The user can stream media.
    public let streamRole: Bool

    /// The user can control the jukebox.
    public let jukeboxRole: Bool

    /// The user can create and manage shares.
    public let shareRole: Bool

    /// The user can transcode video.
    public let videoConversionRole: Bool

    /// The IDs of the music folders this user has access to.
    public let folder: [Int]?

    // MARK: Decoding

    private enum CodingKeys: String, CodingKey {
        case username, email, scrobblingEnabled, maxBitRate
        case adminRole, settingsRole, downloadRole, uploadRole
        case playlistRole, coverArtRole, commentRole, podcastRole
        case streamRole, jukeboxRole, shareRole, videoConversionRole
        case folder
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        username             = try  c.decode(String.self,  forKey: .username)
        email                = try? c.decode(String.self,  forKey: .email)
        scrobblingEnabled    = try? c.decode(Bool.self,    forKey: .scrobblingEnabled)
        maxBitRate           = try? c.decode(Int.self,     forKey: .maxBitRate)
        adminRole            = (try? c.decode(Bool.self,   forKey: .adminRole))            ?? false
        settingsRole         = (try? c.decode(Bool.self,   forKey: .settingsRole))         ?? false
        downloadRole         = (try? c.decode(Bool.self,   forKey: .downloadRole))         ?? false
        uploadRole           = (try? c.decode(Bool.self,   forKey: .uploadRole))           ?? false
        playlistRole         = (try? c.decode(Bool.self,   forKey: .playlistRole))         ?? false
        coverArtRole         = (try? c.decode(Bool.self,   forKey: .coverArtRole))         ?? false
        commentRole          = (try? c.decode(Bool.self,   forKey: .commentRole))          ?? false
        podcastRole          = (try? c.decode(Bool.self,   forKey: .podcastRole))          ?? false
        streamRole           = (try? c.decode(Bool.self,   forKey: .streamRole))           ?? false
        jukeboxRole          = (try? c.decode(Bool.self,   forKey: .jukeboxRole))          ?? false
        shareRole            = (try? c.decode(Bool.self,   forKey: .shareRole))            ?? false
        videoConversionRole  = (try? c.decode(Bool.self,   forKey: .videoConversionRole))  ?? false
        folder               = try? c.decode([Int].self,   forKey: .folder)
    }
}

// MARK: - NewUser

/// The parameters needed to create a new user account.
///
/// Pass to ``SwiftSonicClient/createUser(_:)``. Only ``username``, ``password``, and
/// ``email`` are required; all role flags default to `false` unless explicitly set.
///
/// The ``password`` is always transferred as a hex-encoded value with an `enc:` prefix —
/// SwiftSonic handles this automatically.
public struct NewUser: Sendable {

    // MARK: Required

    /// The new account username.
    public let username: String

    /// The plain-text password. SwiftSonic hex-encodes it on the wire.
    public let password: String

    /// The user's email address.
    public let email: String

    // MARK: Optional settings

    /// Whether the account should use LDAP authentication.
    public var ldapAuthenticated: Bool?

    // MARK: Role flags

    public var adminRole:           Bool?
    public var settingsRole:        Bool?
    public var streamRole:          Bool?
    public var jukeboxRole:         Bool?
    public var downloadRole:        Bool?
    public var uploadRole:          Bool?
    public var playlistRole:        Bool?
    public var coverArtRole:        Bool?
    public var commentRole:         Bool?
    public var podcastRole:         Bool?
    public var shareRole:           Bool?
    public var videoConversionRole: Bool?

    /// The IDs of the music folders to grant access to.
    public var musicFolderIds: [String]?

    public init(username: String, password: String, email: String) {
        self.username = username
        self.password = password
        self.email    = email
    }
}

// MARK: - UserUpdate

/// The parameters for updating an existing user account.
///
/// Pass to ``SwiftSonicClient/updateUser(_:)``. Only ``username`` (to identify the
/// account) is required. All other fields are optional — only the fields you set
/// will be included in the request.
///
/// The ``password`` is always transferred as a hex-encoded value with an `enc:` prefix —
/// SwiftSonic handles this automatically.
public struct UserUpdate: Sendable {

    /// The username of the account to update.
    public let username: String

    /// A new plain-text password. SwiftSonic hex-encodes it on the wire.
    public var password: String?

    /// A new email address.
    public var email: String?

    public var ldapAuthenticated:   Bool?
    public var adminRole:           Bool?
    public var settingsRole:        Bool?
    public var streamRole:          Bool?
    public var jukeboxRole:         Bool?
    public var downloadRole:        Bool?
    public var uploadRole:          Bool?
    public var playlistRole:        Bool?
    public var coverArtRole:        Bool?
    public var commentRole:         Bool?
    public var podcastRole:         Bool?
    public var shareRole:           Bool?
    public var videoConversionRole: Bool?

    /// The IDs of the music folders to grant access to.
    public var musicFolderIds: [String]?

    public init(username: String) {
        self.username = username
    }
}
