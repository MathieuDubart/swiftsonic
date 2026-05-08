// HashableTests.swift — SwiftSonicTests
//
// Tests for Equatable and Hashable conformances.
// Identifiable models (ArtistID3, AlbumID3, Song, Playlist) key equality on `id`.
// Value models (Line, StructuredLyrics, LyricsList, OpenSubsonicExtension) use full structural equality.

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - Helpers

private func decodeArtist(id: String, name: String = "Artist") throws -> ArtistID3 {
    let json = "{\"id\":\"\(id)\",\"name\":\"\(name)\"}"
    return try JSONDecoder().decode(ArtistID3.self, from: Data(json.utf8))
}

private func decodeAlbum(id: String, name: String = "Album") throws -> AlbumID3 {
    let json = "{\"id\":\"\(id)\",\"name\":\"\(name)\",\"songCount\":0,\"duration\":0}"
    return try JSONDecoder().decode(AlbumID3.self, from: Data(json.utf8))
}

private func decodeSong(id: String, title: String = "Song") throws -> Song {
    let json = "{\"id\":\"\(id)\",\"title\":\"\(title)\"}"
    return try JSONDecoder().decode(Song.self, from: Data(json.utf8))
}

private func decodePlaylist(id: String, name: String = "Playlist") throws -> Playlist {
    let json = "{\"id\":\"\(id)\",\"name\":\"\(name)\",\"songCount\":0,\"duration\":0}"
    return try JSONDecoder().decode(Playlist.self, from: Data(json.utf8))
}

private func decodePlaylistWithSongs(id: String, name: String = "Playlist") throws -> PlaylistWithSongs {
    let json = "{\"id\":\"\(id)\",\"name\":\"\(name)\",\"songCount\":0,\"duration\":0}"
    return try JSONDecoder().decode(PlaylistWithSongs.self, from: Data(json.utf8))
}

// MARK: - ArtistID3

@Suite("ArtistID3 Hashable")
struct ArtistID3HashableTests {

    @Test("equality_basedOnId: same id, different name → equal")
    func equalityBasedOnId() throws {
        let a1 = try decodeArtist(id: "1", name: "Alpha")
        let a2 = try decodeArtist(id: "1", name: "Beta")
        #expect(a1 == a2)
    }

    @Test("hash_consistentForSameId: same id → same hashValue")
    func hashConsistentForSameId() throws {
        let a1 = try decodeArtist(id: "1", name: "Alpha")
        let a2 = try decodeArtist(id: "1", name: "Beta")
        #expect(a1.hashValue == a2.hashValue)
    }

    @Test("usable_inSet: deduplication by id")
    func usableInSet() throws {
        let a1 = try decodeArtist(id: "1")
        let a2 = try decodeArtist(id: "1")
        let a3 = try decodeArtist(id: "2")
        var set = Set<ArtistID3>()
        set.insert(a1)
        set.insert(a2)
        set.insert(a3)
        #expect(set.count == 2)
        #expect(set.contains(a1))
    }

    @Test("usable_asDictionaryKey: keyed by id")
    func usableAsDictionaryKey() throws {
        let a1 = try decodeArtist(id: "1", name: "Alpha")
        let a2 = try decodeArtist(id: "1", name: "Beta")
        var dict = [ArtistID3: String]()
        dict[a1] = "first"
        dict[a2] = "second"
        #expect(dict.count == 1)
        #expect(dict[a1] == "second")
    }
}

// MARK: - AlbumID3

@Suite("AlbumID3 Hashable")
struct AlbumID3HashableTests {

    @Test("equality_basedOnId: same id, different name → equal")
    func equalityBasedOnId() throws {
        let a1 = try decodeAlbum(id: "10", name: "Alpha")
        let a2 = try decodeAlbum(id: "10", name: "Beta")
        #expect(a1 == a2)
    }

