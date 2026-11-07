# Add sheet — build notes (iOS)

Spec: `docs/product/screens.md` → Add sheet. Decisions: `docs/decisions.md`
(2026-11-05 → 2026-11-07). Seeded 2026-11-07 from the design sessions;
build agents: correct anything here that doesn't match the code.

## Keep (workarounds and why)
- **Keyboard rises with the sheet:** a hidden UIKit helper calls
  `becomeFirstResponder` when its view enters the window (SwiftUI sheets
  have no view controller to hook `viewWillAppear`). Setting focus later
  (`asyncAfter`) made the keyboard arrive after the sheet. (2026-11-06)
- **Late-focus fallback** for the add-intention form opened from a Home
  row's long-press: if no field has focus once the sheet settles, its field
  takes it, so the keyboard rises late rather than not at all. (2026-11-07)
- **Hidden tab is out of the accessibility tree:** the inactive tab's
  controls are removed or `accessibilityHidden`, not just faded; fading left
  the Intention tab's carry toggle reachable by VoiceOver. (2026-11-07)
- **Bloom sizing exception:** the carry bloom uses `.font(.system(size:))`
  computed from `size.carriedMark.carryRow` (15 pt) via
  `@ScaledMetric(relativeTo: .body)`, plus a 0.72 height-to-font-size
  constant in `PPIcon`. It's a glyph sized to text; the no-fixed-font rule
  doesn't apply. (2026-11-06)
- **Native switch on iOS:** only the "on" tint is ours (`switchTrackOn`);
  the off track can't be recolored without replacing the control, so iOS
  keeps the system's. `switchTrackOff` is Android-only. (2026-11-06)
- **Home keeps observing data while a page is pushed** on top of it
  (it used to stop its updates on disappear). (2026-11-07)
- **"Who is this for?" search starts inactive.** Auto-activating
  `.searchable` delayed focus and hid the title/back (exit took X then
  back). (2026-11-06)
- **No possessives built from the alias** in copy ("Add a first intention
  for {alias}"). (2026-11-07)

## Tried and dropped
- **Avatar moving between Name and alias rows** (matchedGeometry across
  `Form` rows): motion broke between rows. (2026-11-06)
- **Glass merge/split avatar ↔ field:** worked, but glass only merges with
  glass, so the fields had to become glass pills that didn't match the
  form. (2026-11-06)
- **Avatar as a toolbar control + Add splitting off the X:** read as a
  button; overloaded the toolbar; Add next to X invited accidental closes.
  (2026-11-06)
- **Hand-built form layout** (custom form-group view, form spacing tokens):
  replaced by native `Form` once variances kept appearing. Don't hand-tune
  padding, label size or alignment in the form. (2026-11-06)
- **Two-step "Added" step with a Not now · Name · Name + intention
  control:** replaced by landing on the person's page. (2026-11-07)
