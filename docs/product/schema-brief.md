# Schema Brief — handoff for the backend session

_Written 2026-10-18 from the product meetings of 2026-10-17/18. Revised
2026-10-18 with answers to the backend session's first review (§8)._
**Audience:** an agent updating `backend/dataconnect/schema/schema.gql`,
`connector/OPERATIONS.md`, functions, and RTDB rules. Every change below names
the spec file that justifies it — read that file if a rule is unclear. Exact
SQL Connect directive syntax is the implementer's job; this is the design.

Principles that still hold: derive on read unless a read is hot; all aggregated
state is server-written; `Prayer` is immutable history (note-only edits);
per-operation `@auth`; names are never public.

---

## 1. Tables

### User — changes
| Field | Change | Why / spec |
|---|---|---|
| `displayName` | keep, **nullable** until `setSelfName`; then mirrors the self-subject's `publicName` | auth-onboarding |
| `locale: String` | ADD — effective UI language (device or override) | screens (Language) |
| `timezone: String` | ADD — IANA, updated from device | streaks-reminders |
| `includeLimit: Int` | REDEFINE — size of the carried pool **beyond the self name**, in **people** (Q32, 2026-11-08). Free = 0 (you, with your intention). Premium = N people | monetization |
| `trialStartedAt`, `entitlementExpiresAt: Timestamp` | ADD — 14-day no-card reverse trial, starts at first prayer | monetization |
| `currentStreak`, `bestStreak` | keep — streak = **local days prayed WITH THE LIST** | streaks-reminders |
| `lastPrayedListNumber` | REMOVE → `lastListLocalDate: Date` (stored; app shows an *effective* streak from stored fields + today) | streaks-reminders |
| `graceDays: Int` (0–cap), `graceOfferPending: Boolean`, `graceOffersEnabled: Boolean` | ADD | streaks-reminders |
| `selfNameChangedAt: Timestamp` | ADD — free edits until first printed, then 1 / 7 days | auth-onboarding |
| `listLiveOptIn: Boolean` (default false), `showNamesInNotifications: Boolean` (default true) | ADD | notifications |
| `prayerVoice: String`, `prayerVoiceConsentAt: Timestamp` | ADD (nullable seam, unused at MVP) — religion is special-category data | prayer-flow (guided) |

### ReminderPreference — NEW (decided: own table, not fields on User)
`user`, `slot` (MORNING | MIDDAY | EVENING | CUSTOM), `enabled`, `localTime`,
`label?`. Synced server-side, scheduled on device. Default: Morning on. Custom
reminders (cap 5–7) are later but the table supports them. — notifications

### PrayerSubject — changes
| Field | Change | Why / spec |
|---|---|---|
| `kind` | keep SOUL \| INTENTION. A SOUL is any "name" (person, group, cause) | subjects |
| `parent: PrayerSubject` | ADD — **required for INTENTION, null for SOUL**; parent must be a SOUL with the same owner; one level only | subjects |
| `publicName` | keep — printed text. Cap 40 (name) / 80 (intention), counted in **grapheme clusters**; any script | subjects, screens |
| `personalLabel` | keep — surfaced as "alias", owner-only. Self alias = "Me" | subjects |
| `isCarried: Boolean` | ADD — user's choice to print. On a name: carried (counts a place; auto-set on create while the pool has room). On an intention: **chosen to print with its person** (≤ `intentionsPerPerson` per person, server-enforced; auto-set when under the cap) | monetization |
| `sortOrder` | keep — manual order only (names; intentions within a name); new items at bottom | subjects |
| `avatarTone: Int` | ADD — palette index; default from hash of id | prayer-flow |
| `avatarPath: String` | ADD (nullable seam for photos, private Storage) | prayer-flow |
| `answeredAt` | REMOVE → `resolvedAt: Timestamp` + `resolution` enum (ANSWERED \| RELEASED) | subjects |
| `status` | keep ACTIVE \| ARCHIVED \| PURGED. RELEASE also sets ARCHIVED | subjects |
| `groupId` / `visibility` | **DO NOT ADD** — groups will use a Share table (§4) | roadmap |

Effective carry: an intention prints only if `isCarried && parent.isCarried`;
the pool counts carried **names** beyond the self name (Q32, 2026-11-08). Archive/purge cascade from a name to its
intentions; ADD `archivedByCascade: Boolean` on intentions. **Restore** brings
back only intentions with `archivedByCascade = true` — never Released ones or
ones the user archived on their own.

