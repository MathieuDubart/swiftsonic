# Changelog

All notable changes to SwiftSonic are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.6.0] — 2026-04-27

### Added

- **`Equatable` and `Hashable` on core models** — `ArtistID3`, `AlbumID3`, `Song`, `Playlist`, and `PlaylistWithSongs` now conform to `Equatable` and `Hashable`. Equality is keyed on `id`; these types can be used directly as `Set` elements or `Dictionary` keys without a wrapper.

- **Public initialisers on `Playlist` and `PlaylistWithSongs`** — both structs gain a full `public init` with all fields and `nil` defaults, making it easy to construct values in tests or local drafts without going through JSON decoding.

- **`createPlaylist` replace mode** — `createPlaylist` now accepts an optional `playlistId` parameter. When provided, the existing playlist's track list is replaced atomically with `songIds` in order — the only way to reorder a playlist via the Subsonic API. Passing neither `name` nor `playlistId` throws `SwiftSonicError.invalidConfiguration`.

- **Single-item `star` / `unstar` overloads** — `star(songId:)`, `star(albumId:)`, `star(artistId:)` and their `unstar` counterparts avoid wrapping a single ID in an array at the call site.

- **288 tests** across 97 suites (up from 253 in v0.5.0).

---

## [0.5.0] — 2026-04-23

### Security

> **Upgrade recommended.** This release completes the hardening work started in v0.4.1.
> All items below address findings from the internal security audit.

- **[D3] Cross-domain redirect blocking** — `URLSessionTransport` now uses a per-request `URLSessionTaskDelegate` (`RedirectGuard`) that intercepts HTTP redirects. Any redirect to a host different from the original server is refused and surfaces as the new `SwiftSonicError.insecureRedirect(from:to:)` error. Following a cross-domain redirect would have silently forwarded authentication credentials (embedded as query parameters in the request URL) to an untrusted host. Same-domain redirects continue to be followed normally.

- **[A3] Stronger salt generation** — The Subsonic authentication salt has been increased from 10 to 16 characters (~95 bits of entropy), and `SystemRandomNumberGenerator` is now used explicitly (backed by the OS CSPRNG, `SecRandomCopyBytes` on Apple platforms).

- **[D2] HTTP plain-text warning** — `SwiftSonicClient` now emits an `os.Logger` warning (subsystem `com.swiftsonic`, category `security`) at client initialisation when the configured server URL uses plain HTTP. The warning fires unconditionally regardless of the caller's `logSubsystem` setting, ensuring it is always visible in Console.app.

- **[D4] Request timeout floor** — `ServerConfiguration.requestTimeout` is now clamped to a minimum of 1 second. A zero or near-zero value would cause every request to fail immediately with undefined behaviour across `URLSession` implementations.

- **[C1] `LocalizedError` conformance** — `SwiftSonicError` now conforms to `LocalizedError`. Every `errorDescription` is credential-safe: no usernames, passwords, or API keys appear in any string. Only structural metadata (endpoint name, server hostname, HTTP status code, server-provided message) is included.

### Added

- `SwiftSonicError.insecureRedirect(from: URL, to: URL)` — new error case (non-transient, not an authentication failure).

---

## [0.4.1] — 2026-04-23

### Security

