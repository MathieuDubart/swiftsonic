// URLExtensions.swift — SwiftSonic (Internal)
//
// Provides URL.safeDescription: a credential-safe string representation of
// a Subsonic request URL that redacts all known authentication query parameters.
//
// Use this helper whenever a URL must be included in a log message, error
// string, or any other observable output, to prevent accidental credential leaks.

import Foundation

// MARK: - URL.safeDescription

extension URL {
    /// A credential-safe string representation suitable for log messages.
    ///
    /// Subsonic request URLs embed authentication credentials as query parameters
    /// (`u`, `t`, `s`, `p`, `apiKey`). This property strips the **values** of those
    /// parameters, replacing each with `"***"`, while preserving the parameter names
    /// so the output remains informative for debugging.
    ///
    /// All other query parameters (e.g. `v`, `c`, `f`) are included unmodified.
    ///
    /// ```
    /// // Input:  https://music.example.com/rest/ping?u=alice&t=abc&s=xyz&v=1.16.1&c=MyApp
    /// // Output: https://music.example.com/rest/ping?u=***&t=***&s=***&v=1.16.1&c=MyApp
    /// ```
    ///
    /// - Returns: A redacted URL string, or `"<url-not-representable>"` if the URL
    ///   cannot be parsed by `URLComponents` (should never happen for well-formed
    ///   Subsonic URLs).
    var safeDescription: String {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            // Do NOT fall back to absoluteString — it may contain credentials.
            return "<url-not-representable>"
        }

        let authParams: Set<String> = ["u", "t", "s", "p", "apiKey"]

        if let items = components.queryItems, !items.isEmpty {
            components.queryItems = items.map { item in
                authParams.contains(item.name)
                    ? URLQueryItem(name: item.name, value: "***")
                    : item
            }
        }

        return components.string ?? "<url-not-representable>"
    }
}
