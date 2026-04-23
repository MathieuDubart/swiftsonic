# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 0.2.x   | ✅ Current |
| 0.1.x   | ❌ No longer supported |

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Instead, report them privately via [GitHub's security advisory system](https://github.com/MathieuDubart/swiftsonic/security/advisories/new).

You will receive an acknowledgement within **72 hours**. If the vulnerability is confirmed, a patch and coordinated disclosure will follow within a reasonable timeframe depending on severity.

## Scope

SwiftSonic is a client library that communicates with Subsonic/OpenSubsonic servers over HTTPS. Relevant security areas include:

- Credential handling (username / password / token transmission)
- URL construction and injection
- Response parsing (malformed or malicious server responses)
- Transport-layer configuration (TLS, timeouts)

Out of scope: vulnerabilities in the Subsonic server software itself, or in third-party Subsonic server implementations.
