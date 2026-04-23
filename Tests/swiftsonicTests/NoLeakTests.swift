// NoLeakTests.swift — SwiftSonicTests
//
// Anti-regression canary tests that verify no authentication credential
// escapes into any observable string representation.
//
// Design principle: every sensitive value uses a unique, recognisable marker
// (e.g. "secret_unique_password_marker") so that any future regression that
// accidentally exposes a credential will be caught immediately — the marker
// will appear in the output and the test will fail.
//
// Coverage:
//   - URL.safeDescription (all 5 known auth query params)
//   - AuthMethod.description / .debugDescription / String(describing:)
//   - ServerConfiguration.description / .debugDescription
//   - SwiftSonicError.localizedDescription for every case

import Testing
import Foundation
@testable import SwiftSonic

// MARK: - Canary constants

private enum Canary {
    static let username = "alice_unique_username_marker"
    static let password = "secret_unique_password_marker"
    static let token    = "deadbeef_unique_token_marker"
    static let salt     = "abc123_unique_salt_marker"
    static let plain    = "plainpassword_unique_marker"
    static let apiKey   = "sk_live_unique_apikey_marker"
}

// MARK: - URL.safeDescription

@Suite("URL.safeDescription — no credential leaks")
struct URLSafeDescriptionTests {

    @Test("masks all five known auth query parameters")
    func masksAllAuthParams() {
        let url = URL(string:
            "https://music.example.com/rest/getArtists" +
            "?u=\(Canary.username)" +
            "&t=\(Canary.token)" +
            "&s=\(Canary.salt)" +
            "&p=\(Canary.plain)" +
            "&apiKey=\(Canary.apiKey)" +
            "&v=1.16.1&c=myApp&f=json"
        )!

        let safe = url.safeDescription

        // No sensitive value must appear
        #expect(!safe.contains(Canary.username),  "username canary leaked into safeDescription")
        #expect(!safe.contains(Canary.token),     "token canary leaked into safeDescription")
        #expect(!safe.contains(Canary.salt),      "salt canary leaked into safeDescription")
        #expect(!safe.contains(Canary.plain),     "plaintext-password canary leaked into safeDescription")
        #expect(!safe.contains(Canary.apiKey),    "apiKey canary leaked into safeDescription")

        // Safe structural parts must be preserved
        #expect(safe.contains("music.example.com"))
        #expect(safe.contains("getArtists"))
        #expect(safe.contains("v=1.16.1"))
        #expect(safe.contains("c=myApp"))
    }

    @Test("redacted params show <name>=*** form")
    func redactedParamsUseStarPlaceholder() {
        let url = URL(string: "https://music.example.com/rest/ping?u=alice&t=tok&s=slt&v=1.16.1")!
        let safe = url.safeDescription
        #expect(safe.contains("u=***"))
        #expect(safe.contains("t=***"))
        #expect(safe.contains("s=***"))
        #expect(safe.contains("v=1.16.1")) // non-auth param unchanged
    }

    @Test("URL with no auth params is returned unchanged")
    func noAuthParamsIsIdentity() {
        let url = URL(string: "https://music.example.com/share/abc123")!
        #expect(url.safeDescription == url.absoluteString)
    }

    @Test("URL with only non-auth params is returned unchanged")
    func onlyNonAuthParamsIsIdentity() {
        let url = URL(string: "https://music.example.com/rest/ping?v=1.16.1&c=myApp&f=json")!
        #expect(url.safeDescription == url.absoluteString)
    }
}

// MARK: - AuthMethod no-leak

@Suite("AuthMethod — no credential leaks in string representations")
struct AuthMethodNoLeakTests {

    @Test("tokenAuth.description masks password, preserves username")
    func tokenAuthDescriptionMasksPassword() {
        let auth = AuthMethod.tokenAuth(
            username: Canary.username,
            password: Canary.password,
            reusesSalt: false
        )
        let desc      = auth.description
        let debugDesc = auth.debugDescription

        #expect(!desc.contains(Canary.password),      "password canary in description")
        #expect(!debugDesc.contains(Canary.password), "password canary in debugDescription")
        // Username is intentionally included (not a secret)
        #expect(desc.contains(Canary.username))
    }

    @Test("apiKey.description masks key")
    func apiKeyDescriptionMasksKey() {
        let auth = AuthMethod.apiKey(Canary.apiKey)
        let desc      = auth.description
        let debugDesc = auth.debugDescription

        #expect(!desc.contains(Canary.apiKey),      "apiKey canary in description")
        #expect(!debugDesc.contains(Canary.apiKey), "apiKey canary in debugDescription")
    }

    @Test("String(describing:) on tokenAuth is redacted")
    func stringDescribingTokenAuthIsRedacted() {
        let auth = AuthMethod.tokenAuth(username: "u", password: Canary.password, reusesSalt: false)
        let s = String(describing: auth)
        #expect(!s.contains(Canary.password), "password canary in String(describing:)")
    }

    @Test("String(describing:) on apiKey is redacted")
    func stringDescribingApiKeyIsRedacted() {
        let auth = AuthMethod.apiKey(Canary.apiKey)
        let s = String(describing: auth)
        #expect(!s.contains(Canary.apiKey), "apiKey canary in String(describing:)")
    }
}

// MARK: - ServerConfiguration no-leak

