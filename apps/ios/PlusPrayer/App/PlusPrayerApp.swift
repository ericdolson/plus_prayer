import SwiftUI

@main
struct PlusPrayerApp: App {
    @State private var home: HomeModel
    @State private var session: PrayerSession
    @Environment(\.scenePhase) private var scenePhase
    private let onActive: @MainActor () async -> Void

    init() {
        PPFonts.register()
        let environment = AppEnvironment.fromLaunchArguments()
        let home = HomeModel(environment: environment)
        _home = State(initialValue: home)
        _session = State(initialValue: PrayerSession(graph: { home.graph }, clock: environment.clock))
        onActive = environment.onActive
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(home)
                .environment(session)
        }
        // Back in the foreground: send what's queued, re-read (real backends).
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await onActive() } }
        }
    }
}