    @Test("hash_consistentForSameId: same id → same hashValue")
    func hashConsistentForSameId() throws {
        let a1 = try decodeAlbum(id: "10", name: "Alpha")
        let a2 = try decodeAlbum(id: "10", name: "Beta")
        #expect(a1.hashValue == a2.hashValue)
    }

    @Test("usable_inSet: deduplication by id")
    func usableInSet() throws {
        let a1 = try decodeAlbum(id: "10")
        let a2 = try decodeAlbum(id: "10")
        let a3 = try decodeAlbum(id: "20")
        var set = Set<AlbumID3>()
        set.insert(a1)
        set.insert(a2)
        set.insert(a3)
        #expect(set.count == 2)
        #expect(set.contains(a1))
    }

    @Test("usable_asDictionaryKey: keyed by id")
    func usableAsDictionaryKey() throws {
        let a1 = try decodeAlbum(id: "10", name: "Alpha")
        let a2 = try decodeAlbum(id: "10", name: "Beta")
        var dict = [AlbumID3: Int]()
        dict[a1] = 1
        dict[a2] = 2
        #expect(dict.count == 1)
        #expect(dict[a1] == 2)
    }
}

// MARK: - Song

@Suite("Song Hashable")
struct SongHashableTests {

    @Test("equality_basedOnId: same id, different title → equal")
    func equalityBasedOnId() throws {
        let s1 = try decodeSong(id: "101", title: "Alpha")
        let s2 = try decodeSong(id: "101", title: "Beta")
        #expect(s1 == s2)
    }

    @Test("hash_consistentForSameId: same id → same hashValue")
    func hashConsistentForSameId() throws {
        let s1 = try decodeSong(id: "101", title: "Alpha")
        let s2 = try decodeSong(id: "101", title: "Beta")
        #expect(s1.hashValue == s2.hashValue)
    }

    @Test("usable_inSet: deduplication by id")
    func usableInSet() throws {
        let s1 = try decodeSong(id: "101")
        let s2 = try decodeSong(id: "101")
        let s3 = try decodeSong(id: "201")
        var set = Set<Song>()
        set.insert(s1)
        set.insert(s2)
        set.insert(s3)
        #expect(set.count == 2)
        #expect(set.contains(s1))
    }

    @Test("usable_asDictionaryKey: keyed by id")
    func usableAsDictionaryKey() throws {
        let s1 = try decodeSong(id: "101", title: "Alpha")
        let s2 = try decodeSong(id: "101", title: "Beta")
        var dict = [Song: String]()
        dict[s1] = "first"
        dict[s2] = "second"
        #expect(dict.count == 1)
        #expect(dict[s1] == "second")
    }
}

// MARK: - Playlist

@Suite("Playlist Hashable")
struct PlaylistHashableTests {

    @Test("equality_basedOnId: same id, different name → equal")
    func equalityBasedOnId() throws {
        let p1 = try decodePlaylist(id: "1", name: "Alpha")
        let p2 = try decodePlaylist(id: "1", name: "Beta")
        #expect(p1 == p2)
    }

    @Test("hash_consistentForSameId: same id → same hashValue")
    func hashConsistentForSameId() throws {
        let p1 = try decodePlaylist(id: "1", name: "Alpha")
        let p2 = try decodePlaylist(id: "1", name: "Beta")
        #expect(p1.hashValue == p2.hashValue)
    }

    @Test("usable_inSet: deduplication by id")
    func usableInSet() throws {
        let p1 = try decodePlaylist(id: "1")
        let p2 = try decodePlaylist(id: "1")
        let p3 = try decodePlaylist(id: "2")
        var set = Set<Playlist>()
        set.insert(p1)
        set.insert(p2)
        set.insert(p3)
        #expect(set.count == 2)
        #expect(set.contains(p1))
    }

