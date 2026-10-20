# Seed: Backend production bring-up and list backfill

- **Source:** Claude Code session at the repo root (backend work, continued from an earlier session started in `backend/`)
- **Session date:** 2026-10-19 (US Mountain evening; UTC timestamps below are 2026-10-20)
- **Exported:** 2026-10-19
- **Scope:** first real production deploy of SQL Connect, Functions, and RTDB/Storage rules; RTDB config seed; backfill of lists 1–60 into the database; tooling problems found along the way
- **Suggested split on ingestion:**
    - `docs/decisions.md` (entries in the Decisions section below)
    - `docs/product/open-questions.md` (Open items section below)
    - `backend/CLAUDE.md` (already updated and committed this session; check against §7)

## Status legend

- **SETTLED**: Eric explicitly decided or approved, or it is now true in production.
- **IMPLEMENTED**: Claude chose the behavior while building it; Eric ran it without objecting, but didn't discuss it explicitly.
- **OPEN**: unresolved.
- **FACT**: verified state, not a decision.

---

## 1. Starting state (FACT, before this session's changes)

- Firebase project `plusprayer` (project number `1045736003040`), region `us-central1`.
- Cloud SQL instance `plusprayer-instance` was RUNNABLE.
- SQL Connect service `plusprayer-service`:
    - Its schema `main` and connector `plusprayer` were last deployed 2026-06-24, an early version of the schema.
    - The `admin` connector had never been deployed, so `admin -- status` failed with "connectors/admin was not found".
- `backend/.firebaserc` still held the placeholder `REPLACE_WITH_FIREBASE_PROJECT_ID`.
- The admin CLI (`backend/functions/scripts/admin.ts`) had uncommitted changes from the previous session. They make it use Eric's gcloud login (Application Default Credentials, quota project `plusprayer`) when `GOOGLE_APPLICATION_CREDENTIALS` isn't a service-account key.

---

## 2. Cloud SQL / SQL Connect facts discovered (FACT)

- **Instance:**
    - PostgreSQL 18 (`POSTGRES_18`), tier `db-f1-micro`, ENTERPRISE edition, created 2026-06-23.
    - Label `firebase-data-connect: ft`, i.e. the free trial instance.
    - Firebase docs say trial instances support PostgreSQL 15.x only. This one was created as 18 regardless; there was no major-version upgrade.
    - Operation history: only user creations, one database creation, and routine maintenance on 2026-08-19.
- **Database:** `plusprayer-database`.
- **Postgres roles:**
    - `firebaseowner_/firebasewriter_/firebasereader_plusprayer-database_public`, plus `firebasesuperuser`.
    - IAM users `olson.ericd@gmail.com` (a member of the owner role) and the SQL Connect service agent `service-1045736003040@gcp-sa-firebasedataconnect.iam` (a member of the writer role).
- **Networking:** public IPv4 and no authorized networks; IAM authentication flag on.
- **Contents before the reset:** the June schema had 7 tables (`user`, `prayer_subject`, `prayer_list`, `prayer_list_entry`, `prayer_list_post`, `prayer`, `prayer_subject_link`) and 2 enums (`subject_kind`, `subject_status`). **All 7 tables had 0 rows.**

---

## 3. What happened, in order

### 3.1 `.firebaserc` → `plusprayer`. **SETTLED**

### 3.2 `firebase dataconnect:sql:diff` could not produce a diff. **FACT**

- **Server error:** `FAILED_PRECONDITION / INACCESSIBLE_SCHEMA` ("the database schema cannot be accessed").
- **What the CLI printed instead:** the full CREATE script for the target schema, with the warning "Cannot access CloudSQL database to validate schema".
- **Ruled out:**
    - **Grants:** `firebase dataconnect:sql:setup` reported "already set up as greenfield", re-ran the grants, and the error persisted.
    - **IAM and connectivity:** the service agent has `roles/firebasedataconnect.serviceAgent`, and the service could still run queries. A GraphQL `prayerLists` read returned `[]`.
    - **PostgreSQL 18 schema inspection:** disproven in §3.3.
- **Root cause:** unknown. Something about the June-created tables blocked the service's schema inspection.

### 3.3 Reset: drop the empty June tables and deploy fresh. **SETTLED (Eric chose this over rebuilding the instance)**

- Eric ran this in `firebase dataconnect:sql:shell`, as one transaction:
    - `SET ROLE` to the owner role.
    - A guard that aborts if any of the 7 tables has rows.
    - An explicit `DROP TABLE` of the 7 tables and `DROP TYPE` of the 2 enums, without `CASCADE`.
