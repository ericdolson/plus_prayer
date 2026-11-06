import Foundation
import OSLog

/// Which backend the app runs against, chosen once at launch from the
/// scheme's launch argument `-PPEnvironment mock|emulator|firebase`
/// (apps/ios/CLAUDE.md, "Mock backend and environments"). Debug defaults to
/// mock; previews and tests always use mock.
@MainActor
struct AppEnvironment {
    enum Kind: String {
        case mock, emulator, firebase
    }

    let kind: Kind
    let repositories: Repositories
    /// "Now" for this environment (the mock's clock can be advanced).
    let clock: () -> Date
    /// The mock backend, for its scenario controls; nil otherwise.
    let mock: MockBackend?

    static func mock(_ backend: MockBackend = MockBackend()) -> AppEnvironment {
        AppEnvironment(kind: .mock, repositories: .mock(backend), clock: { backend.now() }, mock: backend)
    }

    /// From the launch argument (launch arguments of the form `-key value`
    /// land in UserDefaults' argument domain).
    static func fromLaunchArguments(_ defaults: UserDefaults = .standard) -> AppEnvironment {
        #if DEBUG
        let fallback = Kind.mock
        #else
        let fallback = Kind.firebase
        #endif
        let requested = defaults.string(forKey: "PPEnvironment").flatMap(Kind.init) ?? fallback
        switch requested {
        case .mock:
            return .mock()
        case .emulator, .firebase:
            // The real repositories come with build step 4 (app-brief §6).
            Logger(subsystem: "dev.hammock.plusprayer", category: "environment")
                .warning("\(requested.rawValue, privacy: .public) isn't built yet; running on the mock")
            return .mock()
        }
    }
}
