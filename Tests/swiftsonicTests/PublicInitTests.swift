// PublicInitTests.swift — SwiftSonicTests
//
// Verifies that core models expose a public initializer usable from
// outside the module (the test target acts as an external consumer).

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - ArtistID3

@Suite("ArtistID3 publicInit")
struct ArtistID3PublicInitTests {

    @Test("constructs ArtistID3 with required fields and nil defaults")
    func constructsWithDefaults() {
        let a = ArtistID3(id: "1", name: "Queen")
        #expect(a.id == "1")
        #expect(a.name == "Queen")
        #expect(a.albumCount == nil)
        #expect(a.coverArt == nil)
        #expect(a.starred == nil)
        #expect(a.userRating == nil)
        #expect(a.musicBrainzId == nil)
        #expect(a.sortName == nil)
        #expect(a.roles == nil)
        #expect(a.album == nil)
    }

    @Test("constructs ArtistID3 with all fields")
    func constructsWithAllFields() {
        let now = Date()
        let a = ArtistID3(
            id: "2", name: "Radiohead",
            albumCount: 10, coverArt: "art-2",
            starred: now, userRating: 5,
            musicBrainzId: "mb-2", sortName: "Radiohead",
            roles: ["composer"], album: []
        )
        #expect(a.albumCount == 10)
        #expect(a.coverArt == "art-2")
        #expect(a.starred == now)
        #expect(a.userRating == 5)
        #expect(a.musicBrainzId == "mb-2")
        #expect(a.roles == ["composer"])
        #expect(a.album?.isEmpty == true)
    }
}
