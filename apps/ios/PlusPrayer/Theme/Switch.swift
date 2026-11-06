import SwiftUI

extension Toggle {
    /// Every switch in the app (design-direction §1): neutral, never blue.
    /// The "on" track is `switchTrackOn` (inkMuted, no brighter) with the
    /// standard white knob, in both themes.
    ///
    /// iOS keeps the native switch (drag, the glass knob, future system
    /// changes), so the off track is the system's: `switchTrackOff` is
    /// Android-only. No custom-drawn switch (decided 2026-11-06).
    func ppSwitch() -> some View {
        tint(PP.color.switchTrackOn)
    }
}
