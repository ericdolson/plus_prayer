# +Prayer — Product Spec Index

**Read this before any feature work in `app/` or `backend/`.**

This folder is the CURRENT-STATE spec: what is true about the product right now,
one file per feature. Each file applies to the app AND the backend, since nearly
every feature crosses that boundary.

| Layer | Where | What it holds |
|---|---|---|
| Brand + principles | `/CLAUDE.md` | Voice, core principles, monorepo rules |
| **Product spec (this folder)** | `docs/product/*.md` | Current behavior, UX, rules, per feature |
| Decision log | `docs/decisions.md` | Append-only WHY, timestamped, with supersedes |
| Data shape | `backend/dataconnect/schema/schema.gql` | Source of truth for tables/fields |
| Operation map | `backend/dataconnect/connector/OPERATIONS.md` | Screen → operation, @auth |
| Build conventions | `app/CLAUDE.md`, `backend/CLAUDE.md` | How to build on each side (not product rules) |
| Raw inputs | `seeds/` | Chat exports. Input only, never the source of truth |

## How to maintain
- When a decision is made: update the feature file here (current state) AND add a
  timestamped entry to `docs/decisions.md` (why + what it supersedes).
- Status tags used in every file: **DECIDED**, **OPEN**, **DEFERRED**, **PROPOSED**
  (recommended by an agent, not yet confirmed by Eric).
- Conflict rule: newer timestamp wins; ambiguous conflicts go to
  `open-questions.md` rather than being resolved silently.
- Agents: never promote PROPOSED → DECIDED on your own.

## Feature files
| File | Covers | Status |
|---|---|---|
| [list-lifecycle.md](list-lifecycle.md) | Daily list, cutoff/flip, curation, base set, social intake | Decided |
| [auth-onboarding.md](auth-onboarding.md) | Sign-in methods, anonymous linking, first run, deletion | Decided |
| [subjects.md](subjects.md) | Souls & intentions, lifecycle, ordering, printed slots | Decided |
| [prayer-flow.md](prayer-flow.md) | The act of praying, logPrayer, offline | Decided; abandoned sessions PROPOSED |
| [stats-history.md](stats-history.md) | Count tiers, intention drill-in, history | Decided |
| [streaks-reminders.md](streaks-reminders.md) | Day streaks, last call, grace | Decided |
| [presence-live.md](presence-live.md) | "Praying now", live counts (RTDB) | Decided |
| [notifications.md](notifications.md) | Local reminders, FCM | Decided |
| [monetization.md](monetization.md) | Free vs premium, pool, trial, paywall | Model decided; price/billing OPEN (Stage 2) |
| [privacy.md](privacy.md) | Printed-list privacy, retention, age, data | Decided; legal text pending |
| [screens.md](screens.md) | Navigation, screen map, add sheet, settings | Decided |
| [schema-brief.md](schema-brief.md) | Handoff: every table/field/function change from the meetings | Ready for backend |
| [design-direction.md](design-direction.md) | Visual system: color roles, type, spacing, Home rows, community card, motion, icons — overrides app-brief | Decided 2026-10-23 |
| [app-brief.md](app-brief.md) | Handoff: screens, components, flows, states, copy for the Flutter app | Ready for app |
| [safety.md](safety.md) | Self-harm, threats, child safety — KNOWN GAP checklist | Beta items + Stage 2 |
| [roadmap.md](roadmap.md) | Stages 0–4 with task checklist | Drafted 2026-10-18 |
| [open-questions.md](open-questions.md) | Everything unresolved, in one place | Living |

## Glossary
- **List N** — the daily printed list. Highest published-or-current number = current.
- **Cutoff / flip** — ~6am MT, manual. Prayers before the flip count toward list N
  and carry the user onto N+1. After the flip, N+1 is current.
- **Community prayer** — a prayer for the current list. Earns the user (and their
  carried subjects) a place on the next list.
- **Personal prayer** — a prayer logged to specific souls/intentions, not to the list.
- **Subject** — a soul (person) or intention (request). Unified table, `kind` enum.
- **Self-subject** — the user's own soul. Always carried, free. "The dividend."
- **Carried** — printed on a list.
- **Fold** — the cutoff in the ordered subject list above which subjects are carried.
- **Base set** — standing names (currently NamUs missing children) seeded onto every list.
- **Tier 1/2/3 counts** — I prayed / my group prayed / the world prayed for X.
