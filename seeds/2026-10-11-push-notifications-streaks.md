# Seed: Push notifications, streaks, and intention history

- **Source chat:** "Push notification strategy + streak design" (+Prayer project)
- **Discussion dates:** 2026-10-11 → 2026-10-12
- **Exported:** 2026-10-18
- **Scope:** daily reminder delivery, reminder UX, last call, streaks, list gate timing, intention drill-in history view
- **Suggested split on ingestion:**
    - `docs/product/notifications.md`
    - `docs/product/streaks.md`
    - `docs/product/intention-history.md`
    - `docs/decisions.md` (entries in the Decisions section below)
    - `docs/product/open-questions.md` (Open questions section below)

## Status legend

- **SETTLED**: Eric explicitly decided; also recorded in project principles.
- **LEANING**: Eric reacted positively, but it was not stated as a final decision.
- **PROPOSED**: suggested in the chat, not yet confirmed by Eric.
- **SUPERSEDED**: replaced by a later decision (the replacement is noted).
- **OPEN**: unresolved.

---

## 1. Notification delivery

### 1.1 Daily reminders are scheduled on the device. **SETTLED (2026-10-11)**

- Use `flutter_local_notifications` with `zonedSchedule` and a daily repeat.
- **Why:** any reminder time costs nothing; DST, travel, and non-whole-hour timezones handle themselves; no server cost; works offline; scales to millions of users by default.
- Reschedule on every app open, covering the next ~7 days, so notification content can vary (for example, the count of the user's intentions on today's list). iOS caps pending local notifications at 64.
- **Android caveat:** exact alarms need a restricted permission; inexact alarms can drift under Doze and OEM battery savers. A few minutes of drift is acceptable for a prayer reminder. Test early on Samsung and Xiaomi devices.

### 1.2 Social and event notifications use server push (FCM). **SETTLED (2026-10-11)**

- Examples: "Someone prayed for your request," group activity, and similar.

### 1.3 Hourly FCM topics: rejected. **SUPERSEDED by 1.1**

- **Original idea:** one FCM topic per UTC hour, subscribe users to the topics matching their chosen hours, and have a cron job publish to each topic hourly.
- **Rejected because:**
    - Non-whole-hour UTC offsets (India +5:30, Nepal +5:45, Newfoundland −3:30, Adelaide +9:30) can't fit hour buckets.
    - DST needs extra buckets.
    - No personalized content.
    - Users must be resubscribed when they travel.
    - FCM topic fan-out favors throughput over timing, so reminders can arrive minutes late at scale.

### 1.4 Reminder preferences are also stored server-side. **PROPOSED**

- The device does the scheduling, but syncing preferences enables multi-device support, analytics, and a later move to server-sent reminders without a migration.
- If server-sent reminders are ever needed, the pattern is:
    - Store each reminder as a local time plus an IANA timezone.
    - Keep a precomputed, indexed `next_fire_utc` column.
    - Run a per-minute worker that sends due reminders in FCM batches of up to 500.
    - Recompute `next_fire_utc` after each send.

---

## 2. Reminder UX

### 2.1 Presets: Morning, Midday, Evening. **SETTLED (2026-10-11)**

- Each preset has an on/off toggle and an adjustable exact time. Replaces the earlier idea of a 24-hour picker.

### 2.2 Default: one reminder on at onboarding (Morning). **PROPOSED**

- One habit-forming nudge beats three ignored ones.

### 2.3 Custom reminders. **LEANING**

- An "Add reminder" link sits below the presets, capped at 5–7 reminders total.
- Optional labels such as "Before work" or "Bedtime"; the label can become the notification text.
- **Reason for the cap:** notification fatigue leads users to disable notifications at the OS level, which also kills the social pushes in 1.2.

### 2.4 Ignored-reminder check-in. **PROPOSED (later)**

- If a reminder is ignored for 1–2 weeks, gently ask whether the user wants to change its time.

### 2.5 No reminders per intention. **LEANING**

- **Why not:** they fragment the daily ritual into a to-do list, multiply notification fatigue, require lifecycle cleanup when intentions are answered or expire, and expose private text on the lock screen.
- **Instead:**
    - The one daily reminder carries intention context, for example "3 of your intentions are on today's list."
    - One-off **moment reminders** for time-bound events, for example "Surgery Thursday 9am, remind me to pray then." A single scheduled notification with a natural end.
