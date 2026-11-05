# iOS Phase 0 — for Eric's approval

_2026-11-04. Nothing in the Xcode project or app Swift exists yet. When this is
approved, answered items move into the spec (`docs/product/`,
`docs/decisions.md`) and this file is deleted._

What Phase 0 produced:
- `backend/dataconnect/connector/connector.yaml`: a `swiftSdk` target that
  generates `apps/ios/PlusPrayerConnector/` (committed separately). It builds
  after the Q2 connector renames.
- `design/tokens.json`: the W3C design tokens (DTCG 2025.10).
- `apps/ios/CLAUDE.md`: build conventions.
- This file: the token codegen proposal, the assets plan, and the open questions.

---

## 1. Token codegen (proposal)

**Recommendation: a small, dependency-free Node script in `design/generate/`**
(Node 22 is already required by `backend/functions`):

```
node design/generate/index.mjs            # writes both outputs
node design/generate/index.mjs --check    # CI: fails if outputs are stale
```

1. Read `design/tokens.json`, resolve `{aliases}`, and validate: every alias
   resolves, `color.dark` and `color.light` hold the same roles (except the
   dark-only `heldGlow`, `unsealedRim`), only known `$type`s, avatar tones 0–15
   all present.
2. Emit **Swift**: `apps/ios/PlusPrayer/Theme/Tokens.generated.swift`.
3. Emit **Kotlin** (when Android starts):
   `apps/android/app/src/main/java/dev/hammock/plusprayer/theme/Tokens.kt`.
4. CI: a path-scoped job on `design/**` runs `--check`, so a token edit can't
   land without regenerated code.

Swift output shape (views only see the semantic `PP` names):
```swift
// GENERATED from design/tokens.json by design/generate. Do not edit.
import SwiftUI

public enum PP {
  public enum color {
    /// The screen's ground (scaffold).
    public static let ground = Color(light: 0xE9EEF9, dark: 0x0E1012)   // dynamic UIColor underneath
    public static let heldGold = Color(light: 0x9A7A30, dark: 0xC8AE6E)
    public static let heldGlow = Color(light: nil, dark: 0xC8AE6E, darkAlpha: 0.35)  // dark-only → clear in light
    public static func avatarTone(_ i: Int) -> Color { … }               // 6% darker in dark
    public static func wax(_ variant: Int) -> (base: Color, sheen: Color) { … }
  }
  public enum space { public static let gutter: CGFloat = 20 … }
  public enum size { public enum held { public static let ring: CGFloat = 2 … } … }
  public enum duration { public static let settle: Duration = .milliseconds(320) … }
  public enum type {
    public static let name = Font.custom("Roca-Bold", size: 19, relativeTo: .title3)
    public static let intention = Font.footnote          // system roles use the text style
    public static let count = Font.subheadline.weight(.medium).monospacedDigit()
  }
}
```
Kotlin gets the same tree: `PPColors` instances for dark and light (provided
through a `CompositionLocal`), `Dp`/`TextUnit` values, `TextStyle`s mapped
from the `android.style` extension, durations as `Int` ms.

**Why not Style Dictionary:** the mapping is ours (paired light/dark roles
into one dynamic color, Roca roles scaled relative to an iOS text style, the
`dev.hammock.plusprayer` extensions). Its built-in Swift formats target UIKit,
so custom formats would be most of the work anyway, plus a dependency to
keep current. Worth revisiting if tokens ever need to feed Figma or the web.

**How `tokens.json` is organized:** `color.dark.*` / `color.light.*` (same
roles), `color.avatarTone.0–15`, `color.wax.<weekday>.{base,sheen}`,
`number.*` (ratios, opacities, halo levels), `font.*`, `typography.*`
(roles, with `ios.textStyle` and `android.style`), `space.*`, `radius.*`,
`size.<component>.*`, `duration.*`, `easing.*`. Tier B chrome (menus, sheets,
search field, bars, switches, pickers) has no tokens, and nor do the Flutter
Material-only slots (`deepest`, `groundLow` ripples, menu sizes, settings
rows, glass blur and tint, the shader scroll-edge curves).

---

## 2. Assets plan

