# SwiftSonic

[![CI](https://github.com/MathieuDubart/swiftsonic/actions/workflows/ci.yml/badge.svg)](https://github.com/MathieuDubart/swiftsonic/actions/workflows/ci.yml)
[![Swift 6](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](https://swift.org)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D)](https://swift.org/package-manager)
[![GitHub release](https://img.shields.io/github/v/release/MathieuDubart/swiftsonic?color=4BC51D)](https://github.com/MathieuDubart/swiftsonic/releases)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2016%20%7C%20macOS%2013%20%7C%20tvOS%2016%20%7C%20watchOS%209%20%7C%20visionOS%201-lightgrey)](https://developer.apple.com/swift/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A modern, Swift-native client for the [Subsonic](http://www.subsonic.org/pages/api.jsp) and [OpenSubsonic](https://opensubsonic.netlify.app/) APIs.

```swift
import SwiftSonic

let client = SwiftSonicClient(
    serverURL: URL(string: "https://music.example.com")!,
    username: "alice",
    password: "secret"
)
let artists = try await client.getArtists()
```

That's it. No setup, no singleton, no global state.

---

## Why SwiftSonic?

Every existing Swift Subsonic client is either abandoned, built on Alamofire, or missing OpenSubsonic support entirely. SwiftSonic fills that gap:

| | SwiftSonic | SubsonicKit | SubSonicAPI |
|---|---|---|---|
| Swift 6 strict concurrency | ✅ | ❌ | ❌ |
| OpenSubsonic extensions | ✅ | ❌ | ❌ |
| Zero dependencies | ✅ | ❌ (Alamofire) | ❌ |
| async/await native | ✅ | ✅ | ❌ |
| Typed error codes | ✅ | ❌ | ❌ |
| Injectable transport | ✅ | ❌ | ❌ |
| Actively maintained | ✅ | ⚠️ | ❌ |

---

## Requirements

- iOS 16+ / macOS 13+ / tvOS 16+ / watchOS 9+ / visionOS 1+
- Swift 5.9+
- Xcode 15+

---

## Installation

### Swift Package Manager

Add SwiftSonic to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/MathieuDubart/swiftsonic.git", from: "0.1.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [.product(name: "SwiftSonic", package: "swiftsonic")]
    )
]
```

Or in Xcode: **File → Add Package Dependencies** → paste the repo URL.

---

## Usage

### Basic setup

```swift
import SwiftSonic

// Standard token auth (most servers)
let client = SwiftSonicClient(
    serverURL: URL(string: "https://music.example.com")!,
    username: "alice",
    password: "secret"
)

// API key auth (OpenSubsonic servers)
let client = SwiftSonicClient(
    configuration: ServerConfiguration(
        serverURL: URL(string: "https://music.example.com")!,
        auth: .apiKey("my-api-key")
    )
)
```

### Checking server capabilities

```swift
try await client.fetchCapabilities()

if let caps = client.serverCapabilities {
    print("Server: \(caps.serverType ?? "unknown") \(caps.serverVersion ?? "")")
    print("OpenSubsonic: \(caps.isOpenSubsonic)")

    if caps.supports("songLyrics") {
        // call OpenSubsonic-specific endpoints
    }
}
```

### Browsing

```swift
// All artists, grouped by index letter
let indexes = try await client.getArtists()
for index in indexes {
    for artist in index.artist {
        print(artist.name)
    }
}

// Music folders
let folders = try await client.getMusicFolders()
```

### Search

```swift
let results = try await client.search3("bohemian", songCount: 10)
print(results.song?.first?.title)   // "Bohemian Rhapsody"
print(results.artist?.first?.name)  // "Queen"
```

### Playlists

```swift
// List all playlists
let playlists = try await client.getPlaylists()

// Fetch a specific playlist with its tracks
let playlist = try await client.getPlaylist(id: "42")
for song in playlist.entry ?? [] {
    print("\(song.title) — \(song.artist ?? "")")
}

// Create and modify
let newPlaylist = try await client.createPlaylist(name: "Road Trip", songIds: ["101", "202"])
try await client.updatePlaylist(id: newPlaylist.id, isPublic: true, songIdsToAdd: ["303"])
try await client.deletePlaylist(id: newPlaylist.id)
```

### Media URLs

Media URL methods are `nonisolated` — no `await` needed:

```swift
// Stream a song in AVPlayer
if let url = client.streamURL(id: "101", maxBitRate: 320, format: "mp3") {
    let player = AVPlayer(url: url)
    player.play()
}

// Cover art for AsyncImage
if let url = client.coverArtURL(id: "al-10", size: 300) {
    AsyncImage(url: url)
}

// Download
let downloadLink = client.downloadURL(id: "101")
```

### Annotations

```swift
// Star songs and albums
try await client.star(songIds: ["101", "201"], albumIds: ["10"])
try await client.unstar(songIds: ["101"])

// Rate (1–5, or 0 to remove)
try await client.setRating(id: "101", rating: 5)

// Scrobble (now playing or completed play)
try await client.scrobble(id: "101", submission: false) // now playing
try await client.scrobble(id: "101")                    // completed
```

### Error handling

```swift
do {
    try await client.ping()
} catch SwiftSonicError.api(let error) {
    switch error.code {
    case .wrongCredentials:
        // prompt re-auth
    case .notFound:
        // resource missing
    default:
        print("Server error \(error.code.rawValue): \(error.message)")
    }
} catch SwiftSonicError.network(let urlError) {
    // no connectivity
} catch SwiftSonicError.httpError(let statusCode, _) {
    // non-2xx response
}
```

### Custom transport (logging, cert pinning, proxies)

```swift
struct LoggingTransport: HTTPTransport {
    let underlying: any HTTPTransport = URLSessionTransport()

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        print("→ \(request.url!)")
        let result = try await underlying.data(for: request)
        print("← \(result.1.statusCode)")
        return result
    }
}

let client = SwiftSonicClient(
    configuration: config,
    transport: LoggingTransport()
)
```

---

## Endpoint coverage

### System
| Endpoint | Status |
|---|---|
| `ping` | ✅ |
| `getLicense` | ✅ |
| `getOpenSubsonicExtensions` | ✅ |

### Browsing
| Endpoint | Status |
|---|---|
| `getMusicFolders` | ✅ |
| `getArtists` | ✅ |
| `getArtist` | ✅ |
| `getAlbum` | ✅ |
| `getSong` | ✅ |
| `getGenres` | ✅ |
| `getIndexes` | ✅ |
| `getMusicDirectory` | ✅ |
| `getArtistInfo2` | ✅ |
| `getAlbumInfo2` | ✅ |

### Lists
| Endpoint | Status |
|---|---|
| `getAlbumList2` | ✅ |
| `getRandomSongs` | ✅ |
| `getSongsByGenre` | ✅ |
| `getStarred2` | ✅ |

### Search
| Endpoint | Status |
|---|---|
| `search3` | ✅ |

### Playlists
| Endpoint | Status |
|---|---|
| `getPlaylists` | ✅ |
| `getPlaylist` | ✅ |
| `createPlaylist` | ✅ |
| `updatePlaylist` | ✅ |
| `deletePlaylist` | ✅ |

### Media URLs
| Endpoint | Status |
|---|---|
| `stream` | ✅ |
| `download` | ✅ |
| `getCoverArt` | ✅ |
| `hls` | ✅ |

### Annotations
| Endpoint | Status |
|---|---|
| `star` | ✅ |
| `unstar` | ✅ |
| `setRating` | ✅ |
| `scrobble` | ✅ |

### User
| Endpoint | Status |
|---|---|
| `getUser` | ❌ |

---

## Design principles

- **Thread-safe by construction** — `SwiftSonicClient` is a Swift actor
- **Zero dependencies** — only `Foundation` and `CryptoKit`
- **Sendable everywhere** — all public types conform to `Sendable`, zero warnings in strict concurrency
- **Injectable transport** — swap out `URLSession` for testing, proxying, or cert pinning
- **No UI coupling** — `Data` and `URL` only, never `UIImage` or `SwiftUI.Image`
- **Silent by default** — pass `logSubsystem:` to opt into `os.Logger` output

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT — see [LICENSE](LICENSE).
