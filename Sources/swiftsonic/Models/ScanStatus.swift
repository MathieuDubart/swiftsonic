// ScanStatus.swift — SwiftSonic
//
// Model for the library scan status returned by getScanStatus and startScan.
// Spec: https://opensubsonic.netlify.app/docs/endpoints/getscanstatus/

import Foundation

/// The current or most recent library scan status.
///
/// Returned by both ``SwiftSonicClient/getScanStatus()`` and
/// ``SwiftSonicClient/startScan()``.
public struct ScanStatus: Codable, Sendable {

    /// Whether a library scan is currently running.
    public let scanning: Bool

    /// Total number of media files counted so far (or in the last completed scan).
    ///
    /// May be `nil` before the server has ever scanned.
    public let count: Int?

    /// Total number of music folders included in the scan.
    ///
    /// Available on OpenSubsonic-compatible servers.
    public let folderCount: Int?

    /// The date and time of the last completed scan.
    ///
    /// Available on OpenSubsonic-compatible servers.
    public let lastScan: Date?

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case scanning, count, folderCount, lastScan
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        scanning    = try c.decode(Bool.self, forKey: .scanning)
        count       = try c.decodeIfPresent(Int.self, forKey: .count)
        folderCount = try c.decodeIfPresent(Int.self, forKey: .folderCount)

        // Decode lastScan via a lenient helper: some servers (e.g. Navidrome) emit
        // nanosecond precision (9 fractional digits) which standard ISO8601DateFormatter
        // may not handle. We fall back to truncating to milliseconds if needed.
        if let raw = try c.decodeIfPresent(String.self, forKey: .lastScan) {
            lastScan = ScanStatus.parseISO8601Date(raw)
        } else {
            lastScan = nil
        }
    }

    // MARK: - Private helpers

    private static func parseISO8601Date(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: string) { return date }

        // Fallback: truncate to 3 fractional digits (milliseconds) and retry.
        // e.g. "2026-04-16T01:58:42.961446802Z" → "2026-04-16T01:58:42.961Z"
        let trimmed = string.replacingOccurrences(
            of: #"(\.\d{3})\d+(Z|[+-]\d{2}:\d{2})$"#,
            with: "$1$2",
            options: .regularExpression
        )
        return formatter.date(from: trimmed)
    }
}