Into `apps/ios/PlusPrayer/Resources/` (Phase 1). Asset-catalog images keep
vector data and render as templates where tinted.

| Bring | From `app/assets/` | To | Notes |
|---|---|---|---|
| Roca Regular, Bold | `fonts/Roca_400.otf`, `Roca_700.otf` | `Resources/Fonts/` (registered at launch) | Only the two weights the type roles use (PostScript `Roca-Regular`, `Roca-Bold`). Add others if a role needs them. Licensed for app embedding (Q9) |
| Praying hands | `unbundled/design/icons/praying_hands.svg` (the glyph `PlusPrayer.ttf` uses for the pray button) | `Assets.xcassets/Symbols/pray.symbolset` (custom SF Symbol) | A custom symbol matches text weight and scales with Dynamic Type. The icon font itself isn't needed: the rest of `PlusPrayer.ttf` is unused or Font Awesome |
| Bloom (carried mark) | `img/+prayer_icon.svg` | `Assets.xcassets/Marks/CarriedMark` (template, vector) | Tinted `carriedMark`. Replaced by the "+"-free bloom when D1 lands |
| Stamp | `img/wax_stamps/wax-neutral.png` (512 px) | `Assets.xcassets/Seals/Stamp` | The only stamp Flutter uses: one gray relief, tinted per wax at runtime (face → base, highlights → sheen), and pewter for the streak badge. 512 px covers the 110 pt card stamp at 3×. Replaced by D2 vectors (small sizes) and D3 photos (≥ 40 pt) |
| Wordmark | `img/+_prayer.svg` | `Assets.xcassets/Brand/Wordmark` (vector) | Foot of You; the launch screen |
| Launch screen | ground colors + wordmark | `INFOPLIST_KEY_UILaunchScreen` (no storyboard) | Q11 |
| App icon | `launch_icon.png` (1000 px, flat) | interim `AppIcon` | iOS 26 icons are layered (Icon Composer `.icon`); 1000 px is short of 1024. Q10 |
| Phosphor Light | `fonts/Phosphor-Light.ttf` | **not brought** | SF Symbols instead (Q1) |
| Google "G" | `img/google_logo.png` | later, with sign-in (build step 3) | Use Google's current branding asset, not this PNG, if it's outdated |
| Firebase config | `app/ios/Runner/GoogleService-Info.plist` | app target | Same bundle ID, same Firebase iOS app. Eric adds it |

**Not brought:** the 7 colored `wax-*.png` (old painted placeholders, unused
in Flutter), `logo_svg_parts/` and the Lottie files (unused by the Flutter
build; native motion replaces them), Baloo 2, Roboto Flex, Roboto Mono
(body is the system font), `prayer_templates/` (guided prayer is post-MVP),
`unbundled/` (design sources: `.ai`, `.3mf`, `.psd`; they stay where they
are), `splash_image.png` (a 1424 px raster of the wordmark; the SVG replaces it).

---

## 3. Answered (2026-11-05, recorded in design-direction.md and decisions.md)
- **Q1 Icons:** SF Symbols at a light weight, plus custom symbols for the
  praying hands and bloom. Phosphor isn't brought over.
- **Q2 SDK:** the connector renames are committed and both SDKs regenerated.
  The Swift package builds, and the functions tests pass (113/113).
  **The connector deploy is still pending**: it needs `--force` because
  `GetMyHeader.self` → `selfSubject` is flagged as breaking (no shipped
  client uses it). Eric runs it from `backend/`:
  `firebase deploy --only dataconnect --force`.
- **Q4 Tokens:** Flutter's tuned values for all of them. The spec and
  `tokens.json` are updated. Initials at 70% leave vermilion and olive at
  ~2.6–2.9:1.
- **Q5, Q6:** the pill and pray button are our layout on native glass; scroll
  edges are native on iOS; the docked search row is a sanctioned exception.
- **Q9:** Roca is licensed for app embedding. The license file is still to be
  added.

## 4. Open questions

