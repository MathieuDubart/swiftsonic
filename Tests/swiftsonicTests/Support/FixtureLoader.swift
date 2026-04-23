// FixtureLoader.swift — SwiftSonicTests
//
// Loads JSON fixture files from Tests/SwiftSonicTests/Fixtures/.
// Fixtures are real API responses captured from demo.navidrome.org.

import Foundation

enum FixtureLoader {
    /// Loads a fixture file by name (without extension) from the Fixtures bundle.
    ///
    /// - Parameter name: The fixture filename without `.json` extension.
    /// - Returns: The raw `Data` contents of the fixture.
    static func load(_ name: String) -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            preconditionFailure("Fixture '\(name).json' not found in test bundle. Add it to Tests/SwiftSonicTests/Fixtures/")
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            preconditionFailure("Could not read fixture '\(name).json': \(error)")
        }
    }

    /// Loads a fixture and returns it as a pretty-printed string (for debugging).
    static func string(_ name: String) -> String {
        String(decoding: load(name), as: UTF8.self)
    }
}
