import Foundation
import OSLog

/// Which backend the app runs against, chosen once at launch from the
/// launch argument `-PPEnvironment mock|emulator|firebase` (apps/ios/CLAUDE.md,
/// "Mock backend and environments"). Debug defaults to mock; previews and
/// tests always use mock.
///
/// The emulator environment reaches the Mac running the emulators at
/// `-PPEmulatorHost <Mac's LAN address>` (a phone on the same Wi-Fi), else
/// localhost (the simulator). A choice passed as a launch argument is
/// remembered on the device, so the app opened later from the Home Screen
/// stays on it; launch once with `-PPEnvironment mock` to go back. Under
/// XCTest only an explicit argument counts.
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
    /// When the scene becomes active: send what's queued, re-read.
    var onActive: @MainActor () async -> Void = {}

    static let environmentKey = "PPEnvironment"
    static let emulatorHostKey = "PPEmulatorHost"
    /// The remembered choices (the persistent domain, not the arguments').
    static let savedEnvironmentKey = "PPEnvironment.saved"
    static let savedEmulatorHostKey = "PPEmulatorHost.saved"

    static func mock(_ backend: MockBackend = MockBackend()) -> AppEnvironment {
        AppEnvironment(kind: .mock, repositories: .mock(backend), clock: { backend.now() }, mock: backend)
    }

    /// The real repositories against the local emulators on `host`.
    static func emulator(host: String) -> AppEnvironment {
        let backend = FirebaseBackend(emulatorHost: host)
        let data = RemoteData(backend: backend)
        let prayers = QueuedPrayerRepository(data: data)
        let network = PathNetworkRepository()
        network.onReconnect {
            await prayers.flush()
            await data.changed()
        }
        let repositories = Repositories(subjects: SQLConnectSubjectRepository(data: data),
                                        lists: FirebaseListRepository(data: data),
                                        user: SQLConnectUserRepository(data: data),
                                        prayers: prayers,
                                        live: RTDBLiveRepository(database: backend.database),
                                        network: network)
        var environment = AppEnvironment(kind: .emulator, repositories: repositories, clock: Date.init, mock: nil)
        environment.onActive = {
            await prayers.flush()
            await data.changed()
        }
        return environment
    }

    /// From the launch arguments (`-key value` lands in UserDefaults'
    /// argument domain), else what this device remembers, else the default.
    static func fromLaunchArguments(_ defaults: UserDefaults = .standard,
                                    processInfo: ProcessInfo = .processInfo) -> AppEnvironment {
        let choice = resolve(defaults, underTests: processInfo.environment["XCTestConfigurationFilePath"] != nil)
        let log = Logger(subsystem: "dev.hammock.plusprayer", category: "environment")
        switch choice.kind {
        case .mock:
            return .mock()
        case .emulator:
            #if !targetEnvironment(simulator)
            if choice.host == "127.0.0.1" {
                log.warning("No -PPEmulatorHost on a device: localhost won't reach the Mac")
            }
            #endif
            return .emulator(host: choice.host)
        case .firebase:
            // Production comes later (build step 4); never from a debug run.
            log.warning("firebase isn't wired yet; running on the mock")
            return .mock()
        }
    }

    /// The kind and emulator host, remembering explicit choices.
    static func resolve(_ defaults: UserDefaults, underTests: Bool) -> (kind: Kind, host: String) {
        let arguments = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
        let argKind = (arguments[environmentKey] as? String).flatMap(Kind.init)
        let argHost = (arguments[emulatorHostKey] as? String)?.trimmingCharacters(in: .whitespaces)
        if !underTests {
            if let argKind { defaults.set(argKind.rawValue, forKey: savedEnvironmentKey) }
            if let argHost, !argHost.isEmpty { defaults.set(argHost, forKey: savedEmulatorHostKey) }
        }
        #if DEBUG
        let fallback = Kind.mock
        #else
        let fallback = Kind.firebase
        #endif
        let saved = underTests ? nil : defaults.string(forKey: savedEnvironmentKey).flatMap(Kind.init)
        let kind = argKind ?? saved ?? fallback
        let savedHost = underTests ? nil : defaults.string(forKey: savedEmulatorHostKey)
        let host = [argHost, savedHost].compactMap { $0 }.first { !$0.isEmpty } ?? "127.0.0.1"
        return (kind, host)
    }
}
