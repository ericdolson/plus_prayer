# functions/ — Cloud Functions

Server-side logic for +Prayer (spec: `../dataconnect/connector/OPERATIONS.md`
§D). TypeScript, Node 22, region `us-central1` (same as SQL Connect — its
triggers require it). All SQL lives in the `admin` connector
(`../dataconnect/admin/*.gql`); functions call those operations by name.

| Module | What |
|---|---|
| `src/index.ts` | Wiring only: triggers, schedules, callables, params |
| `src/prayers.ts` | `onPrayerLogged` (exactly-once increments, streak/grace, trial), sweeper, grace answers |
| `src/lists.ts` | `closeList`, `assembleNextList`, review diff, print data, publish, video |
| `src/subjects.ts` | `setSelfName`, `addSubject`, `updateSubject`, `setCarriedItems` |
| `src/accounts.ts` | User creation, `deleteAccount`, `mergeAccounts`, `setEntitlement` |
| `src/presence.ts` | `/stats/live` publisher + reconcile, draft auto-save |
| `src/streak.ts`, `src/pool.ts` | Pure rules (streak + grace; carried pool) |
| `src/live.ts` | RTDB writes (`/lists/current`, `/stats/live`, `/config`) |

Eric's skills run the admin operations through the admin CLI below (service
account). The deployed admin callables stay available too and check the
`admin` custom claim.

## Config
- Server params (`firebase-functions/params`, defaults in `src/config.ts`):
  `GATE_HOURS` (30), `BASE_PREMIUM_POOL` (10), `SUBJECT_CAP` (500),
  `LIST_TIME_ZONE` (America/Denver), `MODERATION_WORD_BLOCKLIST` (false — off
  for the beta). The first deploy prompts for them once.
- Contact info / links: blocked at input and excluded at social ingest
  (`src/contact.ts`), always on.
- Word blocklist (off for the beta): RTDB `/moderation/blocklist`
  (server-only, editable without a deploy), seeded from `config/blocklist`
  (LDNOOBW, CC BY 4.0 — see its README); the functions fall back to the
  bundled seed when it's empty.
- Client-visible values: RTDB `/config`, defaults in
  `config/client-config.json` (also compiled into the app). Seed missing keys
  (and the blocklist, if empty) with `npm run seed:config` (the admin CLI's `seed-config`).

## Admin CLI (for Eric's skills)
The admin callables, run locally with a service account — same code paths
as the deployed functions, JSON on stdout, errors as
`{ "error": { code, message, details } }` on stderr with exit code 1:

```sh
export GOOGLE_APPLICATION_CREDENTIALS=~/.config/plusprayer/service-account.json
npm --prefix backend/functions run admin -- help
npm --prefix backend/functions run admin -- close-list            # ~5 min before the routine
npm --prefix backend/functions run admin -- assemble --social harvest.json
npm --prefix backend/functions run admin -- moderate --decisions decisions.json
npm --prefix backend/functions run admin -- held                   # Eric's short list
npm --prefix backend/functions run admin -- backfill --dry-run     # lists 1..N from publishing/*.json
```

Key: Firebase console → Project settings → Service accounts → Generate new
private key. Keep it outside the repo (`service-account*.json` is
gitignored anyway). It has full admin rights — treat it like a password.
Config comes from `.env` / `.env.<projectId>` (what `firebase deploy` writes
for the params) and the environment, so the CLI and the deployed functions
agree. Every run prints the target project to stderr (production / EMULATOR).

## Tests
- `npm test` — starts the SQL Connect emulator (no Java needed) and runs
  `test/*.test.ts`: gate, the closesAt → N+1 lifecycle, streak/grace incl.
  late-sync repair, assembly + pool + blocklist, increment-only aggregates,
  every client query, client mutations, accounts. RTDB is faked in memory.
- `npm run test:rules` — RTDB rules + `live.ts` against the Database emulator
  (needs JDK 21+).
- Against already-running emulators: `npm run test:run`.

The standalone Firebase CLI bundles Node 20, which can't load firebase-admin
14 in the Functions emulator; use `npx firebase-tools@15` (Node 22+) for
`emulators:start --only functions`. Deployed functions run on Node 22.