- Then `firebase deploy --only dataconnect`, which created the full current schema and deployed both connectors (`plusprayer`, `admin`).
- **Afterwards:** `sql:diff` reports "matches SQL Connect Schema exactly", so inspection works on PostgreSQL 18 with tables present.
- The alternative (rebuild the instance on PostgreSQL 15 or 16) was **not needed**.

### 3.4 Functions, RTDB rules, Storage rules deployed. **SETTLED**

- **Deploy command:** `npx -y firebase-tools@latest deploy --only functions,database,storage` (firebase-tools 15.34.0). See §6.1 for why not the standalone binary.
- **Params:** saved to `backend/functions/.env.plusprayer` (gitignored): `GATE_HOURS=30`, `BASE_PREMIUM_POOL=10`, `SUBJECT_CAP=500`, `LIST_TIME_ZONE=America/Denver`, `MODERATION_WORD_BLOCKLIST=false`.
- **Result:** 24 functions are live, all Node 22 in `us-central1`, with no warnings or errors in the logs after the deploy.
    - **Callables:** `addSubject`, `updateSubject`, `setCarriedItems`, `setSelfName`, `syncAccount`, `deleteAccount`, `mergeAccounts`, `answerGraceOffer`.
    - **Admin callables:** `closeList`, `assembleNextList`, `getReviewDiff`, `moderateEntry`, `moderateEntries`, `getHeldEntries`, `getListForPrint`, `publishList`, `publishListVideo`, `setEntitlement`.
    - **Triggers:** `onPrayerLogged` (SQL Connect mutationExecuted), `presencePublisher` (RTDB write), `onAuthUserCreated` (v1 auth).
    - **Schedules:** `sweepUncountedPrayers` (10 min), `autoSavePrayerDrafts` (15 min), `presenceReconcile` (1 min).
- **Resources:** the RTDB instance `plusprayer-default-rtdb` and the Storage bucket `plusprayer.firebasestorage.app` already existed.

### 3.5 RTDB config seeded. **SETTLED**

- Eric ran `admin -- seed-config` and checked the result in RTDB.
- `/config` = `{ autoSaveHours: 6, draftResumeMinutes: 30, durationCapHours: 4, graceCap: 2, graceIntervalDays: 7, minAppVersion: "0.0.0", minPrayerSeconds: 5, presenceDisplayThreshold: 10 }`.

### 3.6 Auth providers. **FACT**

- Anonymous, Apple, and Google sign-in were already enabled in the `plusprayer` project.

### 3.7 `admin` custom claim: deferred. **OPEN (not blocking)**

- The admin callables check `req.auth.token.admin === true` (`functions/src/index.ts:54`).
- **The admin CLI doesn't need the claim:** it calls the modules directly with Eric's gcloud login. The claim only matters for calls made as a signed-in Firebase user, such as a future in-app admin screen.
- **It can't be set yet:** Eric has no user ID in `plusprayer` until he signs in once. Only the iOS build points at `plusprayer` (§6.4).
- **Plan:** after the first sign-in, a one-off firebase-admin `setCustomUserClaims(uid, { admin: true })`.

### 3.8 Backfill command written and run. **SETTLED (ran in production)**

