# +Prayer — Screen → Operation Map (MVP operation spec)

_Updated 2026-10-18 from `docs/product/schema-brief.md` §6 and §8 (review
answers) and the feature files it cites. Schema: `../schema/schema.gql`._

Operations are designed from what each screen needs in ONE round trip. This maps
every MVP surface to the operation(s) that feed it, plus the write operations
behind user actions. This is the spec; the `.gql` connector files and the
Cloud Functions are implemented from this.

**Implemented (2026-10-18):** client connector `connector/queries.gql`,
`connector/mutations.gql` (Dart SDK → `app/lib/dataconnect_generated`);
server-only connector `../admin/*.gql` (NO_ACCESS, called by the functions);
Cloud Functions in `backend/functions/src` (one module per area; `index.ts`
wires triggers and callables). Operation names below are in `camelCase`; the
`.gql` names are the same in `PascalCase` (e.g. getMyHeader → `GetMyHeader`).

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

Two computed rules used throughout (never swept by a job):
- **Effective carry** — an intention is carried only if `isCarried &&
  parent.isCarried`; the pool counts only effectively carried items beyond the
  self name.
- **Effective entitlement** — `includeLimit` while `entitlementExpiresAt` is in
  the future (or a subscription is active); otherwise the free limit (1, an
  intention under "Me"). Trial and base tier both grant `basePremiumPool`
  (server config, 10).

---

## A. Reads (connector queries)

