import SwiftUI

@main
struct PlusPrayerApp: App {
    @State private var home: HomeModel
    @State private var session: PrayerSession

    init() {
        PPFonts.register()
        let environment = AppEnvironment.fromLaunchArguments()
        let home = HomeModel(environment: environment)
        _home = State(initialValue: home)
        _session = State(initialValue: PrayerSession(graph: { home.graph }, clock: environment.clock))
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(home)
                .environment(session)
        }
    }
}
