# Subjects — Souls & Intentions

_Last updated: 2026-10-17_

## DECIDED
- **Unified `PrayerSubject` table** with `kind` = SOUL | INTENTION.
  SOUL = a person held in prayer, ongoing. INTENTION = a specific request with a
  lifecycle; can be marked answered (`answeredAt`) — the gratitude payoff.
- **Two names:** `publicName` (printed/shown, e.g. "Gary Olson") and optional
  `personalLabel` (owner-only, e.g. "Dad"). `note` optional.
- **Every name has an optional alias** (2026-10-17) = `personalLabel`, shown in
  the app as "alias". The owner sees the alias in their own list ("Dad"); the
  real name ("Gary Olson") is what's printed. The self-subject's alias is always
  "Me". Aliases are owner-only — in future prayer groups, members see the real
  name. Search matches both. Aliases are never moderated or sent to the
  moderation first pass.
- **Self-subject:** auto-created, always carried free, pinned top, exempt from
  `includeLimit` and ordering, forced ACTIVE.
- **Lifecycle enum** (2026-06-24): ACTIVE (main list, list-eligible) / ARCHIVED
  (recoverable hide) / PURGED ("gone gone", hidden everywhere, row persists for
  history). PURGED ≠ data erase.
- **Ordering is manual (user-decided)** (2026-10-18): drag to reorder names, and
  intentions within a name; self row pinned top. No automatic ordering — the
  header filter (e.g. Still to hold) covers that need. `sortOrder` orders the main list; carrying is chosen separately
  via `isCarried` (see monetization.md).
- **Souls/Intentions distinction is an app-layer feature** (structured input).
  Collapsed to one undifferentiated list on social.
- **Free tier prints you + one intention of your own** (2026-10-17; supersedes
  the earlier "intentions on the global list are premium-only").
- **Personal prayers** = prayers intentionally logged to specific subjects in the
  app. Unlimited private prayer is free (see monetization.md for what "free"
  includes — under discussion).
- **Upgrade-prompt guardrail:** never fire an upgrade prompt on a freshly added
  subject tied to someone in crisis.
- **Ops:** addSubject, updateSubject, reorderSubjects, markIntentionAnswered,
  archiveSubject, restoreSubject, purgeSubject (OPERATIONS.md).

- **Intentions live under a name** (2026-10-17). A "name" is a top-level
  subject — a person, group, or cause, however the user wants to name it
  ("Mom", "Our parish", "Ukraine"). An intention always has a parent name;
  one level only. Your own intentions sit under your self-row.
  Main list: names as rows, intentions as indented sub-rows. Add-intention
  defaults to "For: Me" so no name has to be created first.
  Schema: nullable `parent: PrayerSubject` (promotes the deferred
  `relatedSubject` seam to MVP); required when kind = INTENTION.
- **Where you add decides the type:** "Add name" (40 chars) on the main list,
  "Add intention" (80 chars) on a name. No type-after-entry flow.
- **Resolving an intention** (2026-10-17) offers two choices:
  **Answered** — no longer eligible for the global list (frees its place
  immediately); stays on the main view under its name as "Answered · praying in
  gratitude" until archived; prayers logged to it are gratitude prayers.
  **Release** — for outcomes not hoped for; no gratitude implied; not
  list-eligible; moves straight to the archive with history intact.
  Schema: replace `answeredAt` with `resolvedAt` + `resolution`
  (ANSWERED | RELEASED). Assembly excludes resolved intentions.
- **Anonymous answered count** may appear on the list and in social captions,
  only when the number is meaningful (PROPOSED: a cumulative running total,
  e.g. "312 intentions answered", which only grows; per-list numbers only above
  a threshold). Mention in privacy terms.
- **Name ↔ intention carrying** (2026-10-18): an intention is *effectively*
  carried only when `intention.isCarried && parent.isCarried`. Uncarrying a name
  leaves its intentions' own flags intact; re-carrying the name brings them back
  (over-limit flow if needed). The pool counts only effectively carried items.
- **Cascade:** archive / purge on a name applies to its intentions. Restore brings
  back only intentions archived *by that cascade* — never Released ones or ones
  the user archived themselves. Restoring an intention whose name is archived is
  blocked ("Restore its name first"). Restoring a Released intention clears its
  release (open and list-eligible again); Answered stays Answered.
- **Selection rules in prayer** (2026-10-17): checking an intention also holds
  its name (both linked → counts toward the name); checking a name does not
  auto-check its intentions; unchecking a name unchecks its intentions; a name
  shows a partial state when only some intentions are held.

## RESOLVED (see monetization.md)
- Paid capacity is a pool of carried names/intentions, chosen on the "your
  portion" screen with auto-carry while room remains (replaces the fold).
- Private names/intentions are unlimited and free.

## DEFERRED
- Pause-a-subject (`setSubjectActive`) — cut for MVP.
- Intention attached to a soul (`relatedSubject` self-ref).
- Group visibility (`groupId`, `visibility`).
- True data erase (GDPR-style).