### Screen: Home (personal list + pinned today's-list row)
- **getCurrentListMeta** (ANON) — current PrayerList: id, listNumber, listDate,
  status, currentFrom, closesAt (initial value; open apps get it live from
  RTDB `/lists/current` → in-app "List N closes in 5 minutes" banner for
  anyone who hasn't prayed with the list; no push),
  videoPublishedAt (null → "being filmed" placeholder),
  videoPath, sealVariant (null → unsealed state), soulCount, intentionCount,
  prayerCount (static seed; the live value comes from RTDB `/lists/current`
  and is stitched client-side). Never the roster of names (ADMIN only).
- **getMyHeader** (OWNER) — User: displayName, locale, timezone, planTier,
  includeLimit, trialStartedAt, entitlementExpiresAt, currentStreak,
  bestStreak, lastListLocalDate, graceDays, graceOfferPending,
  graceOffersEnabled, notification settings. Also drives state-based
  onboarding resume: no User / displayName null (no self subject yet) →
  "What's your name?"; otherwise → main screen.
  Client-side from these fields: "prayed with the list today" =
  `lastListLocalDate == device local date` (badge, row text, local last-call
  cancel), and the EFFECTIVE streak — stored streak, or 0 once the missed days
  since lastListLocalDate exceed graceDays — so a break shows before the next
  write.
- **getMySubjects** (OWNER) — subjects WHERE status = ACTIVE (Answered
  intentions stay ACTIVE until archived): id, kind, parent { id }, publicName,
  personalLabel, isSelf, isCarried, sortOrder, avatarTone, avatarPath,
  resolution, resolvedAt. Client nests intentions under their parent, ordered
  by sortOrder within each level, self row pinned top.
  Per-row derived values: "last prayed" (latest `Prayer.localDate` via the
  user's links) and "prayed today". See implementation choices.
- **searchMySubjects** (OWNER) — header search: `prayerSubjects_search` over
  publicName + alias (`simple` config, any script); never PURGED.
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
  subject with its isCarried flag, nested and ordered as on Home (client
  applies effective carry); the user's entitlement (includeLimit, planTier,
  entitlementExpiresAt, trialStartedAt) for the meter (e.g. "17 / 15", against
  the effective entitlement); and my entries on the given (newest) list with
  their moderationStatus ("Held for review" / "Not printed · {reasonCategory}").
  No active entitlement (trial ended or subscription lapsed) + effective carry
  still over the free limit = "Waiting for your choice" (the soft landing). The illustrative print preview is rendered
  client-side from this.

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
  prayers returned, tier-1 cycles = distinct listContextNumber. Entries come
  with their moderationStatus: only APPROVED ones were printed and count.
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

## B. Writes (client-invoked, OWNER-scoped)

Resolved (was an open choice): writes that need the pool, grapheme caps, the
~500 cap, or the self-name limit are **callables** (functions, Admin SDK);
the rest are **connector mutations**, scoped with
`<table>_updateMany(where: { id, owner = auth.uid })` + `@check(this == 1)` so
a foreign or missing id fails plainly and changes nothing.

Callables (`functions/src/subjects.ts`):
- **addSubject** — kind, parentId?, publicName, personalLabel?, note?. INTENTION
  needs `parentId` = one of my ACTIVE names; SOUL has none. Caps 40 / 80
  grapheme clusters (alias 40, note 1000 — see ambiguities). Appended to the
  bottom of its level. `isCarried` auto-set while the pool (effective carry vs.
  effective entitlement) has room, else false and marked not on the list.
  Rejected past the ~500 cap ("contact us").
- **updateSubject** — publicName, personalLabel, note on a non-self item. Not
  kind, not parent. The self name uses setSelfName.
- **setCarriedItems** — the "your portion" save: exactly these ids carried.
  Over the effective entitlement → `failed-precondition` with
  `{ reason: "OVER_LIMIT", carried, limit, free }` for the meter/paywall;
  nothing is trimmed. Uncarrying a name leaves its intentions' own flags
  intact (they stop counting); re-carrying brings them back through the same
  check.

Connector mutations (`connector/mutations.gql`):
- **reorderSubjects** (`orderedIds`) — one level (names, or one name's
  intentions) in its new order. Self ignored/pinned.
- **markIntentionAnswered** — resolvedAt + ANSWERED (stays ACTIVE; frees its
  place immediately). **releaseIntention** — resolvedAt + RELEASED + ARCHIVED.
  Only open (unresolved, ACTIVE) intentions; never self.
- **archiveSubject** — ARCHIVED. On a name, its ACTIVE intentions too, with
  `archivedByCascade = true`. Blocked for isSelf.
- **restoreSubject** — ARCHIVED → ACTIVE. On a name, brings back ONLY its
  intentions with `archivedByCascade = true` (flag cleared) — never Released
  ones or ones archived on their own. An intention whose name is still
  archived can't be restored on its own ("Restore its name first").
- **purgeSubject** — PURGED ("gone gone"; row persists); on a name, all its
  intentions too. Blocked for isSelf.
- **setSubjectAvatarTone** — palette index, or null for the hash default.
- **updatePrayerNote** — NOTE ONLY. Duration, items, list are immutable. No
  deletion.
- **updateMySettings** — locale, timezone, listLiveOptIn,
  showNamesInNotifications, graceOffersEnabled (omitted = unchanged).
- **createReminder** / **updateReminder** / **deleteReminder** — slot, enabled,
  localTime "HH:mm", label. One row per preset slot; CUSTOM may repeat (its
  5–7 cap ships with custom reminders).

setSelfName, mergeAccounts, answerGraceOffer, syncAccount, deleteAccount are
callables too (D).

---

## C. logPrayer — optimistic, idempotent client write

DECIDED: optimistic client write (offline-capable; praying at a sentimental
place without signal must not fail). Written ONCE per prayer session, at
Amen (the list invitation extends the same prayer). Under 5s nothing is
written.

Inputs: `id` (client-generated UUID v4), startedAt, prayedAt (end),
durationSeconds (5 s – 4 h, `@check` on vars), localDate + timezone (device,
at START), communityListId? (set iff the list was included), listContextNumber
(list current at START), note?, subjectIds[].

Write: ONE native statement — the Prayer (endedBy AMEN, mode MANUAL, user =
auth.uid) and its PrayerSubjectLinks. Only subjects owned by the caller are
linked (others silently skipped; group sharing later widens this), and holding
an intention links its parent name too — in the same statement. A
communityListId that isn't a real list is stored as null.

Idempotency: `ON CONFLICT (id) DO NOTHING` — a retried send with the same id is
a no-op success, never an overwrite (history stays immutable).

Side effects happen as REACTIONS, not inside logPrayer (keeps the write pure
and offline-friendly): see onPrayerLogged.

---

## D. Reactions & server/admin (Cloud Functions — ADMIN / event-driven)

- **onAuthUserCreated** (auth trigger) — create the User ONLY (displayName
  null). Linking keeps the uid and fires no create, so no second User.
- **syncAccount** (callable) — called after sign-in / linking: refreshes
  authProvider / isAnonymous. Every user callable also ensures the User row
  exists (covers the trigger landing after the app's first call).
- **setSelfName(name)** (callable, owner, idempotent) — first call (the
  "What's your name?" step, required before the main screen) creates the self
  PrayerSubject (kind SOUL, isSelf, personalLabel "Me", isCarried true) and
  sets User.displayName. The self subject's id is derived from the uid, so a
  double-tap can never create two. Later calls are self-name edits: publicName + displayName +
  selfNameChangedAt together; free until the self's first APPROVED entry on a
  PUBLISHED list, then once per 7 days, returning the next-available date.
  40-grapheme cap.
- **mergeAccounts(anonIdToken)** (callable, the signed-in existing user) —
  after a credential-in-use conflict where both accounts have data and the
  user chose [Merge both] (an empty anon account just switches silently).
  Verifies the anon token, then in ONE atomic statement: reassign the anon's
  non-self subjects (sortOrder appended); re-parent the anon self's
  intentions to the existing self; re-point the anon self's links and entries
  to the existing self (drop the anon entry where both selves are on the same
  list); reassign prayers; recompute the streak from the merged list days,
  bestStreak = max, graceDays = max (capped), trialStartedAt = earliest, keep
  the active entitlement, keep the existing user's reminder prefs. Then delete
  the anon User + Auth user and move its RTDB nodes. The UI warns that
  duplicates may need cleanup.
- **onPrayerLogged** (`onMutationExecuted`, filter operation = LogPrayer; the
  auto-save job calls the same handler directly; **sweepUncountedPrayers**
  every 10 min re-runs it for any prayer the trigger missed). EXACTLY ONCE:
  `Prayer.countedAt` is claimed in the same statement as every increment
  (`admin/prayers.gql` ApplyPrayer), with an optimistic check on the user's
  streak/grace/trial fields (re-read + retry on conflict). All counters are
  increment-on-write and never recounted from rows. Does:
  - always: on the DailyStats row for the UTC day of the prayer's END
    (`prayedAt`), increment prayers / prayerSeconds; if `User.lastStatsDate`
    differs from that day, increment peoplePraying and set lastStatsDate;
  - if communityList is set and that list is still current and the prayer
    started before its closesAt: increment its prayerCount and prayerSeconds
    and mirror the count to RTDB `/lists/current` (a closed list's numbers are
    final);
  - if communityList is set: update
    currentStreak / bestStreak / lastListLocalDate from `localDate` (list days
    only — personal-only prayers never extend it). Grace is consumed LAZILY
    here: missed days since lastListLocalDate ≤ graceDays → consume that many
    and continue; else reset the streak (bank unchanged). Every 7 real list
    days set graceOfferPending (or the "grace days are full"
    acknowledgement) unless graceOffersEnabled = false;
  - on the user's first prayer: set trialStartedAt, entitlementExpiresAt =
    +14 days, includeLimit = basePremiumPool — unless an entitlement is
    already active (bought before praying).
- **answerGraceOffer** (callable, owner) — accept → graceDays + 1 (≤ cap) and
  clear graceOfferPending; decline → clear; "Don't offer again" → also
  graceOffersEnabled = false.
- **closeList** (ADMIN callable) — Eric's skill sets the current list's
  `closesAt = now + 5 min` shortly before the morning routine (the exact
  cutoff) and mirrors it to RTDB `/lists/current.closesAt`, so open apps show
  the banner without re-fetching.
- **assembleNextList** (ADMIN callable, manual ~6am MT, after closesAt) — one
  command:
  1. settle list N: nothing to copy — N's prayerCount / prayerSeconds are
     already final (Postgres is the counter; RTDB only mirrors it, and only
     the current list's counters move);
  2. ingest the 🙏 harvest as ExternalPerson (SOCIAL) rows;
  3. create N+1 as draft with `currentFrom = N.closesAt` (N+1 is current from
     here);
  4. draft N+1 entries — steps 2–5 are ONE native statement (`admin/lists.gql`
     AssembleList), names never leave Postgres; if N+1 already exists nothing
     is written. GATE — a user qualifies if they have a
     prayer with (a) `communityList` = N, started before `N.closesAt` and
     committed before assembly runs, OR (b) the list included and ended
     (`prayedAt`) within 30h of assembly (server param). Per qualifying user:
     self + effectively carried, ACTIVE, unresolved items up to the EFFECTIVE
     entitlement (free: intentions under Me only), with `parentEntry` linking
     intentions to their name's entry. SOFT LANDING (any entitlement end —
     trial or lapsed subscription): no active entitlement and the effective
     carry still over the free limit (= the choice not yet made) → keep
     carrying the full portion for up to 7 days after entitlementExpiresAt;
     after that only the self name until they choose. Store billing grace
     periods count as active, so the 7 days start after them. Plus social ExternalPersons from the
     harvest and the active base set (activeUntil null or future). Freeze
     publicName/kind; source APP | SOCIAL | BASE_SET; exactly one of subject /
     externalPerson per row;
  5. auto-flag (moderationStatus HELD + reasonCategory): blocklist
     (`MODERATION_BLOCKLIST` param, whole words) → LANGUAGE; phone/email/URL →
     CONTACT_OR_LINK; a self name changed since the closing list became
     current, after it was first printed → NAME_CHANGES (see ambiguities).
     Not flagged: all-caps, brand-new accounts, base-set names;
  6. RecountList: soulCount / intentionCount (draft: everything not
     EXCLUDED). Returns the new list id/number, counts, and how many are held.
- **getHeldEntries** (ADMIN) — the auto-flagged entries to review.
- **moderateEntry** (ADMIN) — HELD → APPROVED / EXCLUDED, set heldReason +
  reasonCategory (OTHER = "Didn't meet list guidelines"); EXCLUDED requires a
  category (users see it). Recounts the list.
- **getListForPrint** (ADMIN) — APPROVED entries with owner / parentEntry /
  sortOrder so the print step can group each portion.
- **publishList** (ADMIN) — status draft → published, publishedAt,
  sealVariant from the weekday of listDate (Sunday = 0 … Saturday = 6, the
  ritual/CLAUDE.md rotation); recounts APPROVED only.
- **publishListVideo** (ADMIN, ~8am) — videoPublishedAt, videoPath (Storage
  `videos/…`), PrayerListPost rows; sends the opt-in FCM "Today's list is
  live" to the `list-live` topic (the app subscribes/unsubscribes alongside
  User.listLiveOptIn — no device tokens are stored).
- **autoSavePrayerDrafts** (scheduled) — finalize RTDB drafts idle > 6h as a
  Prayer with endedBy AUTO; estimated duration = last foreground moment + up
  to 30 min, capped at 4h from start; localDate/listContextNumber from the
  START. Uses the draft's `prayerId` if it has one (so a late Amen from the
  device can't also land), else an id derived from uid/device/start. Under 5 s
  → discarded. Then runs onPrayerLogged and removes the draft.
- **presencePublisher** (RTDB-triggered) + **presenceReconcile** (1-min
  schedule) — aggregate private `/presence/{uid}/{deviceId}` into public
  `/stats/live` (prayingNow counts people, not devices; prayedLastHour =
  people who finished a prayer in the last hour; prayedToday = DailyStats
  peoplePraying for the UTC day), republished ≥5s apart.
- **setEntitlement** (ADMIN) — planTier / includeLimit / entitlementExpiresAt
  from a verified billing event. Never client-writable. entitlementExpiresAt
  is written THROUGH any store billing grace period (the entitlement stays
  active during it), so the soft landing starts only after grace ends.
- **deleteAccount** (callable, owner) — immediate after one confirmation:
  delete the user's PrayerListEntry rows, then the User (cascades to
  subjects, prayers, links, reminders), then the Auth user and RTDB nodes.
  Stored list counts, prayerSeconds and DailyStats are unaffected
  (increment-on-write, never recounted).

