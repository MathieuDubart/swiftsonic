// License.swift — SwiftSonic
//
// Data model for the server license, returned by getLicense.

import Foundation

/// The server license details returned by ``SwiftSonicClient/getLicense()``.
public struct License: Codable, Sendable {
    /// `true` if the server has a valid license.
    public let valid: Bool

    /// The email address associated with the license.
    public let email: String?

    /// The license expiry date, if applicable.
    public let licenseExpires: Date?

    /// The date the trial period ends, if the server is in trial mode.
    public let trialExpires: Date?
}