- **Privacy:** intention-specific text in notifications is hidden on the lock screen by default. **PROPOSED**, consistent with the principle that privacy is non-negotiable.

---

## 3. Streaks and last call

### 3.1 Streaks count calendar days in the user's local timezone. **SETTLED (2026-10-17)**

- Duolingo-style. A qualifying prayer between local midnight and midnight keeps the streak.
- The prayer always goes to whatever list is current at that moment.
- Store the device timezone, plus the computed local date, on each prayer at write time, so travelers don't gain or lose days when their timezone changes.

### 3.2 Two clocks, experienced by the user as one rule. **LEANING (Eric: "Seems reasonable")**

- **Streak clock:** the user's local day (3.1).
- **List clock:** the global, manually triggered rollover at about 6am Mountain.
- **List gate:** at assembly, a subject is included if its owner's last list prayer falls within a **48-hour rolling window**. Not "prayed during list N's exact window."
- **Why 48 hours:** someone who prays every local day can have nearly 48 hours between prayers (12:01am Monday, then 11:59pm Tuesday). A shorter window would let a perfect streak still drop someone off the list.
- **Invariant:** keeping your streak always keeps you on the list. Users learn one rule ("pray every day"), and the manual rollover stays invisible to them.
- Gate rules apply equally to all tiers (existing principle).

### 3.3 Last call. **SETTLED that it exists (2026-10-11); delivery LEANING**

- A local notification at about 9pm local time, scheduled only if the user hasn't prayed that local day, and cancelled the moment they pray.
- No server needed. Because of the invariant in 3.2, a separate "list closing" push is unnecessary.

### 3.4 No praying into retired lists. **LEANING**

- Prayers always go to the current list. The 48-hour window is the grace period.
- Cross-reference: per the tech-stack chat, prayers between the cutoff for list N and the assembly of N+1 are credited to N+1.

### 3.5 Streak freezes are earned, never bought. **PROPOSED**

- Example: earn 1 freeze per 7-day streak, hold at most 2.
- Extends the "no paid bypass" engagement-gate principle to streaks.

### 3.6 Gentle framing when a streak breaks. **PROPOSED**

- Example: "Welcome back, your intentions are still here." Avoid broken-streak shame; in a prayer app it can read as moral failure.

### 3.7 Don't show list-number history beside the streak. **LEANING**

- A sequence like "#410, #411, #413" exposes gaps and invites confusion between the two clocks.
- A lifetime count, "Prayed for 87 lists," is fine: it only grows and reveals no gaps.
- Known edge case: users who pray near 8am Eastern (the rollover) alternate between lists without noticing, provided the UI just says "today's list."

---

## 4. Intention history (drill-in view)

### 4.1 Purpose. **SETTLED (2026-10-12)**

- An intention's drill-in shows:
    - How many lists it has been on.
    - Total world prayers it has received.
    - Its history.
    - The owner's own explicit prayers for it.

### 4.2 Personal prayers are only explicit logs. **SETTLED**

- A personal prayer is a prayer intentionally logged to that specific intention in the app.
- General daily-list prayers made while the intention happened to be on the list do **not** count. Counting them would inflate the number and blur the two voices.

### 4.3 Design evolution (for context)

- **v1:** list runs as rows ("Lists #404–#428"), with a dashed "Paused for 3 days" marker between runs. Superseded by v3.
- **v2:** three separate layouts (private / occasionally on the list / always on the list), with the header order flipping by whichever voice dominated. Superseded by v3: Eric loved the content but not having three versions.
- **v3 (current): unified period rows.** **LEANING (2026-10-12)**

### 4.4 v3 layout spec

**Header, fixed order (no flip):**

1. Intention name.
2. **"Held by you · N prayers"**: always present. Serif "voice" font, outlined card, heart icon.
3. **"Carried by the world · N prayers · across N lists"**: appears only after the intention has been on at least one list. Plain UI font, filled card.

**Rationale for the fixed order:** this is the owner's view of their own intention. Their voice is the constant; the world's is additive. Never show "0 lists" or an empty world card.

**Timeline: rows are periods, and the line carries the state.**

- **Rows** are calendar buckets that coarsen with age, newest first: "This week," "Last week," "Earlier in October," then whole months ("September," "August"), then years. The last row reads "Begun · {date}."
- **The line beside each row** is drawn to scale, one slice per day in the period. Each day shows the **intention's status on the world list**, never whether the user prayed:

| Line style | Meaning | Source outcome |
|---|---|---|
| Thick solid (~6px) | On that day's world list | `included` |
| Thin solid (~2px) | Not on the list by design: never promoted, rotated out of a slot, or not eligible | `not_slotted` / `not_eligible` |
| Dashed (~2px) | Should have been on the list but was dropped by the gate (owner exceeded the 48h window) | `excluded_gate` |

- The legend label for thin is **"Private,"** not "You." (An early mockup said "You," which wrongly implied it meant days the user prayed.)
- **The user's personal prayers are not drawn on the line.** They appear only as counts in the row text. This is deliberate: showing per-intention days the user didn't pray would turn each intention into a ledger of absences.
- Possible future option: small dots on the days the user prayed (presence marked, absence unmarked). Deferred, because the line stays clean while it tracks one thing.

**Row text (only what applies):**

- Always: "♡ You prayed N times" (counts only, never ratios like "14 of 16 days").
- If any thick days: "On N lists · N prayers"; the current period adds " · current."
- If any dashed days: "*Paused for N days*" (italic, muted).
- A chevron on each row: tapping expands it into the finer detail (exact list runs such as "Lists #445–#447" and individual days). List numbers live one level down.

**Pause semantics. SETTLED/LEANING (2026-10-12)**

- "Paused" **only** means a gate lapse (`excluded_gate`). Leaving the list by choice, rotation, or ineligibility is never labeled; it just renders as thin line.
- Show the pause for **every** gate gap. The 48h window already filters near-misses, so every gate gap is at least one whole missed list.
- Label pauses in **days**, but compute N from the **number of missed lists**, not wall-clock time. This keeps the label consistent with the list numbers shown in the expanded detail. If a list is skipped (for example, a holiday), that day simply doesn't count, because there was no list to be on. **SETTLED (Eric: days are more intuitive)**
- The expanded detail may show the exact range ("Missed lists #429–#431"). Optional; not needed for launch.
- In the expanded detail, a pause can show personal prayers made during it: "Paused for 3 days · ♡ You still prayed twice." The intention was never abandoned, only not carried by the world.

**Known trade-off:** a short run on the list in the middle of a month becomes a small thick slice inside the month's line instead of its own row. Accepted, because the line shows it and a tap reveals it. Alternative if those moments feel under-weighted: keep each world run as its own row and bucket only the thin stretches between runs. **OPEN (minor)**

### 4.5 v3 ASCII rendering (one intention mixing all states)

Line key: `┃` = on list (thick), `│` = private (thin), `┆` = paused (dashed), `●` = row start while on list, `○` = row start while off list. Each line character is roughly proportional to days.

```
Dad's recovery

╭──────────────────────────────╮
│ Held by you              ♡   │
│ 50 prayers                   │
╰──────────────────────────────╯
╭──────────────────────────────╮
│ Carried by the world         │
│ 791K prayers                 │
│ across 26 lists              │
╰──────────────────────────────╯

Key:  │ Private   ┃ World list   ┆ Paused

●  This week                        ›
┃    ♡ You prayed 2 times
┃    On 2 lists · 61K prayers · current

●  Last week                        ›
┃    ♡ You prayed 6 times
┃    On 4 lists · 120K prayers
│
│
○  Earlier in October               ›
│    ♡ You prayed 2 times
┆    Paused for 3 days
┆
○  September                        ›
┃    ♡ You prayed 24 times
┃    On 20 lists · 610K prayers
┃
│
○  August                           ›
│    ♡ You prayed 16 times
│
○  Begun · August 4
```

Reading September: mostly thick (20 days on the list) with a thin tail (10 days off the list by design). No dashes, so no gate lapses.

### 4.6 The same rules produce every case (no separate layouts)

**Intention never on a list** (never promoted): no world card; every row is thin; rows show only counts.

```
Held by you · 52 prayers          (no world card)

○  This week          ♡ You prayed 5 times
│
○  Last week          ♡ You prayed 7 times
│
○  September          ♡ You prayed 24 times
│
○  August             ♡ You prayed 16 times
│
○  Begun · August 4
```

**Intention always on the list, with one gate lapse:**

```
●  This month         ♡ You prayed 19 times
┃                     On 16 lists · 488K prayers · current
┃
┆                     Paused for 3 days
●  September          ♡ You prayed 31 times
┃                     On 25 lists · 712K prayers
┃
○  First carried · March 2
```