**Q3. Persistent client cache for the Swift SDK?** `connector.yaml` can turn
on `clientCache` (`storage: persistent`) for the Swift target only. This is a
codegen change with no deploy. The spec says only the very first launch needs
a connection, so Home must load offline.
_Recommend:_ yes, `maxAge: 0` with persistent storage. It serves the last
result offline and always fetches fresh results online. Our queue still owns
writes.

**Q7. Are the Amen invitation, closing sheet and add sheet native sheets?**
_Recommend:_ yes, native sheets with detents. Tier A components (ring button,
cluster, seal) go inside them. `sheet` and `scrim` are kept in tokens only in
case an overlay ends up custom.

**Q8. The filter menu's counts.** A native `Menu` item can show a subtitle
line, or the count can sit in the title ("Still to hold · 3"). Both fit "as
the platform allows". Which one? _Recommend:_ in the title, since it's one
line and reads like the spec.

**Q10. App icon.** iOS 26 icons are layered (Icon Composer `.icon`, with
light, dark and tinted variants). Can you supply the layers (bloom, "+",
ground), or should I build the interim icon from `launch_icon.png`? It's
1000 px; iOS wants 1024.

**Q11. Launch screen.** _Recommend:_ the wordmark centered on `ground` (light
and dark), matching `splash.PNG`. "Your name, carried by the world." stays
the first onboarding screen, not the launch screen.

**Q12. Default theme.** Flutter defaults to Dark and offers a
System/Light/Dark setting. Native apps usually follow System. Keep Dark as
the default (app-brief: "Dark theme is the primary design")?

**Q13. Creating the project: through the Xcode MCP.** Xcode ships an MCP
server (`xcrun mcpbridge`) that can create projects, targets and
synchronized folders, set build settings and entitlements, build, run tests
and render previews. Xcode writes the project itself, so the
"never hand-edit `project.pbxproj`" rule holds. Steps:
1. **Eric:** with Xcode open, connect it to Claude Code:
   `claude mcp add --transport stdio xcode -- xcrun mcpbridge`. Then
   restart the Claude Code session so the tools load. Xcode may ask you to
   allow the connection.
2. **Agent (via MCP):** create the iOS App project `PlusPrayer` in
   `apps/ios/` (SwiftUI, Swift Testing, iOS 26, bundle ID
   `dev.hammock.plusprayer`). Add the unit and UI test targets and the
   synchronized folders from `CLAUDE.md`. Set Swift 6 mode. Write
   `Packages/PlusPrayerDomain/`. Add Xcode ignores to the root `.gitignore`.
3. **Eric (Xcode UI; the MCP has no package tool):**
   - In File › Add Package Dependencies, add `apps/ios/PlusPrayerConnector`
     and `apps/ios/Packages/PlusPrayerDomain` (via Add Local…).
   - Add firebase-ios-sdk with FirebaseAuth, FirebaseDatabase,
     FirebaseAnalytics, FirebaseCrashlytics and FirebaseMessaging.
   - Set the team and signing, and add the Sign in with Apple, Push and
     Background Modes (remote notifications) capabilities.
   - Drop in `GoogleService-Info.plist`.
4. **Agent:** build through the MCP and confirm a blank app runs on the
   iOS 26.5 simulator. Then build order step 1 (tokens, components, mock)
   starts.

**Q14. Reference screenshots.** The 8 PNGs in `docs/product/reference/` are
untracked, and their names don't follow the README's
`<screen>-<state>-<theme>.png` (e.g. `home_filter_menu.PNG`). I didn't commit
them, since they aren't mine. Should I rename and commit them (e.g.
`home-filter-menu-dark.png`)?

**Notes (no answer needed):**
- **Halo corners:** iOS has no public API for the screen's corner radius
  (Flutter's plugin reads a private one). iOS 26's `ConcentricRectangle` /
  container shapes follow the display corners, so the halo uses those.
- **Google Sign-In:** Flutter left it out over a `gtm-session-fetcher`
  conflict. Natively that may be gone; I'll check at build step 3.
- **Swift 6:** the generated connector compiles in Swift 5 mode with
  `Sendable` warnings. The app target can still use Swift 6 mode.
- **Android:** a `kotlinSdk` target gets added to `connector.yaml` when
  `apps/android/` starts.
