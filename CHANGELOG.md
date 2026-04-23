# Changelog

All notable changes to SwiftSonic are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.3.0]: https://github.com/MathieuDubart/swiftsonic/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/MathieuDubart/swiftsonic/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/MathieuDubart/swiftsonic/releases/tag/v0.1.0