Constraints: self-subject forced ACTIVE, not carried-toggleable, not resolvable.
Resolved items are never list-eligible. Soft abuse cap ~500 subjects per user
(server check, not a paywall) counting only **active** subjects (on Home,
Answered included; not archived, released or purged), plus a quiet hard cap
of ~5,000 total rows per user (generic error) against archive-and-add abuse
(2026-11-06).

### PrayerList — changes
| Field | Change | Why / spec |
|---|---|---|
| `scope` enum | ADD, default GLOBAL; uniqueness becomes **(scope, listNumber)** | roadmap (future church lists) |
| `closesAt: Timestamp` | ADD — set by Eric's skill ~5 min before assembly; the exact cutoff (prayer counts if it **started** before it) | list-lifecycle |
| `currentFrom: Timestamp` | ADD — = previous list's `closesAt` | list-lifecycle |
| `prayerSeconds: Int` | ADD — incremented on write, frozen at settle (survives account deletion) | stats-history |
| `sealVariant: Int` (0–6) | ADD — set at publish from the weekday→wax mapping | list-lifecycle |
| `videoPath: String` | ADD — Firebase Storage object for the self-hosted video | list-lifecycle |
| `status`, `publishedAt`, `videoPublishedAt`, counts | keep; `prayerCount` still settles on close | list-lifecycle |