- **Code:**
    - Admin CLI command `backfill [--only N] [--dry-run] [--lists FILE] [--participants FILE]`, in `functions/src/backfill.ts` and `functions/src/adminCli.ts`.
    - New admin operations in `dataconnect/admin/lists.gql`: `GetListNumbers` (query) and `BackfillList` (one native-SQL `_execute` per list, made of data-modifying CTEs, so it's atomic).
- **Defaults:** reads `../../publishing/lists.json` and `../../publishing/participants.json`, relative to `backend/functions`, which is where `npm --prefix` runs the script.
- **Run result:**
    - **Lists:** 60 lists inserted. Their `soul_count` totals 272,113, the same total as `lists.json`.
    - **Social names and posts:** 27 SOCIAL entries for 23 distinct ExternalPerson rows, and 288 PrayerListPost rows.
    - **Current list:** list 60, ID `366ab4cca5374248a9725aee1e157c0e`, `currentFrom` 2026-10-20T00:30:00Z, no `closesAt`.
    - **RTDB:** `/lists/current` = `{ listId: 366ab4cc…, listNumber: 60, prayerCount: 0 }`.
- **Checks:** `admin -- status` shows list 60 as current and the only open list. A spot check of list 17 showed 10 hand-added names, all APPROVED, 5 post links, `sealVariant` 0, and `settledAt` 2026-07-20T13:56Z.

---

## 4. Decisions

### 4.1 Backfill semantics. **IMPLEMENTED (2026-10-19)**

- **Status and counts:**
    - Every backfilled list is `status = published`, with the printed `soul_count` and `intention_count` from `lists.json`.
    - `prayer_count` is 0: no app prayers existed before launch.
- **Times:**
    - `currentFrom = publishedAt = published.published_at ?? published.scheduled_for ?? published.intended_for`. 56 of 60 lists only record `scheduled_for`.
    - `closesAt = settledAt = the next list's currentFrom`. The last list (60) gets neither, so it becomes current.
    - Real gaps are kept as they happened: there were no lists from 2026-08-05 to 08-11, so list 33 stays open until list 34 at 2026-08-12T15:33Z.
- **`sealVariant`:** the weekday of `listDate`, Sunday = 0, the same as `publishList`.
- **`videoPath`:** the decoded storage path from `video_url`, e.g. `publishing_videos/60.mp4` (some are named `list_1.mp4` or `list_0017.mp4`). `videoPublishedAt` = `currentFrom`.
- **People:** `participants.json → pending[N]` holds the names printed on list N. They become `ExternalPerson(source SOCIAL)` rows with APPROVED `PrayerListEntry` rows (`kind SOUL`, `source SOCIAL`).
    - The display name is `cleanText` + truncated to `nameCap` (40), the same as assembly ingest.
    - **Hand-added names** (`platform: manual`, `id: null`) are keyed `externalId = "name:<lowercased display name>"`. The same name on two lists is one person. There were 21 such entries, for lists 17 and 33.
    - `first_seen` = the participant's `at`.
- **Posts:** only platforms with a recorded `platform_post_url` are written.
    - `external_id` = the Zernio `post_id`.
    - The failed TikTok post and list 60's unconfirmed TikTok were skipped.
- **Safe to rerun:**
    - A list number already in the database is never touched, apart from upserting its post links. A rerun picks up TikTok links confirmed later.
    - It refuses to create the last list as current if the database already has an open list or a higher-numbered one.
- **Base-set entries:** backfilled lists have none, so their `soul_count` is the printed total and must never be recounted (see §5.4).

### 4.2 Deploy tooling. **SETTLED (2026-10-19)**

- Deploy functions with `npx -y firebase-tools@latest` (§6.1).
- Deploy dataconnect with the standalone `firebase` 15.22.1 for now, because of §6.2.
- Check `sql:diff` before any schema deploy.

---

## 5. Open items

### 5.1 NamUs base set import. **OPEN — blocks the first morning run on the database**

- `assembleNextList` copies BASE_SET `external_person` rows into N+1, but none exist yet.
- **Consequence:** without the import, the first `close-list` → `assemble` would produce list 61 with only app users and the 🙏 harvest, a few dozen names instead of about 4,500.
- `UpsertBaseSetPerson` exists; the import script doesn't.
- **Unknown:** where the NamUs data lives. It isn't in the repo.

### 5.2 Storage path for videos. **OPEN**

- `storage.rules` allows public reads only under `videos/`. Backfilled `video_path` values are under `publishing_videos/`, so the app can't load them through the SDK.
- Existing download URLs carry tokens and still work.
- **Options:** open up `publishing_videos/`, or move the files to `videos/` and update `video_path`.

### 5.3 `PrayerListEntry` join-table warning. **OPEN**

- firebase-tools 15.34.0's compiler (used by the MCP `dataconnect_build`) reports an *error*: `schema/schema.gql:529: MISSING_JOIN_TABLE_KEY: On PrayerListEntry: This table looks like a join table, but it is missing the composite primary key definition.`
- 15.22.1 reports it only as a warning. Its suggested workaround is `@table(key: ["list", "parentEntry"])`, which is wrong for this table: it has a surrogate `id` key, and each entry references either a subject or an external person.
- A dataconnect deploy with the newer CLI may fail on it. It needs a schema-side fix, for example restructuring so it no longer looks like a join table, or an opt-out if one exists.

### 5.4 RecountList on backfilled lists. **OPEN (low risk)**

- `moderateEntry`, `moderateEntries`, and `publishList` call `RecountList`, which sets `soul_count` from the entries.
- On a backfilled list, that would drop `soul_count` from about 4,500 to the social count. Nothing in the normal flow touches past lists, but a manual moderation of a backfilled entry would.

### 5.5 App Firebase config targets the wrong project. **OPEN**

- `app/lib/firebase_options.dart` and `app/android/app/google-services.json` point at project `plus-prayer` (number `1014435277143`).
- `app/ios/Runner/GoogleService-Info.plist` points at `plusprayer` (`1045736003040`), where the backend lives.
- Run `flutterfire configure --project=plusprayer` before the `PP_ENV=firebase` app work.

### 5.6 `admin` custom claim. **OPEN** — see §3.7.

### 5.7 Standalone `firebase` binary. **OPEN**

- `/usr/local/bin/firebase` is 15.22.1 (June). Replace it with `npm i -g firebase-tools` once §5.3 is handled, or keep using `npx`.

### 5.8 gcloud CLI user login expired. **OPEN (minor)**

- `gcloud` commands fail with `invalid_grant`; `gcloud auth login` fixes it.
- Application Default Credentials (used by the admin CLI and by the Cloud SQL connector inspection) still work.

### 5.9 Still deferred from before this session

- The morning assembly/review skill, built on the admin CLI.
- Moving the harvest/publish/finalize skills onto the database.
- The print skill reading from the database.
- The privacy-policy note about AI name review.
- **App build step 4** (`PP_ENV=firebase`):
    - add the `firebase_database` and `cloud_functions` packages;
    - real repositories against the generated SDK, the callables and RTDB;
    - the `list-live` FCM topic;
    - mirror `contact.ts` for the inline name check.

---

## 6. Tooling gotchas (FACT; useful for future agents)

### 6.1 The standalone `firebase` binary breaks functions deploys

- The binary bundles npm 8.19.4 on Node 20.18.2. The `functions.predeploy` step (`npm --prefix "$RESOURCE_DIR" run build`) crashes with `npm ERR! Cannot read properties of undefined (reading 'stdin')` in `@npmcli/promise-spawn`.
- The TypeScript build itself is fine. `npx -y firebase-tools@latest deploy …` uses the system npm (11.x on Node 24) and works.

### 6.2 Two firebase-tools versions in play

- The standalone binary is 15.22.1. The MCP server runs `npx -y firebase-tools@latest` (15.34.0).
- The newer compiler is stricter (§5.3).

### 6.3 `sql:diff` output when the database can't be inspected

- When the database can't be inspected, `sql:diff` prints the *full* CREATE script, not a diff, under "Here is the complete expected SQL schema". Don't mistake it for a migration plan.
- Run with `--debug` to see the `IncompatibleSqlSchemaError` / `INACCESSIBLE_SCHEMA` details.

### 6.4 Read-only database inspection without `psql`

- Use `@google-cloud/cloud-sql-connector` + `pg` from the firebase-tools npx cache (`~/.npm/_npx/<hash>/node_modules`), with `authType: IAM` and user `olson.ericd@gmail.com`, inside `BEGIN READ ONLY … ROLLBACK`.
- The scratch script used this session isn't in the repo.

### 6.5 The Claude Code auto-mode classifier blocks production changes

- It blocked `firebase dataconnect:sql:setup` (as a "Production Deploy") and printing the stored output of the production database inspection (as "Production Reads").
- Eric ran production-changing commands himself with `!` or in his own terminal.

### 6.6 `dataconnect:compile` regenerates the app SDK

- It regenerates the Dart SDK into `app/lib/dataconnect_generated`. This session's run produced byte-identical output.

### 6.7 Admin CLI working directory

- The admin CLI runs from `backend/functions` (because of `npm --prefix`), so relative file arguments resolve from there.

---

## 7. Repo changes this session (all on branch `app/skeleton-home`, not pushed)

| Commit | Summary |
|---|---|
| `396a1c3` | backend: backfill lists 1..N from the publishing JSON (`backfill.ts`, `adminCli.ts`, `admin/lists.gql`, docs) |
| `73a1c5e` | functions: admin CLI runs on Eric's gcloud login (ADC; `admin.ts`, `index.ts` comment, `admin-cli.test.ts`, docs) |
| `4d75ebe` | backend: point `.firebaserc` at the plusprayer project |
| `fb399e7` | docs: check off the Stage 0 backend items now deployed (`docs/product/roadmap.md`) |
| `14c1066` | backend: `CLAUDE.md` lists the deployed functions and deploy notes |

- **Not committed by this session:** Eric's own working-tree changes to the publishing JSON, skills, `publishing/CLAUDE.md`, the Framer scripts, and the app.
- **Tests:** none were written or run this session, per Eric's standing rule. `tsc` passed and `dataconnect:compile` (15.22.1) passed. The `admin-cli.test.ts` change has never been run.
