# +Prayer — Root Context

This is the root context file for the +Prayer monorepo. It governs brand-wide
truths that apply everywhere. Subfolders have their own CLAUDE.md files with
workstream-specific context that inherits everything here.

Anything in a subfolder CLAUDE.md refines or extends this file; it never
overrides the brand voice or the core principles below.

---

## What +Prayer Is

+Prayer is a cross-faith daily prayer list. One global list, assembled fresh
each day. People participate by praying for the list; by participating, they
are themselves carried on the next day's list. The list is physically printed,
assembled, stitched, wax-sealed, and ceremonially retired on camera each day.
The ritual is both the content and the product demonstration.

Positioning is tradition-neutral, interfaith, non-denominational. The founder
story is rooted in universal human goodwill rather than any specific faith
tradition. The brand does not perform community or spirituality — it states
facts and stops.

The long-term product is a Flutter/Firebase app. The current phase is
social-first audience building. The app launches later, with social funneling
into it.

---

## Brand Voice (MANDATORY — applies to ALL public-facing text)

**Observational. Spare. Direct.**

- State facts, leave space.
- No emotional editorializing ("souls carried," "hearts from every tradition").
- No urgency or hype language.
- No spiritual tourism phrases ("every corner of the world," "held by strangers").
- No "we" as a performed-community voice. The community speaks for itself in comments.
- Numbers carry weight on their own. Do not editorialize them.
- One clear CTA per section.
- Let the community fill in meaning themselves.

This voice applies to website copy, captions, FAQs, app copy, store listings,
and all public-facing text. When in doubt, cut a sentence rather than add one.

### Quick self-check before shipping any copy
- Did I instruct the reader to feel something? → Remove it.
- Did I use "we" as a warm collective voice? → Rewrite.
- Did I explain an algorithm or mechanic with hype? → State it plainly.
- Could this sentence be cut without losing the fact? → Cut it.

---

## Core Brand Principles

- **The list is curated, not a live feed.** Names are reviewed before they are
  printed and sealed. +Prayer is a curator of the list, not an unfiltered pipe
  from the internet to a sacred object. This is stated honestly and it builds trust.
- **Every object on camera belongs to the ceremony, not a craft workspace.**
- **Darker over lighter; antique/aged over bright or modern.** Applies to wax,
  lighting, and material finishes throughout.
- **Brand integrity is protected ahead of monetization.** No brand deals, no
  donations. The app is the sole meaningful revenue vehicle.
- **Being on the list is a dividend, not a slot.** A participant is always
  carried for free as the reward for praying. Paid tiers let users carry *others*
  (additional souls/intentions) on the printed list — never to be carried themselves.

---

## Monorepo Structure

```
plusprayer/
  CLAUDE.md            ← this file (brand-wide truths)
  docs/decisions.md    ← canonical running decision log
  seeds/               ← verbose agent-readable summaries for ingestion
  backend/             ← all server-side deploy artifacts (one Firebase config)
    CLAUDE.md
    dataconnect/       ← SQL Connect schema + connectors/operations
    functions/         ← Cloud Functions (assembly job, RTDB mirrors, notifications)
  app/                 ← Flutter app (holds its own Firebase client config)
    CLAUDE.md
  publishing/          ← Zernio publishing pipeline (captions, scripts — text only)
    CLAUDE.md
  ritual/              ← material/production decisions and shot notes (text)
    CLAUDE.md
  brand/               ← logo, palette, copy guidelines
    CLAUDE.md
```

### Structural rules
- **No video or raw media in git.** Media lives in Cloud Storage and is
  referenced by ID/URL from small text manifests. Git holds code, text, config,
  and brand context only.
- **App keeps its own Firebase client config** (`firebase_options.dart`,
  `google-services.json`, `GoogleService-Info.plist`) — these are build inputs
  the app compiles against and cannot move into backend/.
- **backend/ owns deploy artifacts** — schema, functions, security rules, and
  the `firebase.json`/`.firebaserc` that drive deploys. Run deploys from within
  backend/.
- **Path-scoped CI** so editing a caption doesn't trigger a Flutter build and a
  schema change doesn't redeploy the app. The workstreams have very different
  cadences (app = slow store review; functions = continuous; social = daily).

---

## Decision Log Protocol

- `docs/decisions.md` is the canonical running log.
- Each decision carries a timestamp.
- **Conflict resolution:** prefer the more recent timestamp. Surface ambiguous
  conflicts rather than resolving them silently.
- Verbose, agent-readable summaries of working sessions go in `seeds/` for
  ingestion. Optimize them for agent readability, not human skimming.

---

## Tech Stack (current)

- **App:** Flutter + Firebase
- **Backend DB:** Firebase SQL Connect (managed PostgreSQL via Cloud SQL),
  region `us-central1`. Chosen over Firestore for relational fit, native
  full-text search, per-operation pricing, and per-operation auth (vs. a global
  rules file). See docs/decisions.md.
- **Ephemeral/live state:** Firebase Realtime Database (presence, live counts) —
  deliberately kept off SQL Connect to avoid high-fan-out subscription cost.
- **Functions:** Cloud Functions (list assembly, RTDB mirroring, notifications)
- **Publishing:** Zernio (formerly Late API — cosmetic rebrand, same endpoints)
  via MCP on Claude Desktop
- **Website:** Framer; **Email:** Kit
- **Auth:** Google, Apple, and Firebase Anonymous (no email/password for now)
