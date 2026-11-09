import FirebaseAnalytics
import FirebaseAuth
import FirebaseCore
import FirebaseCrashlytics
import FirebaseDatabase
import FirebaseDataConnect
import FirebaseFunctions
import Foundation
import OSLog
import PlusPrayerConnector

/// The Firebase SDKs one environment talks to, configured once at launch,
/// and the signed-in (anonymous-first) user. The real repositories
/// (Data/SQLConnect, Data/RTDB, Data/Queue) share it.
///
/// Only the **emulator** environment exists so far: a `demo-` project the
/// SDKs never connect to production for, with every service pointed at the
/// Mac running `npm run emulators` (backend/CLAUDE.md, "Test on your phone
/// with the emulators"). Production (`firebase`) is wired in later
/// (TODO(build step 4): production options from GoogleService-Info.plist).
@MainActor
final class FirebaseBackend {
    /// The emulators' project (backend/functions/scripts/emulators.sh).
    static let emulatorProjectId = "demo-plusprayer"
    static let region = "us-central1"

    let auth: Auth
    let functions: Functions
    let database: Database
    let connector: PlusprayerConnector
    let host: String
    private let log = Logger(subsystem: "dev.hammock.plusprayer", category: "firebase")

    /// Sign-in is anonymous and silent (auth-onboarding.md). Shared so every
    /// repository waits on the same one.
    private var signIn: Task<String, Error>?

    /// Configures Firebase for the emulators on `host` (the Mac's LAN address
    /// on a phone; localhost on the simulator). Call once, before anything
    /// else touches Firebase.
    init(emulatorHost host: String) {
        self.host = host
        // Placeholder values with the right shapes (no real project): the
        // SDKs validate the formats, the emulators accept anything.
        let options = FirebaseOptions(googleAppID: "1:000000000000:ios:0000000000000000000000",
                                      gcmSenderID: "000000000000")
        options.projectID = Self.emulatorProjectId
        options.apiKey = "AIzaSyDemoKeyForTheLocalEmulators000000" // 39 characters, as Installations checks
        options.bundleID = Bundle.main.bundleIdentifier ?? "dev.hammock.plusprayer"
        options.databaseURL = "https://\(Self.emulatorProjectId)-default-rtdb.firebaseio.com"
        if FirebaseApp.app() == nil { FirebaseApp.configure(options: options) }
        Analytics.setAnalyticsCollectionEnabled(false)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)

        auth = Auth.auth()
        auth.useEmulator(withHost: host, port: 9099)
        functions = Functions.functions(region: Self.region)
        functions.useEmulator(withHost: host, port: 5001)
        database = Database.database()
        // The draft and live nodes keep working offline (apps/ios/CLAUDE.md).
        database.isPersistenceEnabled = true
        database.useEmulator(withHost: host, port: 9000)
        connector = DataConnect.plusprayerConnector
        connector.useEmulator(host: host, port: 9399)
        log.info("Firebase emulators at \(host, privacy: .public) (\(Self.emulatorProjectId, privacy: .public))")
    }

    /// The signed-in uid, signing in anonymously first if needed. A cached
    /// user the emulators no longer know (they were restarted empty) is
    /// signed out and replaced.
    func uid() async throws -> String {
        if let signIn { return try await signIn.value }
        let task = Task { @MainActor in try await self.signInIfNeeded() }
        signIn = task
        do {
            return try await task.value
        } catch {
            signIn = nil // try again on the next call
            throw error
        }
    }

    private func signInIfNeeded() async throws -> String {
        if let user = auth.currentUser {
            do {
                _ = try await user.getIDToken()
                return user.uid
            } catch let error as NSError where Self.isGoneUser(error) {
                log.notice("Cached user is gone from the emulators; signing in again")
                try? auth.signOut()
            }
        }
        let result = try await auth.signInAnonymously()
        log.info("Signed in anonymously as \(result.user.uid, privacy: .public)")
        return result.user.uid
    }

    private static func isGoneUser(_ error: NSError) -> Bool {
        guard error.domain == AuthErrorDomain, let code = AuthErrorCode(rawValue: error.code) else { return false }
        return [.userNotFound, .userTokenExpired, .invalidUserToken, .userDisabled].contains(code)
    }

    // MARK: Callables

    /// Calls a user callable (backend/functions/src/index.ts) after sign-in.
    /// Returns its JSON result. Throws `CallableError`.
    func call(_ name: String, _ data: sending [String: Any]) async throws(CallableError) -> [String: Any] {
        do {
            _ = try await uid()
            let result = try await functions.httpsCallable(name).call(data)
            return result.data as? [String: Any] ?? [:]
        } catch {
            throw CallableError(error as NSError) // not signed in (no connection) reads as unreachable
        }
    }
}

/// A callable's failure, from its `HttpsError` code and details
/// (backend/functions/src: `reason`, `field`, …).
struct CallableError: Error {
    let code: FunctionsErrorCode?
    let reason: String?
    let message: String

    init(_ error: NSError) {
        code = error.domain == FunctionsErrorDomain ? FunctionsErrorCode(rawValue: error.code) : nil
        reason = (error.userInfo[FunctionsErrorDetailsKey] as? [String: Any])?["reason"] as? String
        message = error.localizedDescription
    }

    /// No answer from the server (no connection, the emulator down): worth a
    /// retry, and an online-only command says "needs a connection".
    var isUnreachable: Bool {
        code == nil || code == .unavailable || code == .deadlineExceeded
    }

    /// The server looked at the request and said no; resending won't change it.
    var isPermanent: Bool {
        guard let code else { return false }
        return [.invalidArgument, .failedPrecondition, .notFound, .permissionDenied, .alreadyExists, .outOfRange,
                .resourceExhausted, .unauthenticated].contains(code)
    }
}

/// Ids at the boundary. SQL Connect returns UUIDs (32 hex digits on the
/// wire); the app keeps `UUID.uuidString` (what `PrayerSession` makes, so a
/// prayer's local and server ids match); callables and RTDB use the 32-hex
/// form the functions compare with.
nonisolated enum RemoteID {
    static func string(_ uuid: UUID) -> String { uuid.uuidString }

    /// Accepts either form ("E621E1F8-C36C-…" or "e621e1f8c36c…").
    static func uuid(_ id: String) -> UUID? {
        if let uuid = UUID(uuidString: id) { return uuid }
        let hex = id.replacingOccurrences(of: "-", with: "")
        guard hex.count == 32 else { return nil }
        let chars = Array(hex)
        let parts = [0..<8, 8..<12, 12..<16, 16..<20, 20..<32].map { String(chars[$0]) }
        return UUID(uuidString: parts.joined(separator: "-"))
    }

    /// The 32-hex lowercase form the functions and RTDB use.
    static func wire(_ id: String) -> String {
        (uuid(id)?.uuidString ?? id).replacingOccurrences(of: "-", with: "").lowercased()
    }

    static func same(_ a: String, _ b: String) -> Bool { wire(a) == wire(b) }
}
