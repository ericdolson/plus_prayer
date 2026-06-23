# functions/ — Cloud Functions

Server-side logic. See ../CLAUDE.md for the full list and the sensitive-data /
server-only-writes posture. `src/` holds the function source.

## Key functions (anticipated)
- **assembleNextList** — manual-trigger join-and-write building the next list
  (runs ~8am when Eric kicks off the transition; applies name moderation on
  social-sourced entries). NOT scheduled — manual for flexibility.
- **publishList** — flip a reviewed list draft → published.
- **mirrorPrayerCount** — bump current list prayerCount on commit; mirror to RTDB.
- **presence** — maintain RTDB presence counter; periodic reconciliation backstop.
- **streakUpdate** — update streak fields on community-prayer commit.
- **billingEntitlement** — set planTier / includeLimit on subscription change (later).

## Rules
- All global/aggregated state is written here, never by clients.
- The list-assembly read+write happens inside Postgres (set-based); large
  intention sets never ship to a client.
