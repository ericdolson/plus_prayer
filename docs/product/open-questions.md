# Open Questions

_Last updated: 2026-11-05. Resolve here → update the feature file → log in
decisions.md. **MVP** = blocks MVP build._

| # | Question | Area | MVP? |
|---|---|---|---|
| Q3 | Price: ~$20–30/yr vs ~$3–5/mo; monthly/annual; one tier or several | monetization | Stage 2 |
| Q15 | Billing provider (RevenueCat vs direct) | monetization | Stage 2 |
| Q28 | **KNOWN GAP** — safety handling (self-harm resource card, threat/child-safety policy, lawyer review); see safety.md | safety | Stage 2 (S1–S4 beta) |
| Q18 | Link a social participant's handle to their app account? | list-lifecycle | Later |
| Q20 | Physical printing at app scale: how is a list with 100k+ names printed/sealed? | list-lifecycle | Stage 2 |
| Q29 | **App Check** (added 2026-11-05): adopt Firebase App Check (App Attest on iOS, Play Integrity on Android) so only the genuine apps can call SQL Connect, the Functions callables, RTDB and Storage? Today anyone with the public Firebase config can script calls (auth rules still confine them to their own anonymous account, but they could mass-create accounts and prayers). Needs: the `FirebaseAppCheck` product + App Attest capability in the apps, and enforcement on the backend. Recommended: before public launch, maybe monitor-only in the beta. Not yet in the spec or backend | security | Before launch |
| Q30 | **Publishing entity and bundle ID** (added 2026-11-05): +Prayer ships from a new LLC's Apple Developer account (Organization). Final bundle ID (e.g. `com.plusprayer.app`; Android package to match?) and when to switch. Switching before the first TestFlight upload means: register the App ID and capabilities under the LLC team; a new Firebase iOS app (new `GoogleService-Info.plist`); the LLC's APNs key and Sign in with Apple config in Firebase; the project's team and bundle ID. Needs the LLC's D-U-N-S number and enrollment first | publishing | Before beta |

## Design to-dos (not blocking)
| # | Item | Area |
|---|---|---|
| D1 | Draw a dedicated **bloom without the "+"** for the carried mark; until then it uses the logo glyph (`+prayer_icon.svg`). See design-direction §5 Carried mark | design |
| D2 | Draw the **7 wax-stamp vectors as the bloom pressed into wax** (one per weekday wax), replacing the painted circled-"+" placeholder in `WaxSeal`. Same bloom as D1, so ink (carried) and wax (sealed) read as one symbol. **Scope reduced 2026-11-02:** vectors now only for small sizes; large sizes use photos (D3). **2026-11-03:** detail-page beads are plain wax-colored dots, so D2 doesn't block them (see detail-page.md). See list-lifecycle and design-direction §5–6 | design |
| D3 | **Shoot the 7 wax seals (+ an unsealed blank) as macro photos**, cut out with transparency, for large seal sizes. Shoot guide in design-direction §6 "Photographed seals" | design |
| D4 | **Layered app icon** in Icon Composer (`.icon`: layers plus light, dark and tinted variants) for iOS 26. Until then the iOS app uses an interim icon built from `app/assets/img/+prayer_icon.svg` (2026-11-05) | design |
| D5 | **DEFERRED (2026-11-06): searchable intention name picker.** v1 is a plain native menu listing every name (no search). Build when lists commonly pass ~10 names: menu shows Me + the 5 most recent (prayed or added) + "All names…", which pushes a list inside the add sheet with its search field focused (keyboard stays up), matching name + alias like Home search. Under ~10 names the menu lists everyone and "All names…" is hidden. See screens.md add sheet | app |

