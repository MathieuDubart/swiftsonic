// SwiftSonicError.swift — SwiftSonic
//
// Defines the complete error hierarchy for the SwiftSonic library.
// All errors are Sendable and can be safely propagated across concurrency boundaries.
//
// Top-level: SwiftSonicError (the type callers catch)
// Nested:    SubsonicAPIError (server-reported error with typed code)
//            SubsonicErrorCode (exhaustive enum of Subsonic error codes)

import Foundation

// MARK: - Top-level error

/// The error type thrown by all `SwiftSonicClient` methods.
///
/// Use a `switch` statement to handle each case:
/// ```swift
/// do {
///     let artists = try await client.getArtists()
/// } catch let error as SwiftSonicError {
///     switch error {
///     case .api(let apiError) where apiError.code == .wrongCredentials:
///         // prompt re-authentication
///     case .network(let urlError):
///         // show connectivity error
///     default:
///         break
///     }
/// }
/// ```
public enum SwiftSonicError: Error, Sendable {
    /// The server responded with `status: "failed"` and a typed error code.
    case api(SubsonicAPIError)

    /// A network-level error occurred before a response was received.
    case network(URLError)

    /// The server returned a 2xx response but the JSON could not be decoded.
    /// The raw `Data` is included to aid debugging.
    case decoding(DecodingError, rawData: Data)

    /// The server returned a non-2xx HTTP status code.
    case httpError(statusCode: Int, requestURL: URL)

    /// A client-side configuration problem prevented building the request.
    case invalidConfiguration(String)
}

// MARK: - API error detail

/// Carries the structured error information returned by a Subsonic/OpenSubsonic server
/// when `status` is `"failed"`.
public struct SubsonicAPIError: Error, Sendable {
    /// The machine-readable error code.
    public let code: SubsonicErrorCode

    /// The human-readable message provided by the server.
    public let message: String

    /// An optional URL to documentation for this error (OpenSubsonic servers only).
    public let helpURL: URL?

    /// The full URL of the request that triggered this error.
    public let requestURL: URL
}

// MARK: - Subsonic error codes

/// Exhaustive enumeration of the error codes defined by the Subsonic and OpenSubsonic specs.
///
/// Unknown codes (from future server versions) are represented as ``unknown``.
public enum SubsonicErrorCode: Int, Sendable, Codable, Equatable {
    /// A generic, unspecified server error.
    case generic = 0
    /// A required parameter was missing from the request.
    case missingParameter = 10
    /// The client needs to upgrade its protocol version.
    case clientMustUpgrade = 20
    /// The server needs to upgrade to support the requested feature.
    case serverMustUpgrade = 30
    /// Wrong username or password.
    case wrongCredentials = 40
    /// Token authentication is not supported for LDAP users.
    case tokenAuthNotSupportedForLDAP = 41
    /// The requested authentication mechanism is not supported by this server.
    case authMechanismNotSupported = 42
    /// Multiple conflicting authentication mechanisms were provided.
    case conflictingAuthMechanisms = 43
    /// The provided API key is invalid.
    case invalidAPIKey = 44
    /// The authenticated user is not authorized for this operation.
    case unauthorized = 50
    /// The Subsonic server's trial period has expired.
    case trialExpired = 60
    /// The requested data was not found.
    case notFound = 70
    /// An unrecognized error code returned by the server.
    case unknown = -1

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(Int.self)
        self = SubsonicErrorCode(rawValue: raw) ?? .unknown
    }
}
