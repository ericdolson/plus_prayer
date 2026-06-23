# +Prayer

Monorepo for +Prayer — a cross-faith daily prayer list. Social-first now, app later.

Start with `CLAUDE.md` (brand-wide truths and structure), then `docs/decisions.md`
(canonical decision log). Verbose session summaries for agents are in `seeds/`.

## Layout
- `backend/` — server-side deploy artifacts (SQL Connect schema/ops, Functions, rules). Deploy from here.
- `app/` — Flutter app (keeps its own Firebase client config).
- `publishing/` — Zernio pipeline (captions/scripts; media is NOT in git).
- `ritual/` — production/material notes (text only).
- `brand/` — identity and copy guidelines.
- `docs/` — decision log. `seeds/` — agent-ingestable session summaries.

## Hard rules
- No video/raw media in git — Cloud Storage, referenced by manifest.
- Global/aggregated state is server-written only.
- Brand voice (root CLAUDE.md) governs all public-facing copy.

## Commands
The root `package.json` is a task launcher only (this is NOT a Node app — it's a
polyglot monorepo). Deploys run from `backend/`; these scripts just alias the
`cd backend && firebase …` incantations:

- `npm run deploy:backend` — deploy everything in backend/
- `npm run deploy:dataconnect` — deploy SQL Connect schema + connectors
- `npm run deploy:functions` — deploy Cloud Functions
- `npm run deploy:rules` — deploy RTDB + Storage security rules
- `npm run emulators` — start the Firebase emulator suite

Requires the Firebase CLI (`npm i -g firebase-tools` or `npx firebase`).

## Status
Backend MVP schema locked (`backend/dataconnect/schema/schema.gql`).
Next: design connector operations with @auth. App not yet started.
