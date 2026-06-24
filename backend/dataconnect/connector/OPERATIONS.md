# +Prayer — Screen → Operation Map (MVP operation spec)

Operations are designed from what each screen needs in ONE round trip. This maps
every MVP surface to the operation(s) that feed it, plus the write operations
behind user actions. This is the spec; the `.gql` connector files and the
Cloud Functions are implemented from this.

Legend for auth: USER = any signed-in user (incl. anonymous). OWNER = USER + the
row's owner == auth.uid. ADMIN = NO_ACCESS to clients (server/function only).

---

## A. Reads (connector queries)

### Screen: Home / "Pray" surface
What it shows: the current list's public-facing state + the live presence/count
numbers + the user's prayer entry point.
- **getCurrentListMeta** (USER) — current PrayerList: listNumber, listDate,
  status, videoPublishedAt (null → show "being filmed" placeholder; set → show
  video), soulCount, intentionCount, prayerCount (static seed; live value comes
  from RTDB and is stitched client-side). Does NOT return the roster of names
  (that's ADMIN-only).
- Live numbers ("praying now", live prayerCount) come from RTDB subscriptions,
  NOT this query. Client stitches live + static.

### Screen: My Subjects (the main list of tiles)
What each tile shows: subject publicName/personalLabel, kind, on-current-list
status, current per-subject streak, today's prayer count for that subject.
- **getMySubjects** (OWNER) — all of the user's subjects WHERE status = ACTIVE,
  ordered by sortOrder (self pinned first). For each: id, kind, publicName,
  personalLabel, answeredAt, sortOrder, isSelf.
  - Per-tile derived values (on-current-list, streak, today-count) — see note
    below on whether to derive inline or in a companion query.
- **getMyHeader** (OWNER) — the user's own streaks/entitlement for the screen
  header: currentStreak, bestStreak, includeLimit, planTier, and a derived
  "have I prayed the current list yet" boolean (drives the pray CTA state).

NOTE on tile stats: on-current-list + today-count + per-subject streak are
DERIVED. Two options: (1) a single richer getMySubjects that joins the
derivations per subject (one operation, heavier query), or (2) getMySubjects for
the base rows + one companion aggregate query keyed by the current list. Prefer
(1) if it stays one operation; fall back to (2) if the join gets unwieldy.
Decide at implementation against real query ergonomics.

### Screen: Subject full-page
What it shows: everything from the tile PLUS total prayers (tier-1), best streak
for the subject, answered status, and entry points to drill-downs.
- **getSubjectDetail** (OWNER) — the subject row + derived: tier-1 total
  ("I prayed N times", raw count of PrayerSubjectLink), tier-1 cycle count
  (distinct listContextNumber), per-subject current & best streak, on-current-
  list boolean.
- **getSubjectWorldCount** (OWNER) — tier-3 static + live boolean for the
  client stitch: SUM(prayerCount) over the subject's CLOSED lists (current
  EXCLUDED) + boolean "is on current list". Client adds live RTDB value iff true.
  (Kept separate because it's the one with the live-stitch contract.)

### Screen: Subject drill-downs (stats)
What it shows: which lists the subject has been on; prayers-per-cycle; history.
- **getSubjectLists** (OWNER) — the PrayerListEntry rows for this subject joined
  to PrayerList (listNumber, date, that list's prayerCount). Powers "lists Mom
  has been on" and the per-list contribution to the world-count.
- **getSubjectPrayerHistory** (OWNER) — the user's prayers that included this
  subject (via PrayerSubjectLink → Prayer): prayedAt, durationSeconds,
  listContextNumber, note. Powers prayers-per-cycle / timeline.

### Screen: My Prayer history (account-wide)
- **getMyPrayerHistory** (OWNER) — the user's Prayer rows: prayedAt, duration,
  communityList, listContextNumber, note, location. Paginated (limit/offset).

### Screen: Archived subjects
- **getMyArchivedSubjects** (OWNER) — subjects WHERE status = ARCHIVED, so the
  user can restore. (PURGED never returned anywhere.)

### Screen: "Am I on the current list?" (per-subject badge anywhere)
Covered by the on-current-list boolean inside getMySubjects/getSubjectDetail —
an existence check on PrayerListEntry for (current list, subject). No separate op.

---

## B. Writes (connector mutations — client-invoked, OWNER-scoped)

- **addSubject** (OWNER) — create a PrayerSubject (kind, publicName,
  personalLabel?, note?). status defaults ACTIVE; sortOrder appended.
- **updateSubject** (OWNER) — edit publicName/personalLabel/note/kind.
- **reorderSubjects** (OWNER) — set sortOrder across the user's subjects (drives
  the above/below-the-fold cutoff). Self ignored/pinned.
- **markIntentionAnswered** (OWNER) — set answeredAt (intentions only).
- **archiveSubject** (OWNER) — status → ARCHIVED. Blocked for isSelf.
- **restoreSubject** (OWNER) — status ARCHIVED → ACTIVE.
- **purgeSubject** (OWNER) — status → PURGED ("gone gone"; row persists). Blocked
  for isSelf.
- **updatePrayer** (OWNER) — NOTE ONLY. Edit Prayer.note; nothing else (duration,
  subjects, list are immutable historical fact). No prayer deletion.

NOTE: logPrayer is intentionally NOT here — see C (optimistic write + the
community-list rule).

---

## C. logPrayer — optimistic client write

DECIDED: optimistic client-side write (offline-capable; the sentimental-place-
without-signal case must not fail), UI-validated, with server-side reconciliation
DEFERRED. So logPrayer is a client mutation that writes Prayer + the
PrayerSubjectLink rows directly.

Inputs from client: durationSeconds, includedSubjectIds[], note?, location?,
and whether this is the user's community prayer for the current list.
Writes: one Prayer (communityList = current list IF this is the community prayer,
else null; listContextNumber = current list number ALWAYS) + a PrayerSubjectLink
per included subject.

Rule (UI-enforced now): a user must do their community prayer for the current
list before logging personal-only prayers against it; the first qualifying
community prayer is what makes their ACTIVE subjects eligible for the next list.
Server reconciliation of this rule is deferred (accepted interim gap; logged in
decisions.md).

Side effects happen as REACTIONS, not inside logPrayer (keeps the write pure and
offline-friendly): see D.

---

## D. Reactions & server/admin (Cloud Functions — ADMIN / event-driven)

Wiring caveat: Data Connect writes to Postgres; "react to a row insert" may be a
true DB trigger OR simply the same function calling these in sequence. Designed
as separable units; confirm wiring against current DC docs.

- **onPrayerLogged** (reaction) — after a Prayer write: bump current
  PrayerList.prayerCount; mirror the new count to RTDB; if it was a community
  prayer, update the user's currentStreak/bestStreak/lastPrayedListNumber.
- **onAuthUserCreated** (auth trigger, ADMIN) — create the User row + the self-
  PrayerSubject in one transaction. MUST detect anonymous→permanent LINKING and
  NOT create a second User row in that case.
- **assembleNextList** (ADMIN, manual ~6am trigger) — the join-and-write:
  for each user who prayed the current (closing) list, take their ACTIVE self-
  subject (always) + top includeLimit ACTIVE non-self subjects by sortOrder;
  write PrayerListEntry rows with FROZEN publicName, source="app",
  moderationStatus per filtering. Apply name moderation to any social-sourced
  entries. SETTLE-ON-CLOSE: freeze the closing list's final RTDB prayerCount into
  its PrayerList.prayerCount. Then the new list becomes CURRENT (Option C: flips
  at cutoff; videoPublishedAt stays null until the video goes up).
- **publishListVideo** (ADMIN) — set videoPublishedAt + the social post links
  (PrayerListPost rows) when the video goes live (~8am). Flips the app from the
  "being filmed" placeholder to the video.
- **moderateEntry** (ADMIN) — set moderationStatus/heldReason on a
  PrayerListEntry during review (held → approved/excluded).
- **setEntitlement** (ADMIN) — set planTier/includeLimit on a User from a
  verified billing event. Never client-writable.

---

## Auth summary
- OWNER (USER + ownership): all of a user's own subjects, prayers, header,
  archived, detail, world-count, history.
- USER: getCurrentListMeta (metadata only — counts/links/status, NOT the roster).
- ADMIN/NO_ACCESS: the full roster of names (PrayerListEntry in full), assembly,
  publish, moderation, entitlement, auth-trigger user creation.
- Anonymous users get the full OWNER/USER surface (no isAnonymous gate).

## Open implementation choices (decide against real query ergonomics)
- getMySubjects: derive tile stats inline (one op) vs. companion aggregate query.
- Reaction wiring: true DB trigger vs. sequential function calls.
- listContextNumber is now in the schema (decided), so tier-1 cycle view and
  per-subject streak are both queryable.
