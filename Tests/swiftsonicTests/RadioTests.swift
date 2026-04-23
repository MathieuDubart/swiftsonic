// RadioTests.swift — SwiftSonicTests
//
// Tests for internet radio station endpoints:
//   getInternetRadioStations, createInternetRadioStation,
//   updateInternetRadioStation, deleteInternetRadioStation
//
// Fixtures:
//   getInternetRadioStations.json       — manually constructed with two stations
//   getInternetRadioStations_empty.json — real Navidrome response (no stations)
//     Spec: https://opensubsonic.netlify.app/docs/endpoints/getinternetradiostations/

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - getInternetRadioStations

@Suite("getInternetRadioStations")
struct GetInternetRadioStationsTests {

    @Test("getInternetRadioStations decodes a station list")
    func decodesStations() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getInternetRadioStations")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let stations = try await client.getInternetRadioStations()

        #expect(stations.count == 2)

        let kcrw = try #require(stations.first(where: { $0.name == "KCRW" }))
        #expect(kcrw.id == "1")
        #expect(kcrw.streamUrl == "https://kcrw.streamguys1.com/kcrw_192k_mp3_on_air")
        #expect(kcrw.homePageUrl == "https://www.kcrw.com")
        #expect(kcrw.coverArt == "ar-1")

        let fip = try #require(stations.first(where: { $0.name == "FIP" }))
        #expect(fip.homePageUrl == nil)
        #expect(fip.coverArt == nil)
    }

    @Test("getInternetRadioStations returns empty array when server has none")
    func returnsEmptyArray() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getInternetRadioStations_empty")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        let stations = try await client.getInternetRadioStations()

        #expect(stations.isEmpty)
    }

    @Test("getInternetRadioStations sends the correct request path")
    func sendsCorrectPath() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "getInternetRadioStations")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        _ = try await client.getInternetRadioStations()

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/getInternetRadioStations.view") == true)
    }
}

// MARK: - createInternetRadioStation

@Suite("createInternetRadioStation")
struct CreateInternetRadioStationTests {

    @Test("createInternetRadioStation sends streamUrl, name, and optional homepageUrl")
    func sendsRequiredAndOptionalParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.createInternetRadioStation(
            streamURL: URL(string: "https://stream.example.com/live.mp3")!,
            name: "Test Radio",
            homepageURL: URL(string: "https://example.com")!
        )

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/createInternetRadioStation.view") == true)
        #expect(mock.queryItem(named: "streamUrl") == "https://stream.example.com/live.mp3")
        #expect(mock.queryItem(named: "name") == "Test Radio")
        #expect(mock.queryItem(named: "homepageUrl") == "https://example.com")
    }

    @Test("createInternetRadioStation omits homepageUrl when nil")
    func omitsOptionalHomepage() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.createInternetRadioStation(
            streamURL: URL(string: "https://stream.example.com/live.mp3")!,
            name: "Test Radio"
        )

        #expect(mock.queryItem(named: "homepageUrl") == nil)
    }
}

// MARK: - updateInternetRadioStation

@Suite("updateInternetRadioStation")
struct UpdateInternetRadioStationTests {

    @Test("updateInternetRadioStation sends id, streamUrl, and name")
    func sendsAllParams() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.updateInternetRadioStation(
            id: "42",
            streamURL: URL(string: "https://new.stream.example.com/live.mp3")!,
            name: "Updated Radio"
        )

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/updateInternetRadioStation.view") == true)
        #expect(mock.queryItem(named: "id") == "42")
        #expect(mock.queryItem(named: "streamUrl") == "https://new.stream.example.com/live.mp3")
        #expect(mock.queryItem(named: "name") == "Updated Radio")
    }
}

// MARK: - deleteInternetRadioStation

@Suite("deleteInternetRadioStation")
struct DeleteInternetRadioStationTests {

    @Test("deleteInternetRadioStation sends the station id")
    func sendsId() async throws {
        let mock = MockHTTPTransport()
        mock.enqueue(fixture: "ping_ok")

        let client = SwiftSonicClient(configuration: .test, transport: mock)
        try await client.deleteInternetRadioStation(id: "7")

        let req = try #require(mock.lastRequest)
        #expect(req.url?.path.hasSuffix("/rest/deleteInternetRadioStation.view") == true)
        #expect(mock.queryItem(named: "id") == "7")
    }
}
