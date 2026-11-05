import SwiftUI

@main
struct PlusPrayerApp: App {
    init() {
        PPFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
