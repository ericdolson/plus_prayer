# Schema Brief — handoff for the backend session

_Written 2026-10-18 from the product meetings of 2026-10-17/18._
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
| `displayName` | keep; mirrors the self-subject's `publicName` (one name field) | auth-onboarding |
| `locale: String` | ADD — effective UI language (device or override) | screens (Language) |
| `timezone: String` | ADD — IANA, updated from device | streaks-reminders |
| `includeLimit: Int` | REDEFINE — size of the carried pool **beyond the self name**. Free = 1, restricted to intentions under the self name ("Me"). Premium = N names/intentions | monetization |
| `trialStartedAt`, `entitlementExpiresAt: Timestamp` | ADD — 14-day no-card reverse trial, starts at first prayer | monetization |
| `currentStreak`, `bestStreak` | keep — streak = **local days prayed WITH THE LIST** | streaks-reminders |
| `lastPrayedListNumber` | REMOVE → `lastListLocalDate: Date` | streaks-reminders |
| `graceDays: Int` (0–cap), `graceOfferPending: Boolean`, `graceOffersEnabled: Boolean` | ADD | streaks-reminders |
| `selfNameChangedAt: Timestamp` | ADD — free edits until first printed, then 1 / 7 days | auth-onboarding |
| `listLiveOptIn: Boolean` (default false), `showNamesInNotifications: Boolean` (default true) | ADD | notifications |
| `prayerVoice: String`, `prayerVoiceConsentAt: Timestamp` | ADD (nullable seam, unused at MVP) — religion is special-category data | prayer-flow (guided) |

### ReminderPreference — NEW
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
| `isCarried: Boolean` | ADD — user's choice to print; auto-set true on create while the pool has room | monetization |
| `sortOrder` | keep — manual order only (names; intentions within a name); new items at bottom | subjects |
| `avatarTone: Int` | ADD — palette index; default from hash of id | prayer-flow |
| `avatarPath: String` | ADD (nullable seam for photos, private Storage) | prayer-flow |
| `answeredAt` | REMOVE → `resolvedAt: Timestamp` + `resolution` enum (ANSWERED \| RELEASED) | subjects |
| `status` | keep ACTIVE \| ARCHIVED \| PURGED. RELEASE also sets ARCHIVED | subjects |
| `groupId` / `visibility` | **DO NOT ADD** — groups will use a Share table (§4) | roadmap |

Constraints: self-subject forced ACTIVE, not carried-toggleable, not resolvable.
Resolved items are never list-eligible. Soft abuse cap ~500 subjects per user
(server check, not a paywall).

### PrayerList — changes
| Field | Change | Why / spec |
|---|---|---|
| `scope` enum | ADD, default GLOBAL; uniqueness becomes **(scope, listNumber)** | roadmap (future church lists) |
| `currentFrom: Timestamp` | ADD — moment this list became current (the flip). Needed by the gate rule "since the last flip" | list-lifecycle |
| `sealVariant: Int` (0–6) | ADD — set at publish from the weekday→wax mapping | list-lifecycle |
| `videoPath: String` | ADD — Firebase Storage object for the self-hosted video | list-lifecycle |
| `status`, `publishedAt`, `videoPublishedAt`, counts | keep; `prayerCount` still settles on close | list-lifecycle |

### ExternalPerson — NEW
`source` (SOCIAL | BASE_SET), `platform?`, `externalId` (platform user id or
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
| `source` | app \| social \| base_set |
| `moderationStatus`, `heldReason` | keep; ADD `reasonCategory` (shown to users as "Not printed · {category}") |
| `publicName`, `kind` | keep — frozen snapshots |

This table is also the **bead strand** source (with `PrayerList.sealVariant`).
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
per-item "last prayed" (local date) · bead strand + "Off the list · N days" gaps
· period rows (prayers, notes count, answered marker) · "Days in prayer this
month" · "carried on N lists" · answered running total · prayer time per prayer
/ week / all time. Only the user streak/grace fields and list counts are stored.

## 3. Realtime Database
- `/presence/{uid}/{deviceId}` (owner-write): `startedAt`, `lastActiveAt`
  (heartbeat ~1/min in foreground), `inForeground`, `listIncluded`, `itemIds[]`
  (IDs only). Doubles as the in-progress prayer draft. `onDisconnect` marks
  background/disconnect; counts as praying for ~30 min after backgrounding.
- `/stats/live` (server-write, public-read): `prayingNow` (people, not devices),
  `prayedLastHour`, `prayedToday`, `updatedAt` — republished ≥5s apart + 1-min
  reconcile. Clients subscribe only while foregrounded.
- `/lists/current` (server-write, public-read): `listNumber`, live `prayerCount`.

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
| Grace cap / interval | Remote Config + server enforcement | 2 / 7 list days |
| Presence display threshold | Remote Config | 10 |
| Min app version | Remote Config | — |
| Subject abuse cap | server | ~500 |

## 6. Functions & operations to add/revise (update OPERATIONS.md)
- **onAuthUserCreated** — User + self subject ("Me" alias), handle anon linking.
- **logPrayer** (client mutation) — idempotent by client id; writes Prayer + links
  (intention ⇒ parent link). **onPrayerLogged** — list count, streak (list days
  only), grace earning/use/offers, trial start on first prayer.
- **assembleNextList** (admin) — settle N; set N+1 `currentFrom`; gate =
  prayed with list since last flip OR within 30h; per user: self + carried,
  ACTIVE, unresolved items up to entitlement (free: intentions under Me only;
  intention requires its name carried); + social ExternalPersons from harvest +
  active base set; freeze names; auto-flag (profanity/blocklist, phone/email/URL,
  frequent self-name changes); write `parentEntry`.
- **autoSavePrayerDrafts** (scheduled) — finalize drafts idle >6h (endedBy AUTO).
- **presencePublisher** + reconcile.
- **publishList / publishListVideo** (admin) — status, `videoPublishedAt`,
  `videoPath`, `sealVariant`, post rows.
- **moderateEntry**, **setEntitlement** (admin); **deleteAccount** (strip
  names/owner from past entries, keep counts).
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
