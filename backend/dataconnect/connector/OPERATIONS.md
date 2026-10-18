# +Prayer — Screen → Operation Map (MVP operation spec)

_Updated 2026-10-18 from `docs/product/schema-brief.md` §6 and the feature
files it cites. Schema: `../schema/schema.gql`._

Operations are designed from what each screen needs in ONE round trip. This maps
every MVP surface to the operation(s) that feed it, plus the write operations
behind user actions. This is the spec; the `.gql` connector files and the
Cloud Functions are implemented from this.

Legend for auth (SQL Connect spellings verified against the firebase-tools
15.22.1 prelude):
- **ANON** = `@auth(level: USER_ANON)` — any Firebase Auth user, INCLUDING
  anonymous. ⚠ SQL Connect's `level: USER` EXCLUDES anonymous accounts; since
  first run is anonymous-first and anonymous users get the full surface, never
  use `USER` here.
- **OWNER** = ANON + every row read/written is filtered or keyed by
  `auth.uid` (`owner: { id: { eq_expr: "auth.uid" } }`, `userId_expr:
  "auth.uid"`). Ownership of client-supplied ids is proven with a query step +
  `@check` inside the operation.
- **ADMIN** = `@auth(level: NO_ACCESS)` (the default) — runnable only via the
  Admin SDK from Cloud Functions. Eric's skills call admin-only callables that
  verify the `admin` custom claim.

Mechanisms available (prelude): `@transaction` on mutations; `@check(expr,
message)` on fields/steps; `@allow(fields, maxCount)` on `_Data` variables
(required whenever a `_Data` input is a variable — this is how a client is
limited to the fields it may set); `@redact`; native SQL `_select` /
`_selectFirst` / `_execute` / `_executeReturning` (SQL must be a string literal,
DML allowed, no DDL); `<table>_search` full-text on `@searchable` fields;
`_count` / `<field>_sum` aggregates. Functions react to mutations with
`onMutationExecuted` (`firebase-functions/dataconnect`), filterable by
service/connector/operation, region must match `us-central1`.

"Current list" everywhere = the GLOBAL-scope `PrayerList` with the latest
non-null `currentFrom`. It may still be `draft`.

---

## A. Reads (connector queries)

### Screen: Home (personal list + pinned today's-list row)
- **getCurrentListMeta** (ANON) — current PrayerList: id, listNumber, listDate,
  status, currentFrom, videoPublishedAt (null → "being filmed" placeholder),
  videoPath, sealVariant (null → unsealed state), soulCount, intentionCount,
  prayerCount (static seed; the live value comes from RTDB `/lists/current`
  and is stitched client-side). Never the roster of names (ADMIN only).
- **getMyHeader** (OWNER) — User: displayName, locale, timezone, planTier,
  includeLimit, trialStartedAt, entitlementExpiresAt, currentStreak,
  bestStreak, lastListLocalDate, graceDays, graceOfferPending,
  graceOffersEnabled, notification settings. "Prayed with the list today" =
  `lastListLocalDate == device local date` (client-side; drives the badge, the
  row text, and the local last-call cancel).
- **getMySubjects** (OWNER) — subjects WHERE status = ACTIVE (Answered
  intentions stay ACTIVE until archived): id, kind, parent { id }, publicName,
  personalLabel, isSelf, isCarried, sortOrder, avatarTone, avatarPath,
  resolution, resolvedAt. Client nests intentions under their parent, ordered
  by sortOrder within each level, self row pinned top.
  Per-row derived values: "last prayed" (latest `Prayer.localDate` via the
  user's links) and "prayed today". See implementation choices.
- Live numbers (`/stats/live`: prayingNow, prayedLastHour, prayedToday) come
  from RTDB subscriptions while foregrounded, NOT this connector.

### Screen: Today's list page (+ list row avatar cluster, Amen invitation)
- **getMyListStatus** (OWNER) — for the current list: my entries on it
  (publicName, kind, parentEntry, moderationStatus, reasonCategory) — "who's
  carried"; whether I've prayed with it (a Prayer with communityList = current
  since `currentFrom`); lifetime "You've been carried on N lists" (count of
  distinct lists with an entry owned by me).
- Post links: PrayerListPost rows for the list (ANON, metadata only), if the
  page shows them.

