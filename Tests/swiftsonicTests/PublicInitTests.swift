// PublicInitTests.swift — SwiftSonicTests
//
// Verifies that core models expose a public initializer usable from
// outside the module (the test target acts as an external consumer).

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - AlbumID3

@Suite("AlbumID3 publicInit")
struct AlbumID3PublicInitTests {

    @Test("constructs AlbumID3 with required fields and nil defaults")
    func constructsWithDefaults() {
        let a = AlbumID3(id: "10", name: "A Night at the Opera", songCount: 12, duration: 2640)
        #expect(a.id == "10")
        #expect(a.name == "A Night at the Opera")
        #expect(a.songCount == 12)
        #expect(a.duration == 2640)
        #expect(a.artist == nil)
        #expect(a.artistId == nil)
        #expect(a.coverArt == nil)
        #expect(a.starred == nil)
        #expect(a.year == nil)
        #expect(a.song == nil)
    }

    @Test("constructs AlbumID3 with all optional fields")
    func constructsWithAllFields() {
        let now = Date()
        let a = AlbumID3(
            id: "11", name: "OK Computer", songCount: 12, duration: 3120,
            artist: "Radiohead", artistId: "2",
            coverArt: "art-11", playCount: 99,
            created: now, starred: now,
            year: 1997, genre: "Alternative",
            userRating: 5, isCompilation: false
        )
        #expect(a.artist == "Radiohead")
        #expect(a.artistId == "2")
        #expect(a.year == 1997)
        #expect(a.genre == "Alternative")
        #expect(a.userRating == 5)
        #expect(a.isCompilation == false)
    }
}

// MARK: - ArtistIndex

@Suite("ArtistIndex publicInit")
struct ArtistIndexPublicInitTests {

    @Test("constructs ArtistIndex with default empty artist array")
    func constructsWithDefaults() {
        let idx = ArtistIndex(name: "Q")
        #expect(idx.name == "Q")
        #expect(idx.artist.isEmpty)
    }

    @Test("constructs ArtistIndex with artists")
    func constructsWithArtists() {
        let a = ArtistID3(id: "1", name: "Queen")
        let idx = ArtistIndex(name: "Q", artist: [a])
        #expect(idx.artist.count == 1)
        #expect(idx.artist[0].id == "1")
    }
}

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
