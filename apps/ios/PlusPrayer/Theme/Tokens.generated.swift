// GENERATED from design/tokens.json by design/generate/index.mjs. Do not edit.
// Regenerate: node design/generate/index.mjs
//
// Views read these semantic names only (apps/ios/CLAUDE.md, "Theming").

import SwiftUI
import UIKit

nonisolated enum PP {
    /// Color roles (design-direction §1): blue = do this, gold = held, everything else neutral.
    /// Every color is dynamic: one value per theme, resolved by the trait collection.
    enum color {
        /// The screen's ground (scaffold).
        static let ground = Color(light: 0xE9EEF9, dark: 0x0E1012)
        /// Custom (Tier A) overlays only, e.g. the Amen invitation if it isn't a native sheet: a slight lift from the ground (1.08:1). Native sheets use the platform material.
        static let sheet = Color(light: 0xE9EEF9, dark: 0x16191D)
        /// The community card and other in-content containers (1.13:1 step).
        static let cardSurface = Color(light: 0xF5F7FD, dark: 0x1A1D21)
        /// Fields, pills, settings groups on a sheet.
        static let raised = Color(light: 0xF5F7FD, dark: 0x23272D)
        /// One step above raised.
        static let raisedHigh = Color(light: 0xFFFFFF, dark: 0x2E333A)
        /// The avatar cluster's "+N" disc.
        static let clusterOverflow = Color(light: 0xD3DAE8, dark: 0x2E333A)
        /// Hairline edges (glass rims).
        static let hairline = Color(light: 0xD3DAE8, dark: 0x2A2E35)
        /// The intention thread. Neutral always; never changes color or weight.
        static let thread = Color(light: 0xC3CCDD, dark: 0x3A3F47)
        /// 15.8:1 on ground.
        static let ink = Color(light: 0x05294A, dark: 0xE8EAED)
        /// Secondary text. 7.1:1 on ground, ≥5.6:1 on every surface.
        static let inkMuted = Color(light: 0x566D83, dark: 0x9A9EA4)
        /// Intentions on Home, ~7:1 (8.5:1 on ground).
        static let inkIntention = Color(light: 0x3A5169, dark: 0xA9ADB3)
        /// Decorative only, never essential text.
        static let inkFaint = Color(light: 0x8A9BB0, dark: 0x6C7076)
        /// The carried mark. Below 3:1 on purpose (design-direction §5).
        static let carriedMark = Color(light: 0xA6B4C6, dark: 0x53585E)
        /// A switch's "on" track: inkMuted, no brighter, with the standard white knob (design-direction §1, app-wide).
        static let switchTrackOn = Color(light: 0x566D83, dark: 0x9A9EA4)
        /// A switch's "off" track: ink at ~14%, a faint groove, so on and off differ by fill. Android only: iOS keeps the native switch, whose off track is the system's (design-direction §1).
        static let switchTrackOff = Color(light: 0x05294A, dark: 0xE8EAED, lightAlpha: 0.14, darkAlpha: 0.14)
        /// Blue = do this: pray button, Amen, the invitation's tap target, primary buttons. Never status or decoration.
        static let primary = Color(light: 0x0573E0, dark: 0x0580F9)
        /// 3.8:1: glyphs and large/bold text only.
        static let onPrimary = Color(light: 0xFFFFFF, dark: 0xFFFFFF)
        /// Gold = held: rings, intention dots, card border, halo. Non-text (≥3:1).
        static let heldGold = Color(light: 0x9A7A30, dark: 0xC8AE6E)
        /// "Answered · {date}" (≥4.5:1).
        static let heldGoldText = Color(light: 0x765A1C, dark: 0xC8AE6E)
        /// Dark only (light has none): the prayer halo and the brief check bloom. Never a static glow.
        /// Dark theme only; clear in light.
        static let heldGlow = Color(dark: 0xC8AE6E, darkAlpha: 0.35)
        /// The check glyph on a gold check.
        static let onHeld = Color(light: 0xFFFFFF, dark: 0x0E1012)
        /// The prayer-mode screen halo.
        static let halo = Color(light: 0x9A7A30, dark: 0xC8AE6E)
        /// Behind custom (Tier A) overlays only; native sheets bring their own dimming.
        static let scrim = Color(light: 0x05294A, dark: 0x000000, lightAlpha: 0.4, darkAlpha: 0.75)
        /// The unsealed seal: the same shape, unpressed, neutral (before the list is published).
        static let unsealed = Color(light: 0xC9D1DF, dark: 0x30353D)
        /// Dark only: the unsealed blank's rim light (at wax.darkRimOpacity).
        /// Dark theme only; clear in light.
        static let unsealedRim = Color(dark: 0x6C7076, darkAlpha: 1)
        /// Initials on an avatar tone: white at 70% (0xB3), so the letters lightly take on the tone (design-direction §1b). Vermilion and olive fall to 2.6–2.9:1 at this opacity.
        static let onAvatar = Color(light: 0xFFFFFF, dark: 0xFFFFFF, lightAlpha: 0.702, darkAlpha: 0.702)
        /// Wax shading and contact shadows.
        static let shadow = Color(light: 0x000000, dark: 0x000000)

        /// Monogram tones by PrayerSubject.avatarTone (0–15; default = FNV-1a(subject id) mod 16). Same palette in both themes; dark blends each tone avatarDarkDim toward black. FROZEN AT LAUNCH: changing an index recolors everyone's people.
        static let avatarTones: [Color] = [
            Color(light: 0x3949AB, dark: 0x3645A1), // 0 indigo
            Color(light: 0x6D4C41, dark: 0x66473D), // 1 cocoa
            Color(light: 0x8E24AA, dark: 0x8522A0), // 2 purple
            Color(light: 0x1E6B3A, dark: 0x1C6537), // 3 forest
            Color(light: 0xE64A19, dark: 0xD84618), // 4 vermilion
            Color(light: 0x546E7A, dark: 0x4F6773), // 5 slate
            Color(light: 0xAD1F8C, dark: 0xA31D84), // 6 fuchsia
            Color(light: 0x00838F, dark: 0x007B86), // 7 cyan
            Color(light: 0xD81B60, dark: 0xCB195A), // 8 raspberry
            Color(light: 0x0277BD, dark: 0x0270B2), // 9 ocean
            Color(light: 0xA0522D, dark: 0x964D2A), // 10 sienna
            Color(light: 0x00876A, dark: 0x007F64), // 11 teal
            Color(light: 0x9C1450, dark: 0x93134B), // 12 berry
            Color(light: 0x5F9133, dark: 0x598830), // 13 olive
            Color(light: 0x5E35B1, dark: 0x5832A6), // 14 violet
            Color(light: 0x2E7D32, dark: 0x2B762F), // 15 green
        ]

        /// Wax by PrayerList.sealVariant (0 = Sunday … 6 = Saturday), the ritual's 7-day rotation. base = the wax body; sheen = its highlight (the stamp's relief maps face → base, highlights → sheen).
        enum wax {
            /// The wax itself, by sealVariant.
            static let base: [Color] = [
                Color(light: 0xA9822F, dark: 0xA9822F), // 0 — Royal Gold
                Color(light: 0x1E2C4A, dark: 0x1E2C4A), // 1 — Navy Blue
                Color(light: 0x6E1B20, dark: 0x6E1B20), // 2 — Deep Red
                Color(light: 0x4F1C3A, dark: 0x4F1C3A), // 3 — Metallic Garnet Purple
                Color(light: 0x1C4330, dark: 0x1C4330), // 4 — Deep Green
                Color(light: 0x7F6A3C, dark: 0x7F6A3C), // 5 — Antique Brass
                Color(light: 0x55382A, dark: 0x55382A), // 6 — Brown
            ]
            /// Its highlight: the stamp's relief maps face → base, highlights → sheen.
            static let sheen: [Color] = [
                Color(light: 0xE2C46E, dark: 0xE2C46E), // 0 — Royal Gold
                Color(light: 0x4A5F8A, dark: 0x4A5F8A), // 1 — Navy Blue
                Color(light: 0xA8454B, dark: 0xA8454B), // 2 — Deep Red
                Color(light: 0x8E4A74, dark: 0x8E4A74), // 3 — Metallic Garnet Purple
                Color(light: 0x4E8063, dark: 0x4E8063), // 4 — Deep Green
                Color(light: 0xC2A86A, dark: 0xC2A86A), // 5 — Antique Brass
                Color(light: 0x8C654E, dark: 0x8C654E), // 6 — Brown
            ]
            /// The seal's body: the wax, lifted toward its sheen in dark theme where it needs it.
            static let body: [Color] = [
                Color(light: 0xA9822F, dark: 0xA9822F), // 0 — Royal Gold
                Color(light: 0x1E2C4A, dark: 0x273657), // 1 — Navy Blue
                Color(light: 0x6E1B20, dark: 0x7A2329), // 2 — Deep Red
                Color(light: 0x4F1C3A, dark: 0x5C2546), // 3 — Metallic Garnet Purple
                Color(light: 0x1C4330, dark: 0x264F3A), // 4 — Deep Green
                Color(light: 0x7F6A3C, dark: 0x7F6A3C), // 5 — Antique Brass
                Color(light: 0x55382A, dark: 0x604131), // 6 — Brown
            ]
            /// Dark theme only (clear in light): the rim light along the seal's edge.
            static let rim: [Color] = [
                Color(dark: 0xE2C46E, darkAlpha: 0.5), // 0 — Royal Gold
                Color(dark: 0x4A5F8A, darkAlpha: 0.5), // 1 — Navy Blue
                Color(dark: 0xA8454B, darkAlpha: 0.5), // 2 — Deep Red
                Color(dark: 0x8E4A74, darkAlpha: 0.5), // 3 — Metallic Garnet Purple
                Color(dark: 0x4E8063, darkAlpha: 0.5), // 4 — Deep Green
                Color(dark: 0xC2A86A, darkAlpha: 0.5), // 5 — Antique Brass
                Color(dark: 0x8C654E, darkAlpha: 0.5), // 6 — Brown
            ]
        }
    }

    enum space {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        /// Side margins on Home; text inset inside the community card.
        static let gutter: CGFloat = 20
        /// Card padding (top = bottom).
        static let inset: CGFloat = 20
        /// The visible gap between one name group and the next (~24–28): the last row's ink to the next avatar. The list subtracts the rows' own insets.
        static let groupGap: CGFloat = 24
        /// Community card to the first row.
        static let cardToList: CGFloat = 24
        /// The card's status line under its avatar row (~6–8).
        static let statusUnderAvatars: CGFloat = 8
    }

    enum radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 24
        /// The community card (~20–24).
        static let card: CGFloat = 22
        /// Small in-content containers (the search match hint): softer than a capsule, never reads as a field or pill.
        static let hint: CGFloat = 16
    }

    enum size {
        enum avatar {
            /// Name-row avatar. Also the add sheet's new-person avatar in its Name-tab toolbar (as tall as the round X) and the person header of its intention form for a known person (screens.md).
            static let row: CGFloat = 44
            /// Your avatar in Home's header: smaller so it doesn't compete.
            static let header: CGFloat = 32
            /// The profile at the top of You.
            static let large: CGFloat = 72
            /// A person at full size, how people recognize someone: the add sheet's Name tab and the subject's page (screens.md, detail-page.md).
            static let person: CGFloat = 96
            /// The add sheet's For row and the rows of "Who is this for?" (screens.md).
            static let picker: CGFloat = 40
            static let small: CGFloat = 28
            static let tiny: CGFloat = 20
            /// Below this, two initials drop to one; a disc too small for one is color only.
            static let initialsMinGlyph: CGFloat = 11
        }
        enum row {
            /// Name row: the avatar plus its held ring's room. One line.
            static let name: CGFloat = 52
            /// Intention row pitch; all of it is tap target.
            static let intention: CGFloat = 40
        }
        enum held {
            /// Held ring stroke. Crisp, solid, no glow.
            static let ring: CGFloat = 2
            /// Gap between the avatar (or card) and its held ring.
            static let ringGap: CGFloat = 2
            /// The gold dot where the thread meets a held intention.
            static let dot: CGFloat = 5
        }
        enum thread {
            static let stroke: CGFloat = 1
            /// The bend into each intention (≤ half the row or the branch's length).
            static let radius: CGFloat = 12
        }
        /// The prayer-mode check in a row's trailing slot.
        static let check: CGFloat = 24
        enum carriedMark {
            /// After a Roca name; scales with the text.
            static let name: CGFloat = 11
            static let nameGap: CGFloat = 6
            /// After a 13 pt intention; scales with the text.
            static let intention: CGFloat = 9
            static let intentionGap: CGFloat = 4
            /// Trailing the add sheet's "Carry onto the list" label at the label's size, inkMuted in every state (design-direction §5), centered on the label's cap height. Scales with the label.
            static let carryRow: CGFloat = 15
        }
        enum card {
            /// The day's seal, cropped into the card's top-left corner (~70% visible).
            static let stamp: CGFloat = 110
            /// How far the stamp sits left of the card's edge. Tune by outcome (bloom center + most petals visible).
            static let stampOffsetX: CGFloat = 23
            /// How far the stamp sits above the card's edge.
            static let stampOffsetY: CGFloat = 15
            /// The card's avatar row.
            static let avatar: CGFloat = 28
            /// ≤ ~4–5 so two-letter initials are never covered.
            static let avatarOverlap: CGFloat = 4
            /// The dot before "N praying now".
            static let liveDot: CGFloat = 6
        }
        enum cluster {
            /// Avatar clusters outside the card (Today's list, Your portion).
            static let avatar: CGFloat = 24
            /// The Amen invitation's cluster.
            static let avatarLarge: CGFloat = 32
            /// How far each cluster avatar overlaps the one before it: as on the card (size.card.avatarOverlap), ≤ ~4–5 so two-letter initials are never covered.
            static let overlap: CGFloat = 4
        }
        enum seal {
            static let `default`: CGFloat = 44
            /// The day's seal at the top of the Amen invitation (Flutter's 1.3 × the default).
            static let invitation: CGFloat = 56
            /// The streak badge's pewter seal.
            static let badge: CGFloat = 22
            /// Dark-theme rim light.
            static let rimWidth: CGFloat = 1
            /// Seals smaller than this (beads) get the lift but no rim.
            static let rimMinSize: CGFloat = 24
            /// At and above this, seals use the photographed stamps (when D3 lands).
            static let photoMinSize: CGFloat = 40
        }
        enum bead {
            /// Bead strand: ≤ 7 wax beads (~12–14).
            static let diameter: CGFloat = 13
            /// A break (lists missed) is one pitch of bare space.
            static let pitch: CGFloat = 22
            /// The current list's bead while unsealed: a hollow ring.
            static let hollowStroke: CGFloat = 1.5
        }
        enum prayButton {
            /// Home's round pray button, the same height as the floating pill (size.bar.compact while the keyboard is up).
            static let diameter: CGFloat = 62
            /// The Amen invitation's button.
            static let invitation: CGFloat = 85
        }
        enum halo {
            /// The halo's stroke at rest.
            static let glowWidth: CGFloat = 6
            /// The solid gold line on the screen's edge, under the glow. Steady: only the glow breathes.
            static let edge: CGFloat = 2
            /// At rest the visible glow stays within this distance of the screen edge.
            static let maxInwardReach: CGFloat = 12
        }
        /// Home's floating bar (design-direction §4; Tier A layout on the platform's glass, 2026-11-05).
        enum bar {
            /// The pill's height: the same as the round pray button beside it.
            static let height: CGFloat = 62
            /// History, Search and + in the pill.
            static let icon: CGFloat = 26
            /// The bar's gap from the screen's side edges.
            static let inset: CGFloat = 16
            /// Between the pill and the pray button.
            static let gap: CGFloat = 12
            /// The pill and the pray button while the keyboard is up (search): both shrink a little and ride above it.
            static let compact: CGFloat = 52
        }
        /// Home's header controls, each on its own glass (§4).
        enum header {
            /// The glass behind the streak badge and the filter: as tall as your header avatar.
            static let control: CGFloat = 32
            /// The filter glyph and the chip's ×.
            static let icon: CGFloat = 20
        }
        /// The prayer-mode check's strokes (size.check is its diameter).
        enum checkMark {
            /// Unchecked: a thin inkMuted ring.
            static let noneStroke: CGFloat = 1
            /// Partial: the gold ring and its dash.
            static let partialStroke: CGFloat = 1.5
        }
        enum hint {
            /// The search match hint's minimum height (a comfortable tap target).
            static let minHeight: CGFloat = 48
        }
    }

    enum number {
        /// Dark theme only: the seal's rim light (its sheen; the unsealed blank uses color.dark.unsealedRim) at this opacity.
        static let waxDarkRimOpacity: Double = 0.5
        /// Ink over an in-content container (the search match hint) while pressed.
        static let pressed: Double = 0.08
        /// Avatar initials: body sans at this share of the disc's diameter.
        static let initialsScale: Double = 0.4
        /// Overlapping cluster avatars: a ring in the surface's color, this share of the avatar's diameter.
        static let clusterSeparator: Double = 0.07
        /// Two-letter initials tracked apart by this share of their size.
        static let initialsTracking: Double = 0.04
        /// Prayer-mode halo (design-direction §7).
        enum halo {
            /// The glow's breath, low opacity at rest (the edge line holds steady).
            static let restLow: Double = 0.4
            /// The glow's breath, high opacity at rest.
            static let restHigh: Double = 1
            /// Reduce Motion: the glow is static at this opacity (mid-breath), no breath, no flare.
            static let reduceMotion: Double = 0.7
            /// The committing Amen's flare peak opacity (0.99 is fine).
            static let flarePeak: Double = 1
            /// The flare's reach, × the resting reach.
            static let flareReach: Double = 1.3
            /// Light theme widens the glow so it doesn't vanish on the pale ground.
            static let lightWidthScale: Double = 1.2
        }
        /// The check bloom: share of its duration spent swelling (ease-out); the rest settles (ease-in).
        static let bloomRiseShare: Double = 0.35
        /// The check glyph inside a held check, as a share of its diameter.
        static let checkGlyph: Double = 0.62
        /// The partial check's dash, as a share of its diameter.
        static let checkDash: Double = 0.4
        /// The held check springs in from this scale (Reduce Motion: no scale, a fade).
        static let checkSpringFrom: Double = 0.4
        /// During the countdown the pray button's disc is the action blue at this opacity (over raised); solid once Amen is available.
        static let prayButtonDim: Double = 0.3
        /// A name shown only as the parent of an intention the filter keeps (design-direction §4: a held name with an unheld intention under Still to hold) is dimmed to this opacity; the intention stays full strength. Flutter's tuned value.
        static let contextRow: Double = 0.55
        /// The countdown before Amen: a small pie inside the button, this share of its diameter, running down to nothing (no ring outside, no change in size).
        static let countdownPie: Double = 0.4
    }

    enum type {
        /// Onboarding lines, the welcome-back question.
        static let displayLarge = Font.custom("Roca-Bold", size: 30, relativeTo: .largeTitle)
        /// A name as a page title (You, detail pages).
        static let displayTitle = Font.custom("Roca-Bold", size: 26, relativeTo: .title)
        /// Big lines: the invitation, "You'll be carried on List 53".
        static let displayLine = Font.custom("Roca-Regular", size: 22, relativeTo: .title2)
        /// Names on Home and "List 52".
        static let name = Font.custom("Roca-Bold", size: 19, relativeTo: .title3)
        /// Intentions on Home: smaller sans, regular, ~7:1.
        static let intention = Font.system(.footnote, weight: .regular)
        /// "Answered · {date}": never larger than its intention.
        static let answered = Font.system(.footnote, weight: .regular)
        /// Body text; the search empty-state line.
        static let body = Font.system(.body, weight: .regular)
        /// Card counts and status lines, secondary body.
        static let bodySmall = Font.system(.subheadline, weight: .regular)
        /// Secondary lines, captions.
        static let caption = Font.system(.footnote, weight: .regular)
        /// Button labels.
        static let label = Font.system(.subheadline, weight: .semibold)
        /// Small labels, hints.
        static let labelSmall = Font.system(.footnote, weight: .medium)
        /// Timer and counts: tabular figures. When a count rises live, crossfade only the changed digits.
        static let count = Font.system(.subheadline, weight: .medium).monospacedDigit()
        /// Avatar initials: body sans, not the serif. Size = number.initialsScale × the disc (17.6 at 44); tracking number.initialsTracking on two letters; optically centered. Does not scale with Dynamic Type (it tracks the disc).
        static func initials(size: CGFloat) -> Font { .system(size: size, weight: .semibold) }
    }

    /// Durations in seconds.
    enum duration {
        /// Quick fades; Reduce Motion's replacement for springs and blooms.
        static let quick: TimeInterval = 0.16
        /// Ordinary transitions (check fades in, filters).
        static let settle: TimeInterval = 0.32
        static let calm: TimeInterval = 0.7
        /// The check's spring, the only spring in the app: this duration on easing.outBack (a small overshoot).
        static let spring: TimeInterval = 0.42
        /// The gold bloom on check, settling into the crisp ring.
        static let bloom: TimeInterval = 0.36
        /// Under Still to hold, held rows stay this long after Amen …
        static let linger: TimeInterval = 1.2
        /// … then fold away over this (Reduce Motion: fade).
        static let fold: TimeInterval = 0.48
        /// Praying on a detail page: what isn't the subject fades out together.
        static let strip: TimeInterval = 0.25
        /// The add sheet's contact-info message shows this long after typing pauses (screens.md, add sheet).
        static let validationPause: TimeInterval = 0.5
        /// The halo fades in/out.
        static let haloFade: TimeInterval = 0.4
        /// Half of the halo glow's breath (a full in-and-out cycle is 5 s).
        static let haloBreath: TimeInterval = 2.5
        /// The committing Amen's flare, before the fade-out.
        static let haloFlare: TimeInterval = 0.5
        /// The flare's fast rise (ease-out); the rest settles (ease-in-out).
        static let haloFlareRise: TimeInterval = 0.15
        /// From the Amen tap to the flare. Becomes the time to the seal's impact once the stamp animation exists.
        static let haloFlareOffset: TimeInterval = 0
        /// The pray button's decaying ring before Amen appears; the invitation's ring.
        static let prayHold: TimeInterval = 5
    }

    enum easing {
        /// Ease-out: rises, swells.
        static func out(_ duration: TimeInterval) -> Animation { .timingCurve(0, 0, 0.58, 1, duration: duration) }
        /// The check's spring (Flutter's Curves.easeOutBack). The only overshoot in the app.
        static func outBack(_ duration: TimeInterval) -> Animation { .timingCurve(0.175, 0.885, 0.32, 1.275, duration: duration) }
        /// Ease-in-out: settles.
        static func inOut(_ duration: TimeInterval) -> Animation { .timingCurve(0.42, 0, 0.58, 1, duration: duration) }
        /// Ease-in: the bloom's settle, exits.
        static func `in`(_ duration: TimeInterval) -> Animation { .timingCurve(0.42, 0, 1, 1, duration: duration) }
    }
}

nonisolated extension Color {
    /// One color per theme, resolved from the trait collection.
    init(light: UInt32, dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(rgb: dark, alpha: darkAlpha)
                : UIColor(rgb: light, alpha: lightAlpha)
        })
    }

    /// Dark theme only; clear in light.
    init(dark: UInt32, darkAlpha: Double = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(rgb: dark, alpha: darkAlpha) : .clear
        })
    }
}

nonisolated private extension UIColor {
    convenience init(rgb: UInt32, alpha: Double) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: alpha
        )
    }
}