> **Upgrade recommended.** This release fixes two credential-leak vulnerabilities present in v0.1.0–v0.4.0.
> See the [GitHub Security Advisory](https://github.com/MathieuDubart/swiftsonic/security/advisories) for full details.

- **[A1] Credential leak via error `requestURL`** — `SwiftSonicError.httpError`, `.rateLimited`, and `SubsonicAPIError` previously stored the full request URL (including `u`, `t`, `s`, or `apiKey` query parameters) as a public `requestURL: URL` field. Any consumer passing these errors to a crash reporter, analytics pipeline, or `print()` call would inadvertently expose authentication credentials. The full URL has been replaced with two credential-free fields: `endpoint: String` (e.g. `"getArtists"`) and `serverHost: String?` (e.g. `"music.example.com"`).

  **Migration:** Replace `error.requestURL` accesses and `httpError(statusCode:requestURL:)` / `rateLimited(retryAfter:requestURL:)` pattern matches with `endpoint:serverHost:`.

- **[A2] Credential leak via default string representation** — `AuthMethod` and `ServerConfiguration` lacked `CustomStringConvertible` conformances. Swift's default enum description prints all associated values, so `print(config.auth)` or inspection in the Xcode debugger Variables panel would output the plaintext password or API key. Both types now redact secrets as `"***"` in all string representations.

### Breaking changes in this patch

Both fixes are technically breaking for consumers who accessed `requestURL` or pattern-matched the old case labels. The old API was insecure by design; the new API is the correct replacement.

---

## [0.4.0] — 2026-04-23

### Added

- **User management** — `getUser(username:)`, `getUsers()`, `createUser(_:)`, `updateUser(_:)`, `deleteUser(username:)`, `changePassword(username:newPassword:)`; new `User`, `NewUser`, and `UserUpdate` models. Passwords are always transmitted as `enc:<hexUTF8>` on the wire — the Swift API accepts plain strings.
- **Chat** — `getChatMessages(since:)` → `[ChatMessage]`, `addChatMessage(_:)`; new `ChatMessage` model with `time: Date` (milliseconds-since-epoch wire conversion, consistent with `Bookmark`/`Share`).
- **Lyrics** — `getLyrics(artist:title:)` → `Lyrics?`; new `Lyrics` model (`artist?`, `title?`, `value?`). Returns `nil` when the server returns no lyrics or an empty value.
- **Now Playing** — `getNowPlaying()` → `[NowPlayingEntry]`; new flat `NowPlayingEntry` model (focused subset: `id`, `title`, `artist`, `album`, `duration`, `coverArt`, `contentType` + `username`, `minutesAgo`, `playerId`, `playerName?`). Returns `[]` when nothing is playing.
- **Avatar media URL** — `avatarURL(username:)` nonisolated URL builder; mirrors the existing `coverArtURL`/`streamURL` pattern.
- **Discovery endpoints** — `getArtistInfo(id:count:includeNotPresent:)`, `getAlbumInfo(id:)` (folder-based variant), `getSimilarSongs(id:count:)`, `getSimilarSongs2(id:count:)`, `getTopSongs(artist:count:)` → all reuse the `Song` and `ArtistInfo`/`AlbumInfo` models.
- **Legacy list endpoints** — `getAlbumList(type:size:offset:…)` → `[Song]` (folder-based; prefer `getAlbumList2` for ID3 browsing); `getStarred(musicFolderId:)` → `Starred` (new folder-based model with `artist?`, `album?`, `song?`).
- **Legacy search** — `search2(_:…)` → `SearchResult2` (new folder-based model; prefer `search3` for ID3 browsing).
- **233 tests** across 82 suites (up from 196 in v0.3.1).

---

## [0.3.1] — 2026-04-23

### Fixed
- `JSONDecoder.DateDecodingStrategy.iso8601` does not handle fractional-second timestamps (e.g. `"2026-01-15T10:00:00.000Z"`) in the `swift test` CLI on macOS. Replaced with a custom strategy that tries `.withFractionalSeconds` first and falls back to basic ISO 8601, fixing 15 CI test failures in the `getShares`, `createShare`, `getNewestPodcasts`, `getBookmarks`, and `getPlayQueue` suites.

---

## [0.3.0] — 2026-04-23

### Added
- **Scan endpoints** — `getScanStatus()`, `startScan()` → `ScanStatus`; lenient ISO 8601 parser handles Navidrome's nanosecond-precision timestamps
- **Internet Radio endpoints** — `getInternetRadioStations()`, `createInternetRadioStation(streamURL:name:homepageURL:)`, `updateInternetRadioStation(id:streamURL:name:homepageURL:)`, `deleteInternetRadioStation(id:)` → `InternetRadioStation`
- **Bookmark endpoints** — `getBookmarks()`, `createBookmark(songId:position:comment:)`, `deleteBookmark(songId:)` → `Bookmark`; position expressed as `TimeInterval` (seconds), converted to/from milliseconds on the wire
- **Play Queue endpoints** — `getPlayQueue()` → `SavedPlayQueue?` (nil when no queue saved), `savePlayQueue(ids:current:position:)`; position in seconds, wire format milliseconds
- **Share endpoints** — `getShares()`, `createShare(ids:description:expires:)`, `updateShare(id:description:expires:)`, `deleteShare(id:)` → `Share`; `expires` expressed as `Date`, converted to/from milliseconds-since-epoch on the wire
- **Podcast endpoints** — `getPodcasts(id:includeEpisodes:)`, `getNewestPodcasts(count:)`, `refreshPodcasts()`, `createPodcastChannel(url:)`, `deletePodcastChannel(id:)`, `downloadPodcastEpisode(id:)`, `deletePodcastEpisode(id:)` → `PodcastChannel` / `PodcastEpisode`; `PodcastChannelStatus` and `PodcastEpisodeStatus` enums with `.unknown` fallback for forward compatibility
- **Jukebox endpoints** — 11 separate methods (`jukeboxGet`, `jukeboxStatus`, `jukeboxStart`, `jukeboxStop`, `jukeboxSkip`, `jukeboxAdd`, `jukeboxSet`, `jukeboxRemove`, `jukeboxClear`, `jukeboxShuffle`, `jukeboxSetGain`) → `JukeboxPlaylist` / `JukeboxStatus`
- **Integration tests** extended with `getScanStatus`, `getInternetRadioStations`, `getBookmarks`, `getPlayQueue` live checks against `demo.navidrome.org`
- **169 tests** across 63 suites (up from 110 in v0.2.0)

---

## [0.2.0] — 2026-04-23

### Added
- **Browsing endpoints** — `getGenres()`, `getAlbumList2(type:size:offset:musicFolderId:)`, `getRandomSongs(size:genre:fromYear:toYear:musicFolderId:)`, `search3(_:artistCount:albumCount:songCount:musicFolderId:)`
- **Retry & resilience** — `RetryPolicy` with configurable exponential back-off + jitter; `.default` (3 attempts) and `.none` presets; transient-error detection on `SwiftSonicError`
- **Observability** — structured `os.Logger` logging throughout the request lifecycle; `SwiftSonicMetricsCollector` protocol with `SwiftSonicRequestEvent` enum (`.started`, `.succeeded`, `.failed`, `.retryScheduled`)
- **Rate-limit handling** — `SwiftSonicError.rateLimited(retryAfter:requestURL:)` case; `Retry-After` header parsing
- **Error classification helpers** — `isTransient`, `isAuthenticationFailure`, `suggestedRetryDelay` on `SwiftSonicError`
- **Full-stack tests** — `URLProtocolTests` exercises the complete `SwiftSonicClient → URLSessionTransport → URLSession` pipeline via `MockURLProtocol`
- **Integration tests** — `IntegrationTests` suite against `demo.navidrome.org`; skipped unless `SWIFTSONIC_INTEGRATION_TESTS=1`
- **CI** — `swift test --parallel` flag; release workflow triggered on semver tags

### Changed
- `ServerConfiguration` gains an optional `requestTimeout` parameter (default `30 s`)
- `SwiftSonicClient` initialiser gains optional `retryPolicy` and `metricsCollector` parameters
- Internal envelope types (`SubsonicPayload`, `SubsonicEnvelope`, container structs) are now explicitly `Sendable`

---

## [0.1.0] — 2026-04-23

### Added
- Initial release
- `SwiftSonicClient` actor with injectable `HTTPTransport`
- `URLSessionTransport` (default transport, token-auth via `MD5(password + salt)`)
- `ServerConfiguration` — URL, username, password
- `ServerCapabilities` — API version + OpenSubsonic flag cached on the client
- **System endpoints** — `ping()`, `getLicense()`, `fetchCapabilities()`, `getOpenSubsonicExtensions()`
- **Browsing endpoints** — `getMusicFolders()`, `getArtists(musicFolderId:)`
- `SwiftSonicError` — typed error enum wrapping API, HTTP, network, and configuration errors
- `SubsonicAPIError` + `SubsonicErrorCode` — typed Subsonic API error codes
- Unit tests with `MockHTTPTransport` and JSON fixture files
- `ResilienceTests` — white-box tests for retry math and error classification
- MIT licence, `CONTRIBUTING.md`, `SECURITY.md`

[0.6.0]: https://github.com/MathieuDubart/swiftsonic/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/MathieuDubart/swiftsonic/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/MathieuDubart/swiftsonic/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/MathieuDubart/swiftsonic/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/MathieuDubart/swiftsonic/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/MathieuDubart/swiftsonic/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/MathieuDubart/swiftsonic/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/MathieuDubart/swiftsonic/releases/tag/v0.1.0
