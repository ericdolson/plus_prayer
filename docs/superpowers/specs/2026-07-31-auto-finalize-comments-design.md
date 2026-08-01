# Auto-finalize comments after publish

**Date:** 2026-07-31
**Status:** approved (design)
**Touches:** `.claude/skills/publish-list/SKILL.md`, `.claude/skills/finalize-comments/SKILL.md`

## Problem

Publishing a list and finalizing its comments are two manual steps separated by a
few minutes of waiting. The wait exists because `finalize-comments` refuses to run
until list N's YouTube, Facebook, and Instagram posts are all `published`. In
practice Eric either sits and waits, or moves on and forgets to run it — leaving
list N‑1's mechanic comment live and pointing at a retired list, and list N with no
🙏 CTA on it at all.

`publish-list` also ends with a 5-section checklist that duplicates what
`finalize-comments` does automatically minutes later. It is noise.

## Goals

1. Publishing is fire-and-forget: one command, no waiting, no reminder to run
   anything afterward.
2. A platform gets finalized as soon as *it* is live, not when the slowest of the
   three is.
3. A platform that never goes live is reported as a failure, not retried forever or
   silently dropped.

## Non-goals

- Automating pinning. Zernio cannot pin on any platform; that stays manual.
- Automating the Threads and TikTok close-out. Both fail at the API
  (`Platform error: 24` / `PLATFORM_LIMITATION`); they stay manual.
- Surviving the end of the session. The timer lives in the session that published.
  If the session ends before the cycle completes, `/finalize-comments N` by hand is
  the recovery — it is idempotent and picks up exactly where the cycle stopped.

## Design

### 1. `publish-list`: drop the checklist, arm a timer

Step 7 (the canonical 5-section post-publish checklist) is removed from the skill.

`publishing/CLAUDE.md` holds that checklist under a heading that currently reads
"Post-publish todo list (CANONICAL — output every time)" and mandates printing it
after every publish. Left alone it would contradict the skill and any agent reading
the workstream context would keep emitting it. So that section is demoted, not
deleted: the mandate language ("output every time", "Never drop a section or a
platform") is removed and the section is reframed as the record of what the manual
close-out process covers — with a pointer to `finalize-comments`, which now does
the automatable parts. Keeping the text preserves the per-platform copy and the
pinning gotchas it documents.

The new final step, after `lists.json` is committed:

- Launch `sleep 300` with `run_in_background: true`. Nothing else — the command is
  a timer, not a check.
- Tell Eric in one line that all five are scheduled and finalize will run itself at
  about +5 minutes.
- End the turn.

Foreground `sleep` is blocked by the harness, and a background command re-invokes
the assistant when it exits. That exit is the wake signal; no polling of any kind
happens in the shell.

### 2. The wake cycle

On each wake, for list N:

1. Call `posts_get` on the `post_id` for youtube, facebook, and instagram from
   `lists["N"].published.platforms`.
2. Run `finalize-comments` for list N. It handles whichever platforms are live (see
   §3) and skips the rest.
3. If any of the three is still not `published`, arm the next timer and repeat. If
   all three are done — or the schedule is exhausted — stop and report.

Wake schedule, measured from the publish command:

| wake | sleep armed | cumulative |
|------|-------------|------------|
| 1    | 300s        | ~5 min     |
| 2    | 180s        | ~8 min     |
| 3    | 240s        | ~12 min    |
| 4    | 480s        | ~20 min    |

Rationale: against a ~2-minute publish lead, YouTube is live ~1.5 min after the
create call, Facebook ~3 min, Instagram ~4–5 min (Lists 21–29, `post.published` log
timestamps). The first wake at +5 min normally finds all three ready and the cycle
ends after one pass. The remaining wakes exist for a slow Instagram transcode; the
worst observed lag is ~3 min past target, so +20 min is far outside normal
behavior.

After wake 4, any platform still not `published` is reported as a failure with its
post id and current status, and the cycle stops. No further timers.

### 3. `finalize-comments`: per-platform gate

The current precondition — all three of youtube/facebook/instagram must be
`published` or STOP — is replaced by a per-platform check.

For each of youtube, facebook, instagram, independently:

- If `lists["N"].published.platforms[platform].post_id` reports `status:
  published`, do **both halves for that platform**: Half A deletes list N‑1's
  logged `mechanic_id` and posts the retired notice; Half B posts list N's mechanic
  comment and logs its id.
- Otherwise skip that platform silently and leave it for a later pass.

Each platform is gated on **its own** list-N post, not on any of the three. The
retired copy says "find the newest list on our channel / Page / profile" — posting
that on YouTube while list N is not yet live on YouTube would point people at
nothing.

No new bookkeeping is needed. The existing idempotency already makes repeated
partial passes safe: Half A skips a platform whose `closeout` is `"done"`, Half B
skips one whose `mechanic_id` is already logged. A platform finalized on wake 1 is
a no-op on wake 2.

The skill's output gains one line naming which platforms it handled this pass and
which are still pending. Its manual checklist (pin the six comments; Threads and
TikTok close-out copy) is unchanged — those are the only things left that a human
must do.

## Edge cases

- **List 1** — no list N‑1 exists. Half A is skipped entirely; Half B still runs.
  (Pre-existing behavior, unchanged by this design.)
- **A platform that was already finalized** — idempotency skips it. Re-running by
  hand at any time is safe.
- **Session ends mid-cycle** — the pending timer dies with it. Nothing is corrupted;
  `/finalize-comments N` by hand completes whatever the cycle did not.
- **Publish itself failed on a platform** — that post never reaches `published`, so
  it is skipped every pass and surfaces in the wake-4 failure report with its
  status.

## Verification

This is a documentation change to two skills; there is nothing to unit-test. It is
verified by the next real publish:

1. `publish-list N` prints no checklist and reports that finalize is armed.
2. A wake fires ~5 min later without Eric doing anything.
3. `lists.json` gains list N's `comments` block and list N‑1's entries flip to
   `closeout: "done"` — for every platform that was live at that wake.
4. Any platform not live at wake 1 is picked up on a later wake, and the commit
   history shows it landing in a separate pass.
