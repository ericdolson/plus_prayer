# connector/ — client operations (queries & mutations)

The ONLY operations the app can call, via the generated typed SDK
(`app/lib/dataconnect_generated`, regenerate with
`firebase dataconnect:sdk:generate` from `backend/`). Each declares its own
`@auth`; that is the security model.

- `queries.gql` — reads (`USER_ANON`, every row scoped to `auth.uid`; list
  metadata is public-safe: numbers, counts, seal, video — never names).
- `mutations.gql` — writes, including `LogPrayer`. Read its header for the
  native-SQL rules this engine needs.
- `OPERATIONS.md` — the authoritative screen → operation map (what each op
  does and why). Start there.

Server-only operations (assembly, prayer reactions, merge, moderation,
publish, entitlements) live in `../admin/` (`NO_ACCESS`) and are called by
the Cloud Functions in `backend/functions`.

Auth posture: anonymous users get the full surface — use `USER_ANON`, never
`USER` (SQL Connect's `USER` excludes anonymous accounts).
