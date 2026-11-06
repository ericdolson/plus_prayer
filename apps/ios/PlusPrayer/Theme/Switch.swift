import SwiftUI

extension Toggle {
    /// Every switch in the app (design-direction §1): neutral, never blue.
    /// The "on" track is `inkMuted` with the standard white knob, in both
    /// themes (full ink was near-white in dark mode, the brightest thing on
    /// screen).
    func ppSwitch() -> some View {
        tint(PP.color.inkMuted)
    }
}
