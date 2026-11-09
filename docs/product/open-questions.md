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
| Q31 | **Add-sheet upsell (updated 2026-11-06).** The once-a-day invitation card is dropped: the add sheet's carry row shows a persistent, quiet **"Make room for {alias}"** when the pool is full (visible, inert until Membership / Your portion exist). Open: what its menu offers (add more places/people via membership; free one up via a picker or Your portion), its wording, and how strong the membership pitch inside it is. **Free tier:** most new names of a free user hit this, so it should explain, not sell. Q32 decided 2026-11-08 (people) | monetization | Stage 2 |
| Q33 | **Standalone journal entries (IDEA 2026-11-08, post-MVP).** Let people write a journal entry outside a prayer, alone or tied to one or more names, so it shows in those people's Journal. Appraisal: real value (a hospital update, a thought at 2 a.m.; the Journal becomes the place for their story) and cheap in schema (an entry row with optional subject links, or a zero-length "AUTO"-style prayer); risks: it drifts from the ritual (writing replaces praying), blurs "prayers" counts unless entries are not prayers, and adds a second compose surface. If done: a ＋ in the Journal tab, never on Home; never counted as a prayer; no streak credit. Revisit after beta with how much people write after Amen | app | Post-MVP |
| Q34 | **A first-run tour of Home? (2026-11-09).** Decided for now: no coach marks; the onboarding hand-off brings Home in order (header, rows, the card, the pray button last). Revisit if beta testers miss the community card, the pray button or ＋; if so, prefer one in-context line over a tooltip tour | app | Beta |

## Design to-dos (not blocking)
| # | Item | Area |
|---|---|---|
| D1 | Draw a dedicated **bloom without the "+"** for the carried mark; until then it uses the logo glyph (`+prayer_icon.svg`). See design-direction §5 Carried mark | design |
| D2 | Draw the **7 wax-stamp vectors as the bloom pressed into wax** (one per weekday wax), replacing the painted circled-"+" placeholder in `WaxSeal`. Same bloom as D1, so ink (carried) and wax (sealed) read as one symbol. **Scope reduced 2026-11-02:** vectors now only for small sizes; large sizes use photos (D3). **2026-11-08:** the detail page no longer draws wax beads (History is a calendar), so D2 doesn't touch it. See list-lifecycle and design-direction §5–6 | design |
| D3 | **Shoot the 7 wax seals (+ an unsealed blank) as macro photos**, cut out with transparency, for large seal sizes. Shoot guide in design-direction §6 "Photographed seals" | design |
| D4 | **Layered app icon** in Icon Composer (`.icon`: layers plus light, dark and tinted variants) for iOS 26. Until then the iOS app uses the Flutter app's 1024 icon (`app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`, 2026-11-07), light only. Android's interim: the Flutter app's launcher mipmaps (`app/android/app/src/main/res/mipmap-*`); it'll need an adaptive icon (foreground + background) | design |
| D5 | ~~Searchable intention name picker~~ **Done in spec 2026-11-06:** the add sheet's For row pushes a searchable "Who is this for?" (screens.md) | app |
| D6 | **Discard confirmation in the add sheet (deferred 2026-11-06):** whether X / swipe-down with typed text should ask "Discard this name?" first. Not now: accidental X taps seem unlikely; revisit if testers lose text | app |
| D6 | **DEFERRED (2026-11-06): prayer info while searching in prayer.** Searching mid-prayer turns the pill into the search field, so the timer and "with N" are hidden until ✕ (focus is elsewhere; the halo and Amen still show the prayer). Revisit only if people miss them, e.g. a quiet timer inside the field | app |
| D7 | **Android launch screen.** Android 12+ (SplashScreen API) shows a centered icon on a color, not a full wordmark. Options: the mark alone on `ground`, or the icon then a brief wordmark. Flutter's generated res (`drawable*/splash.png`, `values-v31`) is the starting point. Decide when Android starts | design |
| D8 | **Custom quill symbol `pp.quill` for the journal** (2026-11-08). SF Symbols has no feather, quill, fountain pen or nib (checked). Draw a quill as a custom symbol beside `pp.bloom` / `pp.pray` (antique over modern; a pencil reads as editing a document). Replaces the pencil (`PPIcon.journal`) wherever the journal shows: the ✎ mark on prayers and older-month rows, and possibly the "Add to journal" button. Keep the pencil until it exists (change the symbol once) | design |

## Resolved
| # | Resolution | Date |
|---|---|---|
| R1 | Decisions live in `docs/product/` (current state) + `docs/decisions.md` (why) | 2026-10-17 |
| R24 | **Pool unit = people** (was Q32): a place = one carried person, Me free; each prints with up to 1 chosen intention (`/config` `intentionsPerPerson`; higher caps = a tier property later); intentions cost nothing; no "and N more"; free = you with your intention; set by a "Prints with" picker on the person page. Tiers and prices still open | 2026-11-08 |
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
| R8 | Pool unit = names/intentions (unit superseded by R24, 2026-11-08); block over-limit save; auto-carry; Answered (not list-eligible, stays w/ gratitude) vs Release (archive); anonymous answered count when meaningful | 2026-10-17 |
| R7 | Free = you + one own intention; ~14-day no-card reverse trial; intentions nest under names (person/group/cause); selection rules; names print with intentions; portion preview; caps 40/80; app user's social 🙏 carries only them | 2026-10-17 |
| R6 | Intentions print as text on the physical list; names/intentions character-capped; font shrinks with scale | 2026-10-17 |
| R5 | Row secondary text = one state line; list invitation = tap-then-ring stating who'll be carried; monogram avatars at MVP, photos fast-follow | 2026-10-17 |
| R4 | In-prayer UX = in-place mode (halo, check = holding, FAB → Amen after ~5s, list invitation at Amen) | 2026-10-17 |
| R3 | A prayer may include the list, subjects, both, or neither; no ordering rule; main screen = personal list with today's list pinned on top (was Q6) | 2026-10-17 |
| R2 | Streaks = calendar days in user's local TZ (supersedes list-number streaks) | 2026-10-17 |

- **Archived screen: restored-uncarried copy** (2026-11-07). `restoreSubject`
  returns `uncarried: true` when the pool turned the item off. Decide the
  quiet line the Archived screen shows then, when that screen is built.