    @Test("usable_asDictionaryKey: keyed by id")
    func usableAsDictionaryKey() throws {
        let p1 = try decodePlaylist(id: "1", name: "Alpha")
        let p2 = try decodePlaylist(id: "1", name: "Beta")
        var dict = [Playlist: String]()
        dict[p1] = "first"
        dict[p2] = "second"
        #expect(dict.count == 1)
        #expect(dict[p1] == "second")
    }
}

// MARK: - PlaylistWithSongs

@Suite("PlaylistWithSongs Hashable")
struct PlaylistWithSongsHashableTests {

    @Test("equality_basedOnId: same id, different name → equal")
    func equalityBasedOnId() throws {
        let p1 = try decodePlaylistWithSongs(id: "1", name: "Alpha")
        let p2 = try decodePlaylistWithSongs(id: "1", name: "Beta")
        #expect(p1 == p2)
    }

    @Test("hash_consistentForSameId: same id → same hashValue")
    func hashConsistentForSameId() throws {
        let p1 = try decodePlaylistWithSongs(id: "1", name: "Alpha")
        let p2 = try decodePlaylistWithSongs(id: "1", name: "Beta")
        #expect(p1.hashValue == p2.hashValue)
    }

    @Test("usable_inSet: deduplication by id")
    func usableInSet() throws {
        let p1 = try decodePlaylistWithSongs(id: "1")
        let p2 = try decodePlaylistWithSongs(id: "1")
        let p3 = try decodePlaylistWithSongs(id: "2")
        var set = Set<PlaylistWithSongs>()
        set.insert(p1)
        set.insert(p2)
        set.insert(p3)
        #expect(set.count == 2)
        #expect(set.contains(p1))
    }

    @Test("usable_asDictionaryKey: keyed by id")
    func usableAsDictionaryKey() throws {
        let p1 = try decodePlaylistWithSongs(id: "1", name: "Alpha")
        let p2 = try decodePlaylistWithSongs(id: "1", name: "Beta")
        var dict = [PlaylistWithSongs: String]()
        dict[p1] = "first"
        dict[p2] = "second"
        #expect(dict.count == 1)
        #expect(dict[p1] == "second")
    }
}

// MARK: - Line (structural equality)

@Suite("Line Equatable")
struct LineEquatableTests {

    @Test("equal when value and start match")
    func equalWhenAllFieldsMatch() {
        let l1 = Line(value: "I hurt myself today", start: 1000)
        let l2 = Line(value: "I hurt myself today", start: 1000)
        #expect(l1 == l2)
        #expect(l1.hashValue == l2.hashValue)
    }

    @Test("not equal when value differs")
    func notEqualWhenValueDiffers() {
        let l1 = Line(value: "I hurt myself today", start: 1000)
        let l2 = Line(value: "To see if I still feel", start: 1000)
        #expect(l1 != l2)
    }

    @Test("not equal when start differs")
    func notEqualWhenStartDiffers() {
        let l1 = Line(value: "I hurt myself today", start: 1000)
        let l2 = Line(value: "I hurt myself today", start: 2000)
        #expect(l1 != l2)
    }

    @Test("usable in Set")
    func usableInSet() {
        let l1 = Line(value: "Hello", start: 0)
        let l2 = Line(value: "Hello", start: 0)
        let l3 = Line(value: "World", start: nil)
        let set = Set([l1, l2, l3])
        #expect(set.count == 2)
        #expect(set.contains(l1))
    }
}

// MARK: - StructuredLyrics (structural equality)

@Suite("StructuredLyrics Equatable")
struct StructuredLyricsEquatableTests {

    @Test("equal when all fields match")
    func equalWhenAllFieldsMatch() {
        let s1 = StructuredLyrics(lang: "en", synced: true, line: [Line(value: "Hello", start: 0)])
        let s2 = StructuredLyrics(lang: "en", synced: true, line: [Line(value: "Hello", start: 0)])
        #expect(s1 == s2)
        #expect(s1.hashValue == s2.hashValue)
    }