### DailyStats — NEW
`date` (**UTC day** of the prayer's end), `prayers`, `prayerSeconds`,
`peoplePraying` — all prayers incl. personal; incremented on write, never
recounted from rows. `peoplePraying` uses `User.lastStatsDate` (UTC): if it
differs from today, increment and set it. — stats-history

### ExternalPerson — NEW
`source` (SOCIAL | BASE_SET), `platform` (non-null; base set = "namus"), `externalId` (platform user id or
NamUs case id), `displayName`, `firstSeen`, `activeFrom?`, `activeUntil?`.
Unique (source, platform, externalId). Social: public display name + id only.
Resolved NamUs cases: set `activeUntil` (removed quietly). — list-lifecycle

### PrayerListEntry — changes
| Field | Change |
|---|---|
| `id` | ADD surrogate key (replaces composite (list, subject)) |
| `subject?` / `externalPerson?` | exactly one set (DB check). Unique (list, subject) and (list, externalPerson) |
| `owner?` | nullable (null for external) |
| `parentEntry: PrayerListEntry?` | ADD — groups an intention under its name so print honors "your portion" |
| `source` | enum APP \| SOCIAL \| BASE_SET |
| `moderationStatus` | enum APPROVED \| HELD \| EXCLUDED; keep `heldReason` |
| `reasonCategory` | ADD enum LANGUAGE \| CONTACT_OR_LINK \| NAME_CHANGES \| OTHER |
| `publicName`, `kind` | keep — frozen snapshots |

This table is also the **History** source (list days; history.md).
No per-assembly outcome table is needed (decided — stats-history).

### Prayer — changes
| Field | Change | Why / spec |
|---|---|---|
| `id` | **client-generated UUID** so offline retries are idempotent | prayer-flow |
| `startedAt: Timestamp` | ADD | prayer-flow |
| `prayedAt` | keep = end time | — |
| `durationSeconds` | keep; ≥5s; auto-saved = estimate (last foreground + ≤30 min, cap 4h) | prayer-flow |
| `localDate: Date`, `timezone: String` | ADD — local date of **start**; streak + gaps + monthly counts | streaks-reminders |
| `communityList` | keep — set when the list was included | prayer-flow |
| `listContextNumber` | keep — list current at **start** | prayer-flow |
| `endedBy` enum | ADD — AMEN \| AUTO | prayer-flow |
| `mode` enum | ADD — MANUAL \| GUIDED (seam) | prayer-flow |
| `note` | keep — only editable field | prayer-flow |
| `latitude/longitude` | keep nullable, **unused at MVP** (location deferred) | prayer-flow |

### PrayerSubjectLink — unchanged
Note: a link may later point to a subject owned by someone else (shared via a
group). Never assume `prayer.user == subject.owner`; "my prayers for X" filters
by `prayer.user`. Checking an intention also writes a link to its parent name.

---

## 2. Derived on read (do not store)
Tier-1 counts (raw + cycles) · tier-3 world count (closed lists + live stitch) ·
per-item "last prayed" (local date) · History days
· period rows (prayers, notes count, answered marker) · "Days in prayer this
month" · "carried on N lists" · answered running total · prayer time per prayer
/ week / all time. Only the user streak/grace fields and list counts are stored.

## 3. Realtime Database
- `/presence/{uid}/{deviceId}` (owner-write): `startedAt`, `lastActiveAt`
  (heartbeat ~1/min in foreground), `inForeground`, `listIncluded`, `itemIds[]`
  (IDs only), plus optional `prayerId` (client UUID — makes auto-save and a late
  Amen idempotent), `localDate` and `timezone` (start date from the device).
  Doubles as the in-progress prayer draft. `onDisconnect` marks
  background/disconnect; counts as praying for ~30 min after backgrounding.
- `/stats/live` (server-write, public-read): `prayingNow` (people, not devices),
  `prayedLastHour`, `prayedToday`, `updatedAt` — republished ≥5s apart + 1-min
  reconcile. Clients subscribe only while foregrounded.
- `/lists/current` (server-write, public-read): `listNumber`, live `prayerCount`,
  **`closesAt`** (mirrored when Eric sets it, so open apps show the 5-minute
  banner without re-fetching).

## 4. Future seams (not built now — keep compatible)
`Group` (type FAMILY | CIRCLE | CONGREGATION | ORGANIZATION, `parentGroup?`),
`Membership` (role), `Share` (subject → group or PUBLIC; many per subject),
tier-2 counts, "In memory" state for departed souls, Report/Block, data export,
separate Entitlement table for family/gift plans, scoped lists.

## 5. Config
| Value | Where | Default |
|---|---|---|
| Gate window | server param | 30h |
| Draft resume / auto-save / duration cap | server param (+ client mirror) | 30 min / 6h / 4h |
| Min prayer duration | both | 5s |
| Grace cap / interval | RTDB `/config` + server enforcement | 2 / 7 list days |
| Presence display threshold | RTDB `/config` | 10 |
| Min app version | RTDB `/config` | — |
| Base premium pool (trial + base subscription) | RTDB `/config` `basePremiumPool`, read by the server for grants (like the grace cap) and by the app for the add sheet; server fallback 10. The `BASE_PREMIUM_POOL` Functions param is dropped (2026-11-06) | 10 |

Client-visible config lives in a small public-read, server-write RTDB node
`/config` (with defaults compiled into the app), NOT Firebase Remote Config —
Remote Config moved to usage-based pricing on 2026-09-01, and RTDB is already
in the stack, offline-cached, and live-updating. Revisit Remote Config only if
A/B testing or audience targeting is needed.
| Subject abuse cap | server; counts active subjects only | ~500 |
| Subject total-row hard cap | server Functions param (like `SUBJECT_CAP`); all non-purged rows | ~5,000 |

## 6. Functions & operations to add/revise (update OPERATIONS.md)
- **onAuthUserCreated** — User only (nullable displayName). **setSelfName(name)**
  (idempotent callable) creates the self subject ("Me").
- **mergeAccounts(anonIdToken)** — called by the signed-in existing user after a
  credential-in-use conflict; verifies the anon token. One transaction: reassign
  non-self subjects (sortOrder appended), re-parent the anon self's intentions
  and re-point its links/entries to the existing self (drop an entry if both
  selves are on the same list), reassign prayers; recompute streak from merged
  list days, bestStreak = max, graceDays = max (capped), trialStartedAt =
  earliest, keep the active entitlement; keep existing reminder prefs; delete
  anon User + auth user; move RTDB nodes. UI warns duplicates may need cleanup.
- **logPrayer** (client mutation) — idempotent by client id; writes Prayer + links
  (intention ⇒ parent link). **onPrayerLogged** — increments list `prayerCount`/
  `prayerSeconds` and `DailyStats`; streak (list days only, lazy grace use), grace
  offers, trial start on first prayer.
- **assembleNextList** (admin) — settle N; set N+1 `currentFrom`; gate =
  prayed with list — (a) `communityList` = closing list (started before
  `closesAt`) and committed before assembly, OR (b) ended within 30h; effective
  entitlement (expired ⇒ free; trial-end soft landing ≤7 days); per user: self + carried,
  ACTIVE, unresolved items up to entitlement (free: intentions under Me only;
  intention requires its name carried); + social ExternalPersons from harvest +
  active base set; freeze names; auto-flag (profanity/blocklist, phone/email/URL,
  frequent self-name changes); write `parentEntry`.
- **autoSavePrayerDrafts** (scheduled) — finalize drafts idle >6h (endedBy AUTO).
- **presencePublisher** + reconcile.
- **publishList / publishListVideo** (admin) — status, `videoPublishedAt`,
  `videoPath`, `sealVariant`, post rows.
- **moderateEntry**, **setEntitlement** (admin); **deleteAccount** (delete the
  user's PrayerListEntry rows and personal data; stored list counts,
  `prayerSeconds` and `DailyStats` are unaffected).
- Client ops: subject CRUD incl. `parent`, `isCarried` (blocked over limit),
  reorder, resolve (Answered/Release), archive/restore/purge, self-name edit
  (rate-limited), reminder/notification prefs, detail-page query (subject +
  entries + prayers in one op), history (paginated), portion preview.

## 7. Migration & data
- Backfill lists 1..N + participants from `publishing/lists.json` /
  `participants.json` (ExternalPerson rows, entries, counts, post links,
  sealVariant from weekday).
- Import NamUs base set as ExternalPerson (BASE_SET).
- Harvest/publish skills cut over to admin functions **before launch**.
- Existing deployed data: none yet — schema can change freely.

## 8. Answers to the first backend review (2026-10-18)
1. Field name: `lastListLocalDate`. 2. A prayer counts for the local date of its
**start**. 3. Streak fields stored; the app displays an effective streak; grace
consumed lazily at the next list prayer. 4. Free = 1 (an intention under Me).
5. Reminders in their own table. 6. Pool = everything beyond the self name;
`basePremiumPool = 10` for both trial and base tier; expired entitlement is
computed as free; trial-end soft landing ≤7 days. 7. Account deletion deletes
entries; aggregates are increment-on-write (`prayerCount`, `prayerSeconds`,
`DailyStats`) and never recounted. 8. `setSelfName` creates the self;
state-based onboarding resume; `mergeAccounts`. 9. `platform = "namus"`.
10. Gate per §6 using `closesAt`.
Follow-ups: `DailyStats.date` = UTC day (`User.lastStatsDate` for
`peoplePraying`); restore only restores `archivedByCascade` intentions; `closesAt`
mirrored to RTDB `/lists/current`. The ≤7-day soft landing applies to ANY
entitlement end (trial or lapsed subscription), detected as "no active
entitlement and carried > free limit" — no `trialEndChoiceAt` field. 11. "First printed" = first APPROVED entry on a
PUBLISHED list. 12. Effective carry + cascade. 13. Enums as listed.

## 9. Answers to the backend implementation review (2026-10-18)
Approved as built: RTDB `/config` (+ seed defaults), pool/cap/abuse checks in
server functions (addSubject, updateSubject, setCarriedItems), `Prayer.countedAt`
(exactly-once counting), no `auth.uid` default on `User.id`.
1. Late offline prayers for a settled list don't change its number; they count
   for DailyStats, streak, and gate.
2. **When `closesAt` is set, create the N+1 PrayerList row immediately** (draft,
   `currentFrom = closesAt`). Prayers started after `closesAt` link to and count
   toward N+1; assembly later fills its entries. App shows N+1 current from then.
3. **Repair streaks from late syncs:** if a prayer arrives with `localDate`
   earlier than the latest counted, recompute the streak from the user's list
   days (look back ~1 year) using the grace days currently held.
4. Grace offers: every 7th consecutive list day of the current streak; a break
   restarts the count (bridged days don't count).
5. Name-change flag = "self name changed since it was last printed".
6. Blocklist: seed from an open list (e.g. LDNOOBW, CC-BY — attribute) for
   English + top languages, stored as editable config; plus phone/email/URL
   patterns.
7. Restoring an intention under an archived name is blocked ("Restore its name
   first"). **Restoring a Released intention clears its resolution** (open and
   list-eligible again). Answered stays Answered when restored.
   Restore is pool-aware (2026-11-07): if the restored item would push
   effectively carried items over the pool, it's restored with its own
   `isCarried` false (a name's intentions keep their flags).
8. "Over the free limit" definition approved.
9. Print order: decided by the print step.
10. Paid plan active at first prayer → no trial; no "trial" tier — approved.
11. Alias 40, note 1,000 approved. **Social display names capped at 40
    graphemes (truncate on ingest).** Range-check `avatarTone`.
12. Push copy: "List 52 is up · 4,345 people, including you."
13. Merged streak rule approved.
14. List date = Mountain date at assembly; draft counts incl. held, published
    counts approved only. **History / world-count operations return only
    APPROVED entries (server-side), not an app-side filter.**
15. Draft fields added to §3.

## 10. Follow-ups (2026-10-18)
- Gate window bound: rule (b) counts only list prayers that ended in the 30h
  **before `closesAt`**; anything started after `closesAt` belongs to N+1 only
  (fixes one prayer earning two lists).
- `avatarTone` 0–15 placeholder approved. Streak repair: never lowers the stored
  streak, doesn't re-spend grace, doesn't trigger offers — approved.
- Blocklist: remove words that are also common given names/nicknames (e.g.
  "dick", "fanny", "willy") from the seed; keep CJK single-character
  whole-word matching.
- Push copy: "List 52 is up · 4,345 people." (broadcast — no "including you").

## 11. Beta moderation (2026-10-18)
- **Block contact info/links at input** in addSubject / updateSubject /
  setSelfName (printed text only — not aliases): phone (7+ digits with separators), email, URL/domain.
  Return a validation error the app shows inline. Don't block verse references
  ("John 3:16"), room numbers, dates, "St.". Social ingest: exclude matching names.
- **Exception-based review:** assembly prints everything not EXCLUDED. `HELD`
  = internal "flagged for Eric"; held items print unless Eric excludes them.
- **Review diff:** the assembly/admin output includes names and intentions that
  are new or changed since the last list (incl. self-name changes) for the
  morning skill's AI first pass and Eric's review.
- **Word blocklist: off** via config for the beta (keep the code); Stage 2.
- Users never see a pending state; `reasonCategory` surfaces only on EXCLUDED
  entries after assembly.

## 12. checkedAt seam (2026-10-27)
Add `checkedAt: Timestamp` to `PrayerSubjectLink` — when each item was checked
during the prayer (client-supplied, offline-safe). No UI uses it; it preserves
options (order held, exact time for single-focus prayers). **No per-item prayer
time is shown anywhere** (a prayer holds many items; splitting time would be
invented math, and "longer is not better").

## addSubject carry inputs (2026-11-06)
`addSubject` takes `carry: Boolean = true` (false = save for private prayer
only) and `carryParent: Boolean = false` (for an intention whose name isn't
carried: carry the name too, which re-carries its intentions still flagged).
The server applies the pool check atomically in the same call and returns
whether the item (and parent) ended up carried, so the app can tell the user
if the result differs from the toggle. Preferred over addSubject +
setCarriedItems (two calls can race with another device).
- Returns the stored flags (`isCarried`, `parentCarried`) **and**
  `effectivelyCarried` (prints: own flag && parent's), which the app uses for
  the "Saved, but not carried" check.
- **All or nothing:** if the name + intention don't both fit, neither is
  carried (no partial carry); the item is still saved.
- `carryParent` where it has no effect (with `carry: false`, on a name, under
  Me, under a carried name) is ignored, not rejected. Free tier: carryParent
  can't succeed; the item saves uncarried.
- Re-carrying a name costs one place (Q32, 2026-11-08); its chosen
  intention comes back with it at no cost.
- **Known gap (accepted 2026-11-06):** read-then-write, so two devices adding
  at the same instant can both pass and exceed the pool by a little (same as
  setCarriedItems). No User version counter for now; the existing over-limit
  handling (trim on Your portion) covers it. Revisit if it shows up.

## Carry changes that reduce carrying are always allowed (2026-11-07)
`setCarriedItems` (and any carry-changing write) must accept a change that
only removes carrying (uncarry a name or intention) even while the user is
over their pool (e.g. a lapsed trial). Only changes that add carrying are
pool-checked. Today the backend blocks every carry change while over the
pool, so a lapsed-trial user can't trim from a person's page.

## Pool counts people (Q32, 2026-11-08)
- **Pool usage = carried names beyond the self name.** Intentions never count.
- **Per-person cap:** RTDB `/config` `intentionsPerPerson` (default 1). The
  server rejects a save that leaves a person (Me included) with more chosen
  intentions than the cap. Choosing a different intention is a swap (one off,
  one on in the same save) and is never pool-checked, only cap-checked.
- **Pool check** applies only to names going from off to on (the
  2026-11-07 "reductions always allowed" rule still holds).
- **addSubject:** a new intention is chosen when its person is under the cap;
  `carry: true` on an intention whose person is at the cap swaps it in
  (unchooses the other). `carryParent` carries the name (pool-checked).
- **Assembly** prints each carried person with their chosen intention(s); no
  "and N more".
- **Migration (beta data):** any person with more chosen intentions than the
  cap keeps the first by `sortOrder`; `includeLimit` free = 0. Production step
  for Eric when deployed.

