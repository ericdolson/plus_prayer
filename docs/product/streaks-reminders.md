# Streaks & Reminders

_Last updated: 2026-10-17_

## DECIDED
- **Streaks count calendar days in the user's local timezone** (2026-10-17).
  Duolingo-style. SUPERSEDES the 2026-06-23 "consecutive list numbers" decision.
  Reason: the list rollover is manual and follows no user's timezone, so a
  list-based streak has no clean deadline for a "last call" reminder.
- **"Last call" reminder** before the user's daily deadline when they haven't
  prayed yet.
- **User streak is STORED** on User (`currentStreak`, `bestStreak`), updated
  server-side by `onPrayerLogged`. Per-subject streaks are DERIVED.

## DECIDED (2026-10-18)
- **The streak counts "days with the world"** (2026-10-18, SUPERSEDES "any
  prayer ≥5s counts"): a local day counts only if the user prayed (≥5s) with
  the list included. The community is the offering — a streak of any prayer
  would make +Prayer like every other app. Keeping the streak always satisfies
  the list gate, so **keep your streak = stay carried** (one rule, one clock).
- **Personal-only prayers** don't extend the streak but are acknowledged: hollow
  marks in the streak sheet and a gentle count — "Days in prayer this month: 26"
  (a count, not a second streak: no run, no grace, no milestones). They count
  everywhere else (History, detail pages, prayer time).
- **Local day:** each Prayer stores the device's local calendar date at
  completion (`Prayer.localDate: Date!`, offline-safe); `User.timezone` (IANA)
  updated from the device; `User.lastPrayedLocalDate` replaces
  `lastPrayedListNumber`. Server computes the streak from `localDate`.
  Travel: use the device's current zone; accept a skipped/doubled day, no penalty.
- **Grace days — offered, accepted, banked** (2026-10-18, SUPERSEDES the
  same-day "max one, auto, strict setting" version):
  - Every 7 days with the world (real list days), the user is **offered** a grace day:
    "Seven days kept. A grace day is yours if you'd like it." [Keep it] [No thanks].
    Reverent, not gamey.
  - Accepted grace days **bank up to 2** (2026-10-18), shown as small marks beside
    the streak. Start at 2 (close to Duolingo's market-tested choice); may raise
    to 3 later — never lower once launched. Cap and 7-day interval are server
    config (Remote Config), tunable without an app release.
  - When the bank is full, the 7-day mark is still acknowledged quietly:
    "Seven days kept. Your grace days are full." 
  - **No strict-mode setting.** Declining offers "Don't offer again"
    (reversible in Settings) — that's the strict path.
  - Only real list days count toward earning; grace-bridged days don't.
  - Each consecutive missed day consumes one grace day; if misses exceed the
    bank, the streak breaks (bank unchanged). A bridged day keeps the streak
    alive but doesn't add a day.
  - An unanswered offer stays pending until answered; offers don't stack.
  - Never sold; same for every tier.
  - Schema: `User.graceDays` (0–cap), `graceOfferPending`, `graceOffersEnabled`.
    Streak is derived on read from `localDate` with the same rules.
- **Last call:** local notification ~8pm, only if not prayed today, plain wording
  ("A moment for prayer before the day ends.").
- **Milestones:** 7, 30, 100, 365 days — one plain line each, no confetti.
- **Broken streak:** no drama; best streak stays visible; count restarts quietly.

- **Streak sheet marks** (2026-10-18): month view shows a sealed mark (that day's
  wax color) for days prayed with the list and a soft hollow mark for
  personal-only days. Nothing shown as empty or wrong.
- **Badge = icon + number only** in the header; the sheet explains what it means.
  Badge states (DECIDED 2026-10-18; replaces "hidden at 0" so the sheet is always
  reachable): streak N + prayed with the list today → seal in wax color + N;
  streak N, not yet today → muted seal + N (still alive); streak 0 → muted
  seal, **no number** (never shows "0"). Tapping always opens the streak sheet
  (best streak, grace days, month view). The sheet is also reachable from History.
- **After a break:** first open shows "Welcome back. {name} is still here." — no
  zero, no broken icon; the badge returns quietly on the next day with the world.
- **Last call (revised 2026-10-18):** ~8pm, only if the user hasn't prayed WITH
  THE LIST today. Two wordings: not prayed at all → "A moment for prayer before
  the day ends."; prayed but not with the list → "Today's list is still open.
  Hold them with you before the day ends."

## OPEN
- Calendar/history view marking grace days distinctly.
- "List closes soon" reminder (separate from last call) — the flip is manual.

## DEFERRED
- Group streaks.
