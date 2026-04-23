// SwiftSonicClient.swift — SwiftSonic
//
// The main entry point for the SwiftSonic library.
//
// SwiftSonicClient is a Swift actor: it is thread-safe by construction and can be
// called from any concurrency context without additional synchronisation.
//
// Endpoint implementations live in separate extension files (SwiftSonicClient+*.swift)
// grouped by API domain. This file only defines the actor, its state, and the shared
// perform(_:) helper used by every endpoint.

import Foundation
import OSLog

// MARK: - SwiftSonicClient

/// A client for the Subsonic and OpenSubsonic APIs.
///
/// `SwiftSonicClient` is thread-safe by construction (Swift actor).
///
/// ## Quick start
/// ```swift
/// import SwiftSonic
///
/// let client = SwiftSonicClient(
///     serverURL: URL(string: "https://music.example.com")!,
///     username: "alice",
///     password: "secret"
/// )
/// let artists = try await client.getArtists()
/// ```
///
/// ## Retry behaviour
/// By default the client retries up to 3 times on transient failures (network
/// errors, HTTP 5xx, HTTP 429) with exponential backoff. Override the default
/// by passing a custom ``RetryPolicy``:
/// ```swift
/// let client = SwiftSonicClient(
///     configuration: config,
///     retryPolicy: RetryPolicy(maxAttempts: 5, baseDelay: 1.0)
/// )
/// // Or disable retries entirely:
/// let client = SwiftSonicClient(configuration: config, retryPolicy: .none)
/// ```
///
/// ## Injecting a custom transport
/// Pass a custom ``HTTPTransport`` to add logging, proxying, or certificate pinning:
/// ```swift
/// let client = SwiftSonicClient(
///     configuration: config,
///     transport: MyLoggingTransport()
/// )
/// ```
public actor SwiftSonicClient {

    // MARK: - Public state

    /// The configuration used to build every request.
    public let configuration: ServerConfiguration

    /// The server capabilities loaded by ``fetchCapabilities()``.
    ///
    /// `nil` until ``fetchCapabilities()`` completes successfully.
    public private(set) var serverCapabilities: ServerCapabilities?

    // MARK: - Private state

    let transport: any HTTPTransport
    let requestBuilder: RequestBuilder
    private let retryPolicy: RetryPolicy
    private let metricsCollector: (any SwiftSonicMetricsCollector)?
    private let logger: Logger

    // MARK: - Initializers

    /// Creates a client with full control over configuration, transport, and behaviour.
    ///
    /// All parameters after `configuration` are optional and have sensible defaults —
    /// the five-line quick-start example in the README continues to work unchanged.
    ///
    /// - Parameters:
    ///   - configuration: Connection and authentication parameters.
    ///   - transport: The HTTP transport to use. When `nil` (default), a
    ///     ``URLSessionTransport`` is created and configured with the timeout values
    ///     from `configuration`.
    ///   - retryPolicy: Controls retry behaviour on transient failures. Defaults to
    ///     ``RetryPolicy/default`` (3 attempts, exponential backoff).
    ///   - metricsCollector: Optional hook for observability. Receives a
    ///     ``SwiftSonicRequestEvent`` for every attempt, retry, success, and failure.
    ///     Defaults to `nil` (no-op).
    ///   - logSubsystem: If non-nil, enables `os.Logger` output under this subsystem.
    ///     Defaults to `nil` (silent).
    public init(
        configuration: ServerConfiguration,
        transport: (any HTTPTransport)? = nil,
        retryPolicy: RetryPolicy = .default,
        metricsCollector: (any SwiftSonicMetricsCollector)? = nil,
        logSubsystem: String? = nil
    ) {
        self.configuration    = configuration
        self.retryPolicy      = retryPolicy
        self.metricsCollector = metricsCollector
        self.requestBuilder   = RequestBuilder(configuration: configuration)

        // When no custom transport is provided, create a URLSession configured with
        // the timeout values declared in ServerConfiguration.
        if let transport {
            self.transport = transport
        } else {
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest  = configuration.requestTimeout
            sessionConfig.timeoutIntervalForResource = configuration.resourceTimeout
            self.transport = URLSessionTransport(configuration: sessionConfig)
        }

        if let subsystem = logSubsystem {
            self.logger = Logger(subsystem: subsystem, category: "SwiftSonicClient")
        } else {
            self.logger = Logger(.disabled)
        }
    }

    /// Creates a client using standard salted-token authentication.
    ///
    /// This is the minimal initializer for the common case.
    ///
    /// ```swift
    /// let client = SwiftSonicClient(
    ///     serverURL: URL(string: "https://music.example.com")!,
    ///     username: "alice",
    ///     password: "secret"
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - serverURL: The base URL of the Subsonic server.
    ///   - username: The account username.
    ///   - password: The account password (never sent over the network).
    ///   - transport: The HTTP transport to use. Defaults to ``URLSessionTransport``.
    public init(
        serverURL: URL,
        username: String,
        password: String,
        transport: (any HTTPTransport)? = nil
    ) {
        self.init(
            configuration: ServerConfiguration(
                serverURL: serverURL,
                username: username,
                password: password
            ),
            transport: transport
        )
    }

    // MARK: - Capabilities

    /// Fetches and caches the server's capabilities.
    ///
    /// Calls `ping` (to obtain base server info) and `getOpenSubsonicExtensions`
    /// (to populate the extensions map). Stores the result in ``serverCapabilities``.
    ///
    /// This method is idempotent: calling it again refreshes the cached value.
    ///
    /// ```swift
    /// try await client.fetchCapabilities()
    /// if client.serverCapabilities?.supports("songLyrics") == true {
    ///     // ...
    /// }
    /// ```
    public func fetchCapabilities() async throws {
        // ping gives us the base envelope fields (version, type, openSubsonic flag)
        let pingEnvelope = try await performRaw(endpoint: "ping", params: [:])

        // getOpenSubsonicExtensions gives us the extensions map
        // This endpoint is publicly accessible (no auth required by spec),
        // but we include auth anyway for consistency.
        var extensionMap: [String: [Int]] = [:]
        if pingEnvelope.isOpenSubsonic == true {
            let extEnvelope: SubsonicEnvelope<OpenSubsonicExtensionsPayload> =
                try await performDecode(endpoint: "getOpenSubsonicExtensions", params: [:])
            let list = extEnvelope.payload?.openSubsonicExtensions ?? []
            extensionMap = Dictionary(uniqueKeysWithValues: list.map { ($0.name, $0.versions) })
        }

        serverCapabilities = ServerCapabilities(
            apiVersion: pingEnvelope.version,
            isOpenSubsonic: pingEnvelope.isOpenSubsonic ?? false,
            serverType: pingEnvelope.serverType,
            serverVersion: pingEnvelope.serverVersion,
            extensions: extensionMap
        )

        logger.debug("Capabilities loaded: version=\(pingEnvelope.version) openSubsonic=\(pingEnvelope.isOpenSubsonic ?? false)")
    }

    // MARK: - Internal helpers

    /// Decodes a typed payload from the Subsonic envelope, with automatic retry.
    ///
    /// Validates HTTP status, checks the Subsonic `status` field, and throws
    /// ``SwiftSonicError`` on any failure. Transient errors are retried according
    /// to the configured ``RetryPolicy``.
    func performDecode<P: SubsonicPayload>(
        endpoint: String,
        params: [String: String],
        multiParams: [String: [String]] = [:]
    ) async throws -> SubsonicEnvelope<P> {
        var attempt = 0

        while true {
            let startTime = Date()
            metricsCollector?.record(.started(endpoint: endpoint, attempt: attempt))
            logger.debug("→ \(endpoint) attempt \(attempt + 1)/\(self.retryPolicy.maxAttempts)")

            do {
                let envelope: SubsonicEnvelope<P> = try await executeOnce(
                    endpoint: endpoint, params: params, multiParams: multiParams
                )
                let duration = Date().timeIntervalSince(startTime)
                metricsCollector?.record(.succeeded(endpoint: endpoint, attempt: attempt, duration: duration))
                logger.debug("✓ \(endpoint) succeeded in \(duration, format: .fixed(precision: 3))s")
                return envelope

            } catch {
                let duration = Date().timeIntervalSince(startTime)
                let swiftSonicError = error as? SwiftSonicError

                if let sse = swiftSonicError {
                    metricsCollector?.record(.failed(endpoint: endpoint, attempt: attempt, error: sse, duration: duration))
                }

                let isRetryable = swiftSonicError?.isTransient ?? false
                let hasAttemptsLeft = attempt + 1 < retryPolicy.maxAttempts

                guard isRetryable && hasAttemptsLeft else {
                    logger.debug("✗ \(endpoint) failed on attempt \(attempt + 1)")
                    throw error
                }

                let delay = swiftSonicError?.suggestedRetryDelay
                    ?? retryPolicy.delay(for: attempt)
                metricsCollector?.record(.retryScheduled(endpoint: endpoint, attempt: attempt, delay: delay))
                logger.debug("↻ \(endpoint) retry \(attempt + 2)/\(self.retryPolicy.maxAttempts) in \(delay, format: .fixed(precision: 2))s")

                // Task.sleep propagates CancellationError — cancellation stops retry immediately.
                try await Task.sleep(for: .seconds(delay))
                attempt += 1
            }
        }
    }

    /// Performs a request for endpoints with no payload (ping, star, etc.).
    @discardableResult
    func performVoid(
        endpoint: String,
        params: [String: String] = [:],
        multiParams: [String: [String]] = [:]
    ) async throws -> SubsonicEnvelope<EmptyPayload> {
        try await performDecode(endpoint: endpoint, params: params, multiParams: multiParams)
    }

    /// Returns the raw envelope (used by fetchCapabilities to read top-level fields).
    private func performRaw(
        endpoint: String,
        params: [String: String]
    ) async throws -> SubsonicEnvelope<EmptyPayload> {
        try await performDecode(endpoint: endpoint, params: params, multiParams: [:])
    }

    // MARK: - Single-attempt execution

    /// Executes a single network attempt without any retry logic.
    private func executeOnce<P: SubsonicPayload>(
        endpoint: String,
        params: [String: String],
        multiParams: [String: [String]]
    ) async throws -> SubsonicEnvelope<P> {
        var request = try requestBuilder.request(
            endpoint: endpoint, params: params, multiParams: multiParams
        )
        // Defence-in-depth: apply request timeout directly on the URLRequest so that
        // custom HTTPTransport implementations also honour the configured value.
        request.timeoutInterval = configuration.requestTimeout

        let (data, httpResponse): (Data, HTTPURLResponse)
        do {
            (data, httpResponse) = try await transport.data(for: request)
        } catch let urlError as URLError {
            throw SwiftSonicError.network(urlError)
        }

        // Handle rate limiting before the generic status check.
        if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            throw SwiftSonicError.rateLimited(
                retryAfter: retryAfter,
                requestURL: request.url ?? configuration.serverURL
            )
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw SwiftSonicError.httpError(
                statusCode: httpResponse.statusCode,
                requestURL: request.url ?? configuration.serverURL
            )
        }

        let envelope: SubsonicEnvelope<P>
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            envelope = try decoder.decode(SubsonicEnvelope<P>.self, from: data)
        } catch let decodingError as DecodingError {
            throw SwiftSonicError.decoding(decodingError, rawData: data)
        }

        if envelope.status == .failed, let rawError = envelope.error {
            throw SwiftSonicError.api(SubsonicAPIError(
                code: SubsonicErrorCode(rawValue: rawError.code) ?? .unknown,
                message: rawError.message,
                helpURL: rawError.helpUrl.flatMap { URL(string: $0) },
                requestURL: request.url ?? configuration.serverURL
            ))
        }

        return envelope
    }
}
