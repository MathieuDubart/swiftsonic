// InternetRadioStation.swift — SwiftSonic
//
// Model for an internet radio station.
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getinternetradiostations/

import Foundation

/// An internet radio station configured on the server.
public struct InternetRadioStation: Codable, Sendable {

    /// The server-assigned station identifier.
    public let id: String

    /// The display name of the station.
    public let name: String

    /// The audio stream URL.
    public let streamUrl: String

    /// The station's homepage URL.
    public let homePageUrl: String?

    /// Cover art identifier (OpenSubsonic servers only).
    public let coverArt: String?
}
