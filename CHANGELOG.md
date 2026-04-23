# Changelog

All notable changes to SwiftSonic are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.2.0]: https://github.com/MathieuDubart/swiftsonic/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/MathieuDubart/swiftsonic/releases/tag/v0.1.0
