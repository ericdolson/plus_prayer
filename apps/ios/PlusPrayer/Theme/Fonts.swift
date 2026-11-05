import CoreText
import Foundation
import OSLog

/// Registers the bundled display serif (Roca) at launch, so adding a face
/// never needs an Info.plist edit. Body text is the system font; nothing to
/// register for it.
nonisolated enum PPFonts {
    private static let log = Logger(subsystem: "dev.hammock.plusprayer", category: "fonts")

    /// Call once, before the first view renders.
    static func register(bundle: Bundle = .main) {
        let urls = bundle.urls(forResourcesWithExtension: "otf", subdirectory: nil) ?? []
        for url in urls {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                // Already registered (previews re-run this) is fine; anything else is a bug.
                let message = error?.takeRetainedValue().localizedDescription ?? "unknown"
                log.error("Couldn't register \(url.lastPathComponent, privacy: .public): \(message, privacy: .public)")
            }
        }
    }
}
