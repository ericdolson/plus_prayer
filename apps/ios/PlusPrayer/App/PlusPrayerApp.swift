import SwiftUI

@main
struct PlusPrayerApp: App {
    init() {
        PPFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            // Build step 1: the component gallery until Home exists.
            ComponentGallery()
        }
    }
}