## Resolved
| # | Resolution | Date |
|---|---|---|
| R1 | Decisions live in `docs/product/` (current state) + `docs/decisions.md` (why) | 2026-10-17 |
| R23 | Language via device + User.locale; groups via share table; PrayerList.scope; analytics + min version from day one; personal practice free at any size (~500 abuse cap only) | 2026-10-18 |
| R22 | Badge always visible (muted, no number at 0); avatar cluster (first 1–2 named w/ avatar, up to 5, +N); "the list" always names who's on it; notifications: names/aliases yes, intention text never (except moment reminders), setting to hide names | 2026-10-18 |
| R21 | In-progress prayers: RTDB draft (per device), Prayer written once; 30-min resume rule; 6h auto-save with estimated duration (~), AUTO flag; prayer time shown per prayer + History header, not on detail pages (was Q5) | 2026-10-18 |
| R20 | Streak badge beside header avatar; "carried on N lists" on Today's list; history = bead strand in wax colors, neutral gaps, note/answered hints; no outcome recording (was Q24) | 2026-10-18 |
| R19 | List gate = prayed for the list since last flip OR within ~30h (config); keep streak = stay carried | 2026-10-18 |
| R18 | Screens/nav (home-only footer: History · 🙏 · ＋Add; avatar → You); one detail page; one add sheet; last call 8pm; guided prayer post-MVP with schema seams now | 2026-10-18 |
| R17 | Privacy: paper kept forever, sealed, locked cabinet at office; helpers under NDA later; 13+; plain summary first then generator + lawyer | 2026-10-18 |
| R16 | Faith positioning (b): faith-agnostic brand ("Everyone" everywhere incl. store) with familiar Christian-rooted ritual words kept (Amen, grace) | 2026-10-18 |
| R15 | Admin = admin-only functions called by Claude skills; auto-flags (profanity, PII/links, frequent self-name changes); users see Held/Not printed; skill keeps generating PDF from DB | 2026-10-18 |
| R14 | MVP push = opt-in "list is live" only; last call only if not prayed at all; video self-hosted on Firebase Storage; full-bleed on list detail | 2026-10-18 |
| R13 | Streaks: local days prayed WITH THE LIST (revised 2026-10-18; personal-only days = hollow marks + monthly count); grace days offered every 7 prayed days, accepted, banked up to 2 (config; may rise to 3, never lower), "don't offer again" instead of strict setting; 8pm last call; quiet milestones | 2026-10-18 |
| R12 | Presence: one count for any prayer, count only, live ≥10 else time window, throttled public RTDB counter (~5s) | 2026-10-18 |
| R11 | ExternalPerson table for social + base set; backfill list history; DB cutover before launch; resolved NamUs cases removed quietly | 2026-10-17 |
| R10 | Pay before sign-in; self-name edits free until first printed then weekly; one name field; aliases (owner-only, self = "Me") | 2026-10-17 |
| R9 | Anonymous-first onboarding; "What's your name?" = self; trial starts at first prayer; sign-in prompts; deletion strips names, keeps counts; names never legible in video | 2026-10-17 |
| R8 | Pool unit = names/intentions; block over-limit save; auto-carry; Answered (not list-eligible, stays w/ gratitude) vs Release (archive); anonymous answered count when meaningful | 2026-10-17 |
| R7 | Free = you + one own intention; ~14-day no-card reverse trial; intentions nest under names (person/group/cause); selection rules; names print with intentions; portion preview; caps 40/80; app user's social 🙏 carries only them | 2026-10-17 |
| R6 | Intentions print as text on the physical list; names/intentions character-capped; font shrinks with scale | 2026-10-17 |
| R5 | Row secondary text = one state line; list invitation = tap-then-ring stating who'll be carried; monogram avatars at MVP, photos fast-follow | 2026-10-17 |
| R4 | In-prayer UX = in-place mode (halo, check = holding, FAB → Amen after ~5s, list invitation at Amen) | 2026-10-17 |
| R3 | A prayer may include the list, subjects, both, or neither; no ordering rule; main screen = personal list with today's list pinned on top (was Q6) | 2026-10-17 |
| R2 | Streaks = calendar days in user's local TZ (supersedes list-number streaks) | 2026-10-17 |
