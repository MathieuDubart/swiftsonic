// ServerConfiguration.swift — SwiftSonic
//
// Holds all the static parameters needed to connect to a Subsonic/OpenSubsonic server:
// the server URL, authentication method, client name, and API version.
//
// ServerConfiguration is a value type (struct) and fully Sendable.
// Construct once and pass to SwiftSonicClient.

import Foundation

// MARK: - Authentication method

/// Describes how the client authenticates with the server.
///
/// Use ``tokenAuth(username:password:reusesSalt:)`` for standard Subsonic servers.
/// Use ``apiKey(_:)`` for OpenSubsonic servers that support the `apiKeyAuthentication` extension.
public enum AuthMethod: Sendable {
    /// Salted-token authentication as defined by the Subsonic spec.
    ///
    /// The token is computed as `MD5(password + salt)` and sent alongside the salt.
    /// The password is **never** transmitted in plaintext.
    ///
    /// - Parameters:
    ///   - username: The account username.
    ///   - password: The account password (used locally for token computation only).
    ///   - reusesSalt: When `false` (default), a fresh random salt is generated for every
    ///     request. Set to `true` to reuse a salt computed once at client initialization.
    case tokenAuth(username: String, password: String, reusesSalt: Bool)

    /// API key authentication (OpenSubsonic `apiKeyAuthentication` extension).
    ///
    /// Sends a single `apiKey` parameter instead of `u`/`t`/`s`.
    /// Requires the server to support the `apiKeyAuthentication` OpenSubsonic extension.
    case apiKey(String)
}

// MARK: - AuthMethod safe string representations

/// Prevents credentials from appearing in logs, debugger output, or crash reports.
///
/// Both `CustomStringConvertible` and `CustomDebugStringConvertible` are implemented
/// so that `String(describing:)`, `print()`, `debugPrint()`, and the Xcode debugger
/// Variables panel all produce redacted output.
extension AuthMethod: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case .tokenAuth(let username, _, _):
            return "tokenAuth(username: \"\(username)\", password: \"***\")"
        case .apiKey:
            return "apiKey(\"***\")"
        }
    }

    public var debugDescription: String { description }
}

// MARK: - Server configuration

/// All static parameters required to communicate with a Subsonic/OpenSubsonic server.
///
/// ```swift
/// // Standard token auth
/// let config = ServerConfiguration(
///     serverURL: URL(string: "https://music.example.com")!,
///     username: "alice",
///     password: "secret"
/// )
///
/// // API key auth (OpenSubsonic)
/// let config = ServerConfiguration(
///     serverURL: URL(string: "https://music.example.com")!,
///     auth: .apiKey("my-api-key")
/// )
/// ```
public struct ServerConfiguration: Sendable {
    /// The base URL of the Subsonic server (e.g. `https://music.example.com`).
    ///
    /// Do not include a trailing slash or any path component.
    public let serverURL: URL

    /// The authentication method to use for every request.
    public let auth: AuthMethod

    /// The client name sent in the `c` parameter of every request.
    ///
    /// Defaults to `"SwiftSonic"`. Override to identify your application.
    public let clientName: String

    /// The Subsonic API version to declare in the `v` parameter.
    ///
    /// Defaults to `"1.16.1"`, the current OpenSubsonic-compatible version.
    public let apiVersion: String

    /// Maximum time to wait for the server to return a response, in seconds.
    ///
    /// Applied as `URLRequest.timeoutInterval` on every request.
    /// Custom ``HTTPTransport`` implementations should honour this value.
    /// Defaults to `30` seconds.
    public let requestTimeout: TimeInterval

    /// Maximum time for an entire resource download to complete, in seconds.
    ///
    /// Applied via `URLSessionConfiguration.timeoutIntervalForResource` when using
    /// the default ``URLSessionTransport``. Custom transports handle this independently.
    /// Defaults to `60` seconds.
    public let resourceTimeout: TimeInterval

    // MARK: Full initializer

    /// Creates a configuration with explicit control over all parameters.
    ///
    /// - Parameters:
    ///   - serverURL: The base URL of the Subsonic server.
    ///   - auth: The authentication method.
    ///   - clientName: Identifier sent as `c` in every request. Defaults to `"SwiftSonic"`.
    ///   - apiVersion: Subsonic API version string. Defaults to `"1.16.1"`.
    ///   - requestTimeout: Per-request timeout in seconds. Defaults to `30`.
    ///   - resourceTimeout: Overall resource timeout in seconds. Defaults to `60`.
    public init(
        serverURL: URL,
        auth: AuthMethod,
        clientName: String = "SwiftSonic",
        apiVersion: String = "1.16.1",
        requestTimeout: TimeInterval = 30,
        resourceTimeout: TimeInterval = 60
    ) {
        self.serverURL       = serverURL
        self.auth            = auth
        self.clientName      = clientName
        self.apiVersion      = apiVersion
        self.requestTimeout  = requestTimeout
        self.resourceTimeout = resourceTimeout
    }

    // MARK: Convenience initializer (token auth)

    /// Creates a configuration using standard salted-token authentication.
    ///
    /// This is the most common initializer for standard Subsonic servers.
    ///
    /// - Parameters:
    ///   - serverURL: The base URL of the Subsonic server.
    ///   - username: The account username.
    ///   - password: The account password (used locally; never sent over the network).
    ///   - reusesSalt: When `false` (default), a fresh salt is generated per request.
    ///   - clientName: Identifier sent as `c` in every request. Defaults to `"SwiftSonic"`.
    ///   - apiVersion: Subsonic API version string. Defaults to `"1.16.1"`.
    ///   - requestTimeout: Per-request timeout in seconds. Defaults to `30`.
    ///   - resourceTimeout: Overall resource timeout in seconds. Defaults to `60`.
    public init(
        serverURL: URL,
        username: String,
        password: String,
        reusesSalt: Bool = false,
        clientName: String = "SwiftSonic",
        apiVersion: String = "1.16.1",
        requestTimeout: TimeInterval = 30,
        resourceTimeout: TimeInterval = 60
    ) {
        self.init(
            serverURL: serverURL,
            auth: .tokenAuth(username: username, password: password, reusesSalt: reusesSalt),
            clientName: clientName,
            apiVersion: apiVersion,
            requestTimeout: requestTimeout,
            resourceTimeout: resourceTimeout
        )
    }
}

// MARK: - ServerConfiguration safe string representations

/// Prevents the auth credentials from appearing in logs, debugger output, or crash reports.
extension ServerConfiguration: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        "ServerConfiguration(serverURL: \(serverURL), auth: \(auth))"
    }

    public var debugDescription: String { description }
}