### Screen: Past lists
- **getPastLists** (ANON) — PrayerList rows (GLOBAL, published) newest first,
  paginated: listNumber, listDate, sealVariant, soulCount, intentionCount,
  prayerCount, videoPath, videoPublishedAt. No names.

### Screen: Your portion
- **getMyPortion** (OWNER) — the self subject + every ACTIVE, unresolved
  subject with its isCarried flag, nested and ordered as on Home; the user's
  entitlement (includeLimit, planTier, entitlementExpiresAt) for the meter
  (e.g. "17 / 15"); and my entries on the newest list with their
  moderationStatus ("Held for review" / "Not printed · {reasonCategory}").
  The illustrative print preview is rendered client-side from this.

### Screen: Name / Intention detail (one page for both)
- **getSubjectDetail** (OWNER) — ONE operation (stats-history.md):
  - the subject row (+ parent for an intention; child intentions for a name),
  - its PrayerListEntry rows joined to PrayerList: listNumber, listDate,
    sealVariant, prayerCount, and whether that list is the current one —
    powers the bead strand, "Off the list · N days" gaps, "On N lists", and
    the tier-3 world count,
  - the user's prayers that link this subject (filter `Prayer.user ==
    auth.uid`, never by subject owner): id, prayedAt, startedAt, localDate,
    durationSeconds, endedBy, listContextNumber, note.
  Client buckets prayers/beads into period rows; tier-1 raw = number of
  prayers returned, tier-1 cycles = distinct listContextNumber.
  **World-count stitch contract (unchanged):** sum prayerCount over CLOSED
  lists only (exclude the current list) + an "on current list" flag; the
  client adds the live RTDB count iff the flag is true. Paginate by period if
  histories get long.

### Screen: History (account-wide) + Prayer detail
- **getMyPrayerHistory** (OWNER) — the user's Prayer rows newest first,
  paginated: id, startedAt, prayedAt, durationSeconds, endedBy (AUTO → "~"),
  localDate, communityList { listNumber }, note, linked subjects
  (publicName/personalLabel). Grouped by day client-side.
- **getMyPrayerTime** (OWNER) — `durationSeconds_sum` this week and all time
  for the "Time in prayer" header. Never ranked.
- **getPrayer** (OWNER) — one prayer with its note and linked subjects (Prayer
  detail screen). May be folded into history if the page has the data.

### Streak sheet
- **getMyMonth** (OWNER, `$from`/`$to` local dates) — the user's prayers in the
  month: localDate, communityList { sealVariant } (null → hollow mark). Plus
  current/best streak and graceDays from getMyHeader. "Days in prayer this
  month" = distinct localDate.

### Screen: Archived
- **getMyArchivedSubjects** (OWNER) — subjects WHERE status = ARCHIVED
  (including RELEASED intentions). PURGED is never returned anywhere.

### Settings: reminders
- **getMyReminders** (OWNER) — ReminderPreference rows for the user.

---

## B. Writes (connector mutations — client-invoked, OWNER-scoped)

All take `@transaction`. Each `_Data` variable carries `@allow(fields: ...)`
listing exactly the client-settable fields; server-owned fields (entitlement,
streak, grace, isSelf, status transitions not listed here) are never in an
`@allow`.

- **addSubject** (OWNER) — kind, parent?, publicName, personalLabel?, note?,
  avatarTone?. Rules: INTENTION requires `parent` = one of my SOULs (query
  step + `@check`); SOUL has no parent; cap 40 / 80 grapheme clusters (client
  validates; see implementation choices for the server check); appended to
  the bottom (sortOrder = max + 1 in its level); `isCarried` auto-set true
  while the pool has room, else false and clearly marked as not on the list;
  rejected past the ~500-subject abuse cap ("contact us"). Kind is decided by
  where the user added it — there is no type change later.
- **updateSubject** (OWNER) — publicName, personalLabel, note, avatarTone
  (avatarPath later). Not kind, not parent. Not for the self subject's
  publicName (use updateSelfName).
- **updateSelfName** (OWNER) — sets the self subject's publicName AND
  `User.displayName` together, and `selfNameChangedAt`. Free until the self
  name is first printed; then once per 7 days (`@check` against
  `selfNameChangedAt`), with the next-available date returned for display.
- **setCarriedItems** (OWNER) — saves the "your portion" selection (list of
  subject ids to carry; all others → false). Blocked if over the entitlement
  (the client shows the paywall; declining returns to trim, never a silent
  choice). Self is always carried and is not counted; resolved items don't
  count toward the pool; free entitlement = 1 intention under "Me" only; an
  intention needs its name carried.
- **reorderSubjects** (OWNER) — set sortOrder for names, or for intentions
  within one name. Self ignored/pinned.
- **resolveIntention** (OWNER, `resolution`) — intentions only, never self.
  ANSWERED → resolvedAt + resolution (stays ACTIVE; frees its place
  immediately). RELEASED → resolvedAt + resolution + status ARCHIVED.
- **archiveSubject** (OWNER) — status → ARCHIVED. Blocked for isSelf.
- **restoreSubject** (OWNER) — status ARCHIVED → ACTIVE.
- **purgeSubject** (OWNER) — status → PURGED ("gone gone"; row persists).
  Blocked for isSelf.
- **updatePrayerNote** (OWNER) — NOTE ONLY. Edit Prayer.note; nothing else
  (duration, subjects, list are immutable historical fact). No deletion.
- **updateMySettings** (OWNER) — locale, timezone, listLiveOptIn,
  showNamesInNotifications, graceOffersEnabled.
- **upsertReminder** / **deleteReminder** (OWNER) — ReminderPreference rows
  (slot, enabled, localTime "HH:mm", label). One row per preset slot; CUSTOM
  may repeat up to the cap (5–7, later).

NOTE: logPrayer is a client mutation too, but has its own contract — see C.
Grace-offer answers change server-owned streak state, so they are a function
(D), not a connector mutation.

---

## C. logPrayer — optimistic, idempotent client write

DECIDED: optimistic client write (offline-capable; praying at a sentimental
place without signal must not fail). Written ONCE per prayer session, at
Amen (the list invitation extends the same prayer). Under 5s nothing is
written.

Inputs: `id` (client-generated UUID v4), startedAt, prayedAt (end),
durationSeconds (≥5, `@check` on vars), localDate + timezone (device, at
START), communityListId? (set iff the list was included), listContextNumber
(list current at START), note?, subjectIds[].

Writes (one `@transaction`): `prayer_insert` with `userId_expr: "auth.uid"`,
endedBy AMEN, mode MANUAL; then `prayerSubjectLink_insertMany` for each
subject. A query step `@check`s that every subjectId is owned by `auth.uid`
(MVP; group sharing later widens this). Holding an intention also links its
parent name: the client sends both (the selection UI already holds the name),
and onPrayerLogged adds a missing parent link defensively.

Idempotency: the PK is the client id, so a retried send hits a duplicate key
and the whole transaction rolls back — the client treats "already exists" as
success. Do NOT use `_upsert`: it would let a client rewrite an existing
prayer, breaking immutability.

Side effects happen as REACTIONS, not inside logPrayer (keeps the write pure
and offline-friendly): see onPrayerLogged.

---

## D. Reactions & server/admin (Cloud Functions — ADMIN / event-driven)

- **onAuthUserCreated** (auth trigger) — create User + self PrayerSubject
  (kind SOUL, isSelf, personalLabel "Me", isCarried true) in one transaction.
  MUST detect anonymous → permanent LINKING and NOT create a second User.
  The self name is collected on the "What's your name?" step and written via
  updateSelfName (free, not yet printed).
- **onPrayerLogged** (`onMutationExecuted`, filter operation = logPrayer; the
  auto-save job calls the same handler directly). Must not trigger on its own
  writes. Does:
  - add any missing parent-name links;
  - if communityList is set: bump that list's prayerCount and mirror to RTDB
    `/lists/current`; update currentStreak / bestStreak / lastListLocalDate
    from `localDate` (list days only — personal-only prayers never extend it);
    grace: consume banked days for consecutive missed days, break the streak
    if misses exceed the bank (bank unchanged), and every 7 real list days set
    graceOfferPending (or the "grace days are full" acknowledgement) unless
    graceOffersEnabled = false;
  - on the user's first prayer: set trialStartedAt and the trial entitlement
    (14 days);
  - feed last-hour / today counts for `/stats/live`.
- **answerGraceOffer** (callable, owner) — accept → graceDays + 1 (≤ cap) and
  clear graceOfferPending; decline → clear; "Don't offer again" → also
  graceOffersEnabled = false.
- **assembleNextList** (ADMIN callable, manual ~6am MT) — one command:
  1. settle list N: freeze the final RTDB count into `PrayerList.prayerCount`;
  2. ingest the 🙏 harvest as ExternalPerson (SOCIAL) rows;
  3. create N+1 as draft with `currentFrom = now` (N+1 is current from here);
  4. draft N+1 entries with set-based native SQL (`_execute` INSERT … SELECT,
     names never leave Postgres): users passing the gate (prayed with the
     list since N's `currentFrom` OR within the last 30h — server param) →
     self + isCarried, ACTIVE, unresolved items up to the entitlement (free:
     intentions under Me only; an intention only if its name is carried),
     with `parentEntry` linking intentions to their name's entry; + social
     ExternalPersons from the harvest; + active base set (activeUntil null or
     future). Freeze publicName/kind; source app | social | base_set; exactly
     one of subject / externalPerson per row;
  5. auto-flag (moderationStatus held + reasonCategory): profanity/blocklist,
     phone/email/URL, frequent self-name changes. Not flagged: all-caps,
     brand-new accounts;
  6. update soulCount / intentionCount.
- **moderateEntry** (ADMIN) — held → approved / excluded, set heldReason +
  reasonCategory.
- **publishList** (ADMIN) — status draft → published, publishedAt,
  sealVariant (weekday → wax mapping).
- **publishListVideo** (ADMIN, ~8am) — videoPublishedAt, videoPath (Storage
  `videos/`), PrayerListPost rows; sends the opt-in FCM "Today's list is live"
  to users with listLiveOptIn. (Merge with publishList if the skill does both
  in one step.)
- **autoSavePrayerDrafts** (scheduled) — finalize RTDB drafts idle > 6h as a
  Prayer with endedBy AUTO; estimated duration = last foreground moment + up
  to 30 min, capped at 4h from start; localDate/listContextNumber from the
  START. Then run onPrayerLogged.
- **presencePublisher** (RTDB-triggered) + **presenceReconcile** (1-min
  schedule) — aggregate private `/presence/{uid}/{deviceId}` into public
  `/stats/live` (prayingNow counts people, not devices), republished ≥5s apart.
- **setEntitlement** (ADMIN) — planTier / includeLimit / entitlementExpiresAt
  from a verified billing event. Never client-writable.
- **deleteAccount** (callable, owner) — immediate after one confirmation:
  strip publicName from the user's past PrayerListEntry rows (owner and
  subject are SET NULL by the FK when the user and subjects are deleted;
  counts remain), then delete the User (cascades to subjects, prayers, links,
  reminders) and the Auth user.

### Data & migration (admin scripts, run once / as needed)
- Backfill lists 1..N + participants from `publishing/lists.json` /
  `participants.json`: PrayerList (numbers, dates, counts, sealVariant from
  weekday, `currentFrom`), PrayerListPost, ExternalPerson, PrayerListEntry.
- Import the NamUs base set as ExternalPerson (BASE_SET).
- Cut the harvest / publish skills over to the admin functions before launch.

---

## Auth summary
- OWNER: all of a user's own subjects, prayers, header, portion, detail,
  history, month, archived, reminders, settings, and every B/C write.
- ANON (metadata only): getCurrentListMeta, getPastLists, post links — counts,
  numbers, seals, video; never names.
- ADMIN/NO_ACCESS: the full roster (PrayerListEntry beyond the user's own),
  ExternalPerson, assembly, moderation, publish, entitlement, streak/grace
  writes, user creation.
- Anonymous users get the full OWNER/ANON surface. Use `USER_ANON`, never
  `USER` (which excludes anonymous accounts).

## Open implementation choices (decide against real query ergonomics)
- Rule enforcement in connector mutations vs. callables: the pool limit
  (setCarriedItems, addSubject auto-carry), the ~500 cap, the self-name rate
  limit, and server-side grapheme caps are awkward in CEL `@check`s. Fallback:
  make those writes callables using the Admin SDK.
- getMySubjects per-row "last prayed": inline nested aggregate vs. a
  companion `_select` keyed by user.
- Search: `prayerSubjects_search` (full-text over publicName + personalLabel,
  `simple` config) vs. client-side filtering of the already-loaded list
  (≤500 rows).
- The "exactly one of subject / externalPerson" rule has no CHECK directive.
  It is guaranteed by assembleNextList as the only writer. A real Postgres
  CHECK would have to be added by hand (`dataconnect:sql:shell`) and needs
  `schemaValidation: COMPATIBLE`.
