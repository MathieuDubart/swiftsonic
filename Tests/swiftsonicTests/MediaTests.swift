// MediaTests.swift — SwiftSonicTests
//
// Tests for media URL helper methods: streamURL, downloadURL, coverArtURL, hlsURL, avatarURL.
// These are nonisolated and synchronous — no network call is made.

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - streamURL

@Suite("streamURL")
struct StreamURLTests {

    @Test("streamURL returns URL with id param")
    func returnsURLWithId() async {
        let client = SwiftSonicClient(configuration: .test)
        let url = client.streamURL(id: "101")

        #expect(url != nil)
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let query = components?.queryItems
        #expect(query?.first(where: { $0.name == "id" })?.value == "101")
        #expect(url?.path.hasSuffix("/rest/stream.view") == true)
    }

    @Test("streamURL includes optional params when provided")
    func includesOptionalParams() async {
        let client = SwiftSonicClient(configuration: .test)
        let url = client.streamURL(id: "101", maxBitRate: 320, format: "mp3", timeOffset: 30)

        #expect(url != nil)
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let query = components?.queryItems
        #expect(query?.first(where: { $0.name == "maxBitRate" })?.value == "320")
        #expect(query?.first(where: { $0.name == "format" })?.value == "mp3")
        #expect(query?.first(where: { $0.name == "timeOffset" })?.value == "30")
    }

    @Test("streamURL includes auth params")
    func includesAuthParams() async {
        let client = SwiftSonicClient(configuration: .test)
        let url = client.streamURL(id: "101")

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let query = components?.queryItems
        #expect(query?.first(where: { $0.name == "u" })?.value == "testuser")
        #expect(query?.first(where: { $0.name == "t" }) != nil)
        #expect(query?.first(where: { $0.name == "s" }) != nil)
    }
}

// MARK: - downloadURL

@Suite("downloadURL")
struct DownloadURLTests {

    @Test("downloadURL returns URL with id param")
    func returnsURLWithId() async {
        let client = SwiftSonicClient(configuration: .test)
        let url = client.downloadURL(id: "101")

        #expect(url != nil)
        #expect(url?.path.hasSuffix("/rest/download.view") == true)
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.first(where: { $0.name == "id" })?.value == "101")
    }
}

// MARK: - coverArtURL

@Suite("coverArtURL")
struct CoverArtURLTests {

    @Test("coverArtURL returns URL with id param")
    func returnsURLWithId() async {
        let client = SwiftSonicClient(configuration: .test)
        let url = client.coverArtURL(id: "al-10")

        #expect(url != nil)
        #expect(url?.path.hasSuffix("/rest/getCoverArt.view") == true)
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.first(where: { $0.name == "id" })?.value == "al-10")
    }

    @Test("coverArtURL includes size param when provided")
    func includesSizeParam() async {
        let client = SwiftSonicClient(configuration: .test)
        let url = client.coverArtURL(id: "al-10", size: 300)

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.first(where: { $0.name == "size" })?.value == "300")
    }

    @Test("coverArtURL omits size param when not provided")
    func omitsSizeByDefault() async {
        let client = SwiftSonicClient(configuration: .test)
        let url = client.coverArtURL(id: "al-10")

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.first(where: { $0.name == "size" }) == nil)
    }
}

// MARK: - hlsURL

@Suite("hlsURL")
struct HLSURLTests {

    @Test("hlsURL returns URL with id param")
    func returnsURLWithId() async {
        let client = SwiftSonicClient(configuration: .test)
        let url = client.hlsURL(id: "101")

        #expect(url != nil)
        #expect(url?.path.hasSuffix("/rest/hls.view") == true)
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.first(where: { $0.name == "id" })?.value == "101")
    }

    @Test("hlsURL includes optional params when provided")
    func includesOptionalParams() async {
        let client = SwiftSonicClient(configuration: .test)
        let url = client.hlsURL(id: "101", audioBitRate: 128, audioTrack: "2")

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let query = components?.queryItems
        #expect(query?.first(where: { $0.name == "audioBitRate" })?.value == "128")
        #expect(query?.first(where: { $0.name == "audioTrack" })?.value == "2")
    }
}

// MARK: - avatarURL

@Suite("avatarURL")
struct AvatarURLTests {

    @Test("avatarURL returns URL with username param")
    func returnsURLWithUsername() async {
        let client = SwiftSonicClient(configuration: .test)
        let url = client.avatarURL(username: "alice")

        #expect(url != nil)
        #expect(url?.path.hasSuffix("/rest/getAvatar.view") == true)
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.first(where: { $0.name == "username" })?.value == "alice")
    }

    @Test("avatarURL includes auth params")
    func includesAuthParams() async {
        let client = SwiftSonicClient(configuration: .test)
        let url = client.avatarURL(username: "alice")

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let query = components?.queryItems
        #expect(query?.first(where: { $0.name == "u" })?.value == "testuser")
        #expect(query?.first(where: { $0.name == "t" }) != nil)
        #expect(query?.first(where: { $0.name == "s" }) != nil)
    }
}