### Data & migration (admin scripts, run once / as needed)
Operations exist (`admin/lists.gql` InsertList, UpsertBaseSetPerson); the
import scripts themselves are not written yet.
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
  ExternalPerson, DailyStats, closeList, assembly, moderation, publish,
  entitlement, streak/grace writes, user creation, self-subject creation
  (setSelfName), mergeAccounts.
- Anonymous users get the full OWNER/ANON surface. Use `USER_ANON`, never
  `USER` (which excludes anonymous accounts).

## Implementation notes (verified against the emulator, firebase-tools 15.22.1)
- Native SQL: list variables bind as JSON text and an EMPTY list binds as JSON
  null — always read arrays through the `jsonb_typeof(...) = 'array'` guard.
- Never put a native SQL field next to other fields under `@transaction`: the
  engine batches them into one invalid statement. Atomic multi-step writes are
  ONE `_execute` statement of data-modifying CTEs; validation runs first in a
  `query @redact` step with `@check` (a failed check stops the operation).
- `_executeReturning` wraps its SQL, so it takes plain `DML … RETURNING` only.
- SQL Connect returns UUIDs as 32 hex digits (no dashes); ids written to RTDB
  use the same form.
- firebase-admin caches DataConnect instances per app by location+service
  (the connector is ignored) — one connector per app.
- The "exactly one of subject / externalPerson" rule has no CHECK directive;
  the only writers (assembly, backfill, merge) guarantee it.
