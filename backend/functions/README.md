# functions/ — Cloud Functions

Server-side logic for +Prayer (spec: `../dataconnect/connector/OPERATIONS.md`
§D). TypeScript, Node 22, region `us-central1` (same as SQL Connect — its
triggers require it). All SQL lives in the `admin` connector
(`../dataconnect/admin/*.gql`); functions call those operations by name.

| Module | What |
|---|---|
| `src/index.ts` | Wiring only: triggers, schedules, callables, params |
| `src/prayers.ts` | `onPrayerLogged` (exactly-once increments, streak/grace, trial), sweeper, grace answers |
| `src/lists.ts` | `closeList`, `assembleNextList`, review, print data, publish, video |
| `src/subjects.ts` | `setSelfName`, `addSubject`, `updateSubject`, `setCarriedItems` |
| `src/accounts.ts` | User creation, `deleteAccount`, `mergeAccounts`, `setEntitlement` |
| `src/presence.ts` | `/stats/live` publisher + reconcile, draft auto-save |
| `src/streak.ts`, `src/pool.ts` | Pure rules (streak + grace; carried pool) |
| `src/live.ts` | RTDB writes (`/lists/current`, `/stats/live`, `/config`) |

Admin callables check the `admin` custom claim (Eric's skills).

## Config
- Server params (`firebase-functions/params`, defaults in `src/config.ts`):
  `GATE_HOURS` (30), `BASE_PREMIUM_POOL` (10), `SUBJECT_CAP` (500),
  `LIST_TIME_ZONE` (America/Denver), `MODERATION_BLOCKLIST` (empty).
- Client-visible values: RTDB `/config`, defaults in
  `config/client-config.json` (also compiled into the app). Seed missing keys
  with `FIREBASE_DATABASE_URL=… npm run seed:config`.

## Tests
- `npm test` — starts the SQL Connect emulator (no Java needed) and runs
  `test/*.test.ts`: gate, streak/grace, assembly + pool, increment-only
  aggregates, client connector ops, accounts. RTDB is faked in memory.
- `npm run test:rules` — RTDB rules + `live.ts` against the Database emulator
  (needs JDK 21+).
- Against already-running emulators: `npm run test:run`.

The standalone Firebase CLI bundles Node 20, which can't load firebase-admin
14 in the Functions emulator; use `npx firebase-tools@15` (Node 22+) for
`emulators:start --only functions`. Deployed functions run on Node 22.