    @Test("not equal when lang differs")
    func notEqualWhenLangDiffers() {
        let s1 = StructuredLyrics(lang: "en", synced: false)
        let s2 = StructuredLyrics(lang: "fr", synced: false)
        #expect(s1 != s2)
    }

    @Test("not equal when synced differs")
    func notEqualWhenSyncedDiffers() {
        let s1 = StructuredLyrics(lang: "en", synced: true)
        let s2 = StructuredLyrics(lang: "en", synced: false)
        #expect(s1 != s2)
    }

    @Test("usable in Set")
    func usableInSet() {
        let s1 = StructuredLyrics(lang: "en", synced: true)
        let s2 = StructuredLyrics(lang: "en", synced: true)
        let s3 = StructuredLyrics(lang: "fr", synced: false)
        let set = Set([s1, s2, s3])
        #expect(set.count == 2)
        #expect(set.contains(s1))
    }
}

// MARK: - LyricsList (structural equality)

@Suite("LyricsList Equatable")
struct LyricsListEquatableTests {

    @Test("equal when structuredLyrics arrays match")
    func equalWhenContentsMatch() {
        let l1 = LyricsList(structuredLyrics: [StructuredLyrics(lang: "en", synced: false)])
        let l2 = LyricsList(structuredLyrics: [StructuredLyrics(lang: "en", synced: false)])
        #expect(l1 == l2)
        #expect(l1.hashValue == l2.hashValue)
    }

    @Test("not equal when contents differ")
    func notEqualWhenContentsDiffer() {
        let l1 = LyricsList(structuredLyrics: [StructuredLyrics(lang: "en", synced: false)])
        let l2 = LyricsList(structuredLyrics: [StructuredLyrics(lang: "fr", synced: false)])
        #expect(l1 != l2)
    }

    @Test("empty lists are equal")
    func emptyListsAreEqual() {
        #expect(LyricsList() == LyricsList())
    }

    @Test("usable in Set")
    func usableInSet() {
        let l1 = LyricsList(structuredLyrics: [StructuredLyrics(lang: "en", synced: true)])
        let l2 = LyricsList(structuredLyrics: [StructuredLyrics(lang: "en", synced: true)])
        let l3 = LyricsList()
        let set = Set([l1, l2, l3])
        #expect(set.count == 2)
    }
}

// MARK: - OpenSubsonicExtension (structural equality)

@Suite("OpenSubsonicExtension Equatable")
struct OpenSubsonicExtensionEquatableTests {

    @Test("equal when name and versions match")
    func equalWhenAllFieldsMatch() {
        let e1 = OpenSubsonicExtension(name: "songLyrics", versions: [1])
        let e2 = OpenSubsonicExtension(name: "songLyrics", versions: [1])
        #expect(e1 == e2)
        #expect(e1.hashValue == e2.hashValue)
    }

    @Test("not equal when name differs")
    func notEqualWhenNameDiffers() {
        let e1 = OpenSubsonicExtension(name: "songLyrics", versions: [1])
        let e2 = OpenSubsonicExtension(name: "apiKeyAuthentication", versions: [1])
        #expect(e1 != e2)
    }

    @Test("not equal when versions differ")
    func notEqualWhenVersionsDiffer() {
        let e1 = OpenSubsonicExtension(name: "songLyrics", versions: [1])
        let e2 = OpenSubsonicExtension(name: "songLyrics", versions: [1, 2])
        #expect(e1 != e2)
    }

    @Test("usable in Set")
    func usableInSet() {
        let e1 = OpenSubsonicExtension(name: "songLyrics", versions: [1])
        let e2 = OpenSubsonicExtension(name: "songLyrics", versions: [1])
        let e3 = OpenSubsonicExtension(name: "formPost", versions: [1])
        let set = Set([e1, e2, e3])
        #expect(set.count == 2)
        #expect(set.contains(e1))
    }
}
