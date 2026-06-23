# connector/ — Operations (queries & mutations)

This folder holds the deployable operations — the API surface the app calls via
the generated typed SDK. Each operation declares its own `@auth` level; this is
the security model (a client can only run operations defined here).

## Status: NOT YET DESIGNED

The schema is locked (`../schema/schema.gql`). Operations are the next design
step. Do not hand-write these ad hoc — design them deliberately (with Claude,
then implement here) so auth levels and the sensitive-data posture are correct.

## Operations to design (from the MVP loop)

Reads:
- `getMe` — my user + entitlement (planTier, includeLimit) + streaks
- `getMySubjects` — my souls/intentions, ordered by sortOrder
- `getCurrentList` — today's published list (counts, post links)
- `getMyListStats` — how many times I prayed for a given list (cheap aggregate)
- `getMyPrayerHistory` — my past prayers (+ optional location for "where I prayed")

Mutations:
- `signUp` — create User + self-PrayerSubject in ONE transaction
- `addSubject` / `updateSubject` / `reorderSubjects` / `setSubjectActive`
- `markIntentionAnswered`
- `logPrayer` — write Prayer + PrayerSubjectLink rows; enforce "must include
  current community list if not yet prayed for it"; bump counts; update streak;
  mirror live count to RTDB
- `linkAnonymousAccount` — carry souls/history across the anon→permanent upgrade

Admin / server-only (privileged environment, not client `@auth`):
- `assembleNextList` — join-and-write: users who prayed current list → their
  eligible subjects → PrayerListEntry rows (frozen names, moderation applied)
- `publishList` — flip draft → published after review
- billing entitlement writes (planTier / includeLimit)

## Auth posture
Intentions are sensitive personal data. Default to the tightest auth that still
works. A user reads/writes only their own subjects and prayers. List reads are
authed-user level. Assembly/publish/billing are server-only.
