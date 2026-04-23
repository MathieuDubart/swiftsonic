// ServerConfiguration+Test.swift — SwiftSonicTests
//
// Provides a pre-built ServerConfiguration for use in unit tests.
// All tests that need a client should use .test to keep setup boilerplate minimal.

import Foundation
@testable import SwiftSonic

extension ServerConfiguration {
    /// A ready-to-use test configuration pointing at a local mock server.
    static let test = ServerConfiguration(
        serverURL: URL(string: "https://test.example.com")!,
        username: "testuser",
        password: "testpassword"
    )
}
