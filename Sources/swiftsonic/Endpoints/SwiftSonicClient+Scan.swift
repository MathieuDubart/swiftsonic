// SwiftSonicClient+Scan.swift — SwiftSonic
//
// Library scan control endpoints: getScanStatus, startScan.
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getscanstatus/
//       https://opensubsonic.netlify.app/docs/endpoints/startscan/

import Foundation

// MARK: - Scan endpoints

public extension SwiftSonicClient {

    /// Returns the current library scan status.
    ///
    /// Poll this method to monitor an in-progress scan.
    ///
    /// ```swift
    /// let status = try await client.getScanStatus()
    /// if status.scanning {
    ///     print("Scanning… \(status.count ?? 0) files found so far")
    /// } else {
    ///     print("Last scan: \(status.count ?? 0) files")
    /// }
    /// ```
    ///
    /// - Returns: A ``ScanStatus`` describing the current or most recent scan.
    func getScanStatus() async throws -> ScanStatus {
        let envelope: SubsonicEnvelope<ScanStatusPayload> =
            try await performDecode(endpoint: "getScanStatus", params: [:])
        return try unwrapRequired(envelope.payload?.scanStatus, endpoint: "getScanStatus")
    }

    /// Initiates a library scan and returns the initial scan status.
    ///
    /// The server scans asynchronously; poll ``getScanStatus()`` to monitor progress.
    ///
    /// ```swift
    /// _ = try await client.startScan()
    /// repeat {
    ///     try await Task.sleep(for: .seconds(2))
    ///     let status = try await client.getScanStatus()
    ///     guard status.scanning else { break }
    /// } while true
    /// ```
    ///
    /// - Note: Requires admin or scan privilege on the server.
    /// - Returns: A ``ScanStatus`` with `scanning` set to `true`.
    func startScan() async throws -> ScanStatus {
        let envelope: SubsonicEnvelope<ScanStatusPayload> =
            try await performDecode(endpoint: "startScan", params: [:])
        return try unwrapRequired(envelope.payload?.scanStatus, endpoint: "startScan")
    }
}

// MARK: - Response payload (internal)

struct ScanStatusPayload: SubsonicPayload {
    static let payloadKey = "scanStatus"
    let scanStatus: ScanStatus
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        scanStatus = try container.decode(ScanStatus.self)
    }
}
