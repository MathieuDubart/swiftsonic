// SwiftSonicClient+Radio.swift — SwiftSonic
//
// Internet radio station endpoints: get, create, update, delete.
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getinternetradiostations/
//
// Note: create/update/delete require admin privilege on the server.

import Foundation

// MARK: - Internet Radio endpoints

public extension SwiftSonicClient {

    /// Returns all internet radio stations configured on the server.
    ///
    /// ```swift
    /// let stations = try await client.getInternetRadioStations()
    /// for station in stations {
    ///     print("\(station.name) — \(station.streamUrl)")
    /// }
    /// ```
    ///
    /// - Returns: An array of ``InternetRadioStation`` objects, empty if none are configured.
    func getInternetRadioStations() async throws -> [InternetRadioStation] {
        let envelope: SubsonicEnvelope<RadioStationsPayload> =
            try await performDecode(endpoint: "getInternetRadioStations", params: [:])
        return envelope.payload?.stations.internetRadioStation ?? []
    }

    /// Adds a new internet radio station.
    ///
    /// - Parameters:
    ///   - streamURL: The audio stream URL.
    ///   - name: The display name for the station.
    ///   - homepageURL: Optional URL for the station's homepage.
    ///
    /// - Note: Requires admin privilege. Since Subsonic API v1.16.0.
    func createInternetRadioStation(
        streamURL: URL,
        name: String,
        homepageURL: URL? = nil
    ) async throws {
        var params: [String: String] = [
            "streamUrl": streamURL.absoluteString,
            "name": name,
        ]
        if let url = homepageURL { params["homepageUrl"] = url.absoluteString }
        try await performVoid(endpoint: "createInternetRadioStation", params: params)
    }

    /// Updates an existing internet radio station.
    ///
    /// - Parameters:
    ///   - id: The station identifier.
    ///   - streamURL: The new audio stream URL.
    ///   - name: The new display name.
    ///   - homepageURL: Optional new homepage URL.
    ///
    /// - Note: Requires admin privilege. Since Subsonic API v1.16.0.
    func updateInternetRadioStation(
        id: String,
        streamURL: URL,
        name: String,
        homepageURL: URL? = nil
    ) async throws {
        var params: [String: String] = [
            "id": id,
            "streamUrl": streamURL.absoluteString,
            "name": name,
        ]
        if let url = homepageURL { params["homepageUrl"] = url.absoluteString }
        try await performVoid(endpoint: "updateInternetRadioStation", params: params)
    }

    /// Deletes an internet radio station.
    ///
    /// - Parameter id: The station identifier.
    ///
    /// - Note: Requires admin privilege. Since Subsonic API v1.16.0.
    func deleteInternetRadioStation(id: String) async throws {
        try await performVoid(endpoint: "deleteInternetRadioStation", params: ["id": id])
    }
}

// MARK: - Response payloads (internal)

struct RadioStationsContainer: Decodable, Sendable {
    // Absent when the server returns an empty object `{}` instead of an array
    let internetRadioStation: [InternetRadioStation]?
}

struct RadioStationsPayload: SubsonicPayload {
    static let payloadKey = "internetRadioStations"
    let stations: RadioStationsContainer
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        stations = try container.decode(RadioStationsContainer.self)
    }
}
