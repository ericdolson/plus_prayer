# Open Questions

_Last updated: 2026-10-17. Resolve here → update the feature file → log in
decisions.md. **MVP** = blocks MVP build._

| # | Question | Area | MVP? |
|---|---|---|---|
| Q3 | Price: ~$20–30/yr vs ~$3–5/mo; monthly/annual; one tier or several | monetization | Stage 2 |
| Q15 | Billing provider (RevenueCat vs direct) | monetization | Stage 2 |
| Q28 | **KNOWN GAP** — safety handling (self-harm resource card, threat/child-safety policy, lawyer review); see safety.md | safety | Stage 2 (S1–S4 beta) |
| Q18 | Link a social participant's handle to their app account? | list-lifecycle | Later |
| Q20 | Physical printing at app scale: how is a list with 100k+ names printed/sealed? | list-lifecycle | Stage 2 |

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
