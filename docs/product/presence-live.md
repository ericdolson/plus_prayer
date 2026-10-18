# Presence & Live Counts

_Last updated: 2026-10-17_

## DECIDED
- **Live state lives on Realtime Database, not SQL Connect.** RTDB is
  bandwidth-billed (right for high-churn data); SQL Connect subscription fan-out
  billing is the least-proven surface.
- **"Praying now" presence** = anyone currently in prayer. Not tied to the global
  list. Uses RTDB `onDisconnect()` for crash-proof cleanup; a low-frequency
  reconciliation job is the backstop.
- **Live prayer count for the current list** mirrored to RTDB from server side;
  clients subscribe to RTDB. Settle-on-close freezes it into Postgres.
- **All global/aggregated state is server-written.** Clients write only their own
  presence node (validated by `database.rules.json`).

## DECIDED (2026-10-18)
- **One number for any prayer** (with or without the list). Shown in the
  in-prayer footer ("with 212 others") and as a quiet line on the main screen.
- **Count only, never who** — outside future private groups.
- **Low-scale fallback:** show the live count when ≥ 10; otherwise a window
  ("38 prayed in the last hour"). Fall further back (e.g. "prayed today") or hide
  rather than ever showing 0. (Exact ladder PROPOSED below.)
- **Throttled public counter:** clients never subscribe to raw presence.
  `/presence/{uid}` nodes (with `onDisconnect`) are private; a server process
  aggregates them and writes ONE small public node on a fixed cadence (~5s),
  together with the last-hour prayer count. Clients subscribe only to that node.
  RTDB is the home for it (cheap for tiny payloads; bandwidth-billed).

## PROPOSED
- Public node `/stats/live = { prayingNow, prayedLastHour, prayedToday, updatedAt }`.
- Cadence mechanics: Cloud Scheduler can't go below 1 minute, so use an
  event-driven publisher (presence write → update private counter → republish
  the public node if ≥5s since the last publish) plus a 1-minute scheduled
  job that catches trailing changes and reconciles drift.
- Clients subscribe only while foregrounded (cost scales with open clients ×
  update rate). Revisit cadence at scale.
- Display ladder: prayingNow ≥ 10 → live; else prayedLastHour ≥ 10 → last hour;
  else prayedToday ≥ 10 → today; else hide the line.

## DEFERRED
- Presence inside private groups (would show WHO, since groups are non-anonymous).
