// SwiftSonicClient+System.swift — SwiftSonic
//
// System endpoints: ping, getLicense, getOpenSubsonicExtensions.
//
// These are the lowest-level endpoints — no domain data, just server health
// and capability information. They are also the building blocks of fetchCapabilities().

import Foundation

// MARK: - System endpoints

extension SwiftSonicClient {

    // MARK: ping

    /// Checks connectivity to the server and validates credentials.
    ///
    /// A successful call returns without throwing. Use this to verify that the
    /// server is reachable and the credentials in ``configuration`` are correct.
    ///
    /// ```swift
    /// try await client.ping()
    /// print("Server is reachable")
    /// ```
    public func ping() async throws {
        try await performVoid(endpoint: "ping")
    }

    // MARK: getLicense

    /// Returns the server's license information.
    ///
    /// ```swift
    /// let license = try await client.getLicense()
    /// print(license.valid ? "Licensed" : "Trial")
    /// ```
    public func getLicense() async throws -> License {
        let envelope: SubsonicEnvelope<LicensePayload> =
            try await performDecode(endpoint: "getLicense", params: [:])
        guard let license = envelope.payload?.license else {
            throw SwiftSonicError.decoding(
                DecodingError.valueNotFound(
                    License.self,
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Missing 'license' in getLicense response"
                    )
                ),
                rawData: Data()
            )
        }
        return license
    }

    // MARK: getOpenSubsonicExtensions

    /// Returns the OpenSubsonic extensions supported by the server.
    ///
    /// This endpoint requires no authentication and is safe to call before
    /// establishing a session. Consider using ``fetchCapabilities()`` instead,
    /// which calls both `ping` and this endpoint and caches the result.
    ///
    /// ```swift
    /// let extensions = try await client.getOpenSubsonicExtensions()
    /// for ext in extensions {
    ///     print("\(ext.name): versions \(ext.versions)")
    /// }
    /// ```
    public func getOpenSubsonicExtensions() async throws -> [OpenSubsonicExtension] {
        let envelope: SubsonicEnvelope<OpenSubsonicExtensionsPayload> =
            try await performDecode(endpoint: "getOpenSubsonicExtensions", params: [:])
        return envelope.payload?.openSubsonicExtensions ?? []
    }
}

// MARK: - Response payloads (internal)

struct LicensePayload: SubsonicPayload {
    static let payloadKey = "license"
    let license: License
}

/// A single OpenSubsonic extension entry.
public struct OpenSubsonicExtension: Codable, Sendable {
    /// The extension name (e.g. `"songLyrics"`, `"apiKeyAuthentication"`).
    public let name: String

    /// The versions of this extension the server supports (e.g. `[1, 2]`).
    public let versions: [Int]
}

struct OpenSubsonicExtensionsPayload: SubsonicPayload {
    static let payloadKey = "openSubsonicExtensions"
    let openSubsonicExtensions: [OpenSubsonicExtension]
}