@Suite("ServerConfiguration — no credential leaks in string representations")
struct ServerConfigurationNoLeakTests {

    @Test("description with tokenAuth masks password")
    func descriptionMasksPassword() {
        let config = ServerConfiguration(
            serverURL: URL(string: "https://music.example.com")!,
            username: "alice",
            password: Canary.password
        )
        let desc      = config.description
        let debugDesc = config.debugDescription

        #expect(!desc.contains(Canary.password),      "password canary in description")
        #expect(!debugDesc.contains(Canary.password), "password canary in debugDescription")
    }

    @Test("description with apiKey masks key")
    func descriptionMasksApiKey() {
        let config = ServerConfiguration(
            serverURL: URL(string: "https://music.example.com")!,
            auth: .apiKey(Canary.apiKey)
        )
        let desc      = config.description
        let debugDesc = config.debugDescription

        #expect(!desc.contains(Canary.apiKey),      "apiKey canary in description")
        #expect(!debugDesc.contains(Canary.apiKey), "apiKey canary in debugDescription")
    }

    @Test("String(describing:) on configuration is redacted")
    func stringDescribingConfigIsRedacted() {
        let config = ServerConfiguration(
            serverURL: URL(string: "https://music.example.com")!,
            auth: .apiKey(Canary.apiKey)
        )
        let s = String(describing: config)
        #expect(!s.contains(Canary.apiKey), "apiKey canary in String(describing:)")
    }
}

// MARK: - SwiftSonicError.localizedDescription no-leak

/// Verifies that no known credential canary escapes into any SwiftSonicError
/// description. Tests each case independently so a regression in one case
/// doesn't silently mask others.
@Suite("SwiftSonicError.localizedDescription — no credential leaks")
struct SwiftSonicErrorNoLeakTests {

    @Test("api error description contains no credential canaries")
    func apiErrorDescriptionSafe() {
        let apiError = SubsonicAPIError(
            code: .wrongCredentials,
            message: "Wrong credentials",
            helpURL: nil,
            endpoint: "ping",
            serverHost: "music.example.com"
        )
        let desc = SwiftSonicError.api(apiError).localizedDescription
        #expect(!desc.contains(Canary.password), "password canary in api error description")
        #expect(!desc.contains(Canary.apiKey),   "apiKey canary in api error description")
        #expect(!desc.contains(Canary.token),    "token canary in api error description")
    }

    @Test("httpError description contains status, endpoint, host — no canaries")
    func httpErrorDescriptionSafe() {
        let desc = SwiftSonicError.httpError(
            statusCode: 401,
            endpoint: "getArtists",
            serverHost: "music.example.com"
        ).localizedDescription
        #expect(!desc.contains(Canary.password), "password canary in httpError description")
        #expect(!desc.contains(Canary.apiKey),   "apiKey canary in httpError description")
        // Safe fields must be present
        #expect(desc.contains("401"))
        #expect(desc.contains("getArtists"))
    }

    @Test("rateLimited description safe")
    func rateLimitedDescriptionSafe() {
        let desc = SwiftSonicError.rateLimited(
            retryAfter: 5.0,
            endpoint: "search3",
            serverHost: "music.example.com"
        ).localizedDescription
        #expect(!desc.contains(Canary.password), "password canary in rateLimited description")
        #expect(!desc.contains(Canary.apiKey),   "apiKey canary in rateLimited description")
        #expect(desc.contains("search3"))
    }

    @Test("network error description safe")
    func networkErrorDescriptionSafe() {
        let desc = SwiftSonicError.network(URLError(.timedOut)).localizedDescription
        #expect(!desc.contains(Canary.password), "password canary in network error description")
        #expect(!desc.contains(Canary.apiKey),   "apiKey canary in network error description")
    }

    @Test("decoding error description safe")
    func decodingErrorDescriptionSafe() {
        let dErr = DecodingError.valueNotFound(
            String.self,
            DecodingError.Context(codingPath: [], debugDescription: "missing key")
        )
        let desc = SwiftSonicError.decoding(dErr, rawData: Data()).localizedDescription
        #expect(!desc.contains(Canary.password), "password canary in decoding error description")
        #expect(!desc.contains(Canary.apiKey),   "apiKey canary in decoding error description")
    }

    @Test("invalidConfiguration description safe")
    func invalidConfigurationDescriptionSafe() {
        let desc = SwiftSonicError.invalidConfiguration("bad url").localizedDescription
        #expect(!desc.contains(Canary.password), "password canary in invalidConfiguration description")
        #expect(!desc.contains(Canary.apiKey),   "apiKey canary in invalidConfiguration description")
    }

    @Test("insecureRedirect description contains hosts, no canaries")
    func insecureRedirectDescriptionSafe() {
        let from = URL(string: "https://music.example.com/rest/ping")!
        let to   = URL(string: "https://evil.example.com/steal")!
        let desc = SwiftSonicError.insecureRedirect(from: from, to: to).localizedDescription
        #expect(!desc.contains(Canary.password), "password canary in insecureRedirect description")
        #expect(!desc.contains(Canary.apiKey),   "apiKey canary in insecureRedirect description")
        // Safe structural parts must be present
        #expect(desc.contains("music.example.com"))
        #expect(desc.contains("evil.example.com"))
    }
}
