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
    private let logger: Logger

    // MARK: - Initializers

    /// Creates a client with full control over configuration and transport.
    ///
    /// - Parameters:
    ///   - configuration: Connection and authentication parameters.
    ///   - transport: The HTTP transport to use. Defaults to ``URLSessionTransport``.
    ///   - logSubsystem: If non-nil, enables `os.Logger` output under this subsystem.
    ///     Defaults to `nil` (silent).
    public init(
        configuration: ServerConfiguration,
        transport: (any HTTPTransport)? = nil,
        logSubsystem: String? = nil
    ) {
        self.configuration = configuration
        self.transport = transport ?? URLSessionTransport()
        self.requestBuilder = RequestBuilder(configuration: configuration)
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

    /// Decodes a typed payload from the Subsonic envelope.
    ///
    /// Validates HTTP status, checks the Subsonic `status` field, and throws
    /// ``SwiftSonicError`` on any failure.
    func performDecode<P: SubsonicPayload>(
        endpoint: String,
        params: [String: String]
    ) async throws -> SubsonicEnvelope<P> {
        let request = try requestBuilder.request(endpoint: endpoint, params: params)
        logger.debug("→ \(endpoint) \(params)")

        let (data, httpResponse): (Data, HTTPURLResponse)
        do {
            (data, httpResponse) = try await transport.data(for: request)
        } catch let urlError as URLError {
            throw SwiftSonicError.network(urlError)
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw SwiftSonicError.httpError(
                statusCode: httpResponse.statusCode,
                requestURL: request.url ?? configuration.serverURL
            )
        }

        let envelope: SubsonicEnvelope<P>
        do {
            envelope = try JSONDecoder().decode(SubsonicEnvelope<P>.self, from: data)
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

    /// Performs a request for endpoints with no payload (ping, star, etc.).
    @discardableResult
    func performVoid(endpoint: String, params: [String: String] = [:]) async throws -> SubsonicEnvelope<EmptyPayload> {
        try await performDecode(endpoint: endpoint, params: params)
    }

    /// Returns the raw envelope (used by fetchCapabilities to read top-level fields).
    private func performRaw(
        endpoint: String,
        params: [String: String]
    ) async throws -> SubsonicEnvelope<EmptyPayload> {
        try await performDecode(endpoint: endpoint, params: params)
    }
}