> **Note on the free tier (decided 2026-10-17, after this thread):** free users now get themselves plus one of their own intentions printed. So the "never on a list" case describes **unpromoted** intentions, not free users in general. The history view needs no special handling for tiers; it renders whatever the assembly outcomes say.

### 4.7 Rendering algorithm (pseudo-code)

```
inputs:
  intention_id, owner_tz
  assembly_outcomes: list of (list_number, list_local_date_in_owner_tz, outcome)
      outcome ∈ { included, excluded_gate, not_slotted, not_eligible }
  personal_prayers: list of (timestamp, local_date)   # explicit logs to this intention
  world_counts: map list_number → prayers received while on that list

1. Build day states from intention creation to today:
     for each day: state = outcome of the list current that day
       included                    → THICK
       excluded_gate               → DASHED
       not_slotted / not_eligible  → THIN
     days with no published list (skipped) → omitted entirely (not drawn, not counted)

2. Bucket days into periods, newest first:
     this week, last week, earlier this month, then months, then years
     (exact coarsening thresholds: OPEN)

3. For each period:
     line_segments = runs of identical state, in reverse chronological order,
                     with heights proportional to day counts
     row.you_count   = personal prayers in the period
     row.lists       = count of THICK days (= lists on)
     row.world       = sum of world_counts for those lists
     row.paused_days = count of DASHED days (= missed lists)
     row.is_current  = period contains today and today's state is THICK
     start dot: filled if the newest day in the period is THICK, else hollow

4. Final row: "Begun · {creation date}"
   (or "First carried · {date}" — wording OPEN)

5. Header:
     held_total  = all personal prayers
     world_total = sum of all world_counts
     world card shown only if world_total > 0 (ever on a list)
```

---

## 5. Data model implications (for the schema pass)

- **Assembly outcome per intention, per list.** **PROPOSED; required by section 4**
    - At every list assembly, record an outcome for every eligible-or-owned intention, not just the ones included: `included | excluded_gate | not_slotted | not_eligible`.
    - **This can't be reconstructed later** from inclusion data alone. Without it, a pause can't be told apart from a rotation.
- **On each prayer:**
    - Device IANA timezone and computed local date (for streaks).
    - Explicit links to the intentions/names it was for.
    - Per the tech-stack chat: `listContextNumber`, always set (the list current at write time), and `communityList`, nullable (only on the prayer that qualified the user for the list).
- **On the user:** `currentStreak`, `bestStreak`, `lastPrayedLocalDate`, and a freeze balance (if 3.5 is adopted).
- **Reminder preferences:** preset on/off and times, custom reminders (time, label), and timezone. Synced server-side; scheduled on the device.
- **World counts per intention per list:** aggregated for the history view's totals and row sums.

---

## 6. Open questions

1. **What qualifies a streak day:** any prayer (including personal-only), or only a prayer for the daily list? This matters for the invariant in 3.2: if personal-only prayers count, a streak can survive while the gate drops the user.
2. Exact bucket coarsening thresholds (when weeks merge into a month, and months into a year).
3. Wording of the final row: "Begun · {date}" vs. "First carried · {date}" when the intention has been on the list.
4. Whether short world runs need their own rows (the 4.4 trade-off).
5. Whether to add personal-prayer dots to the line later (4.4).
6. Freeze earn rate and cap (3.5).
7. Moment-reminder UX for time-bound intentions (2.5).
8. Whether to keep the 48h gate window exactly, or tune it after beta data.

---

## 7. Cross-references and conflicts

- **Streak definition: RESOLVED.** The schema draft in the "App features, pricing, and tech-stack" chat defined the streak as consecutive list numbers (`lastPrayedListNumber`). That is superseded by the local-calendar-day streak (this thread; confirmed in principles on 2026-10-17). Replace `lastPrayedListNumber` with `lastPrayedLocalDate`. `listContextNumber` remains useful for the history view.
- **Free-tier list eligibility: RESOLVED by recency.** "Non-premium intentions never on the global list" was replaced on 2026-10-17 by: free tier prints the user plus one intention of their own. See the note in 4.6.
- **Related principles:**
    - Privacy is non-negotiable: names are never shown; scale stands in for weight.
    - The engagement gate applies equally to all tiers.
    - The daily rollover is manual: N+1 is assembled ~6am Mountain and published ~8am.
