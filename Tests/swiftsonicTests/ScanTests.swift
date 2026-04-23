// ScanTests.swift — SwiftSonicTests
//
// Tests for scan control endpoints: getScanStatus, startScan.
//
// Fixtures:
//   getScanStatus.json         — real response from demo.navidrome.org (scanning=false)
//   getScanStatus_scanning.json — manually constructed (scanning=true)
//     Spec: https://opensubsonic.netlify.app/docs/endpoints/getscanstatus/

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getScanStatus

@Suite("getScanStatus")
struct GetScanStatusTests {

    @Test("getScanStatus decodes a completed scan (scanning=false)")
    func decodesCompletedScan() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getScanStatus")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let status = try await client.getScanStatus()

        #expect(status.scanning == false)
        #expect(status.count == 501)
        #expect(status.folderCount == 50)
        #expect(status.lastScan != nil)     // Navidrome fixture has nanosecond precision

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/getScanStatus.view") == true)
    }

    @Test("getScanStatus decodes an in-progress scan (scanning=true)")
    func decodesInProgressScan() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getScanStatus_scanning")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let status = try await client.getScanStatus()

        #expect(status.scanning == true)
        #expect(status.count == 123)
        #expect(status.folderCount == 10)
        #expect(status.lastScan == nil)
    }

    @Test("getScanStatus sends the correct request path")
    func sendsCorrectPath() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getScanStatus")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getScanStatus()

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/getScanStatus.view") == true)
        #expect(mock.queryItem(named: "f") == "json")
        #expect(mock.queryItem(named: "v") != nil)
    }
}

// MARK: - startScan

@Suite("startScan")
struct StartScanTests {

    @Test("startScan sends the correct request path and decodes the response")
    func sendsCorrectPathAndDecodes() async throws {
        let mock = MockHTTPTransport()
        // Server immediately returns scanning=true
        mock.enqueue(fixture: "getScanStatus_scanning")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let status = try await client.startScan()

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/startScan.view") == true)
        #expect(status.scanning == true)
    }
}
