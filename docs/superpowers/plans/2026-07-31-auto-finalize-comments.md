# Auto-Finalize Comments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make publishing fire-and-forget — `publish-list` arms a background timer that wakes Claude to run `finalize-comments`, which now finalizes each platform as that platform goes live instead of waiting for all three.

**Architecture:** Three markdown files change; no code. `publish-list` loses its post-publish checklist and gains a timer-arming final step plus a documented wake cycle. `finalize-comments` swaps its all-or-nothing precondition for a per-platform gate. `publishing/CLAUDE.md` loses the duplicated checklist section, keeping one line from it.

**Tech Stack:** Markdown skill files. Verification is `grep`/`Read`, not a test runner — there is nothing executable here.

## Global Constraints

- **Spec:** `docs/superpowers/specs/2026-07-31-auto-finalize-comments-design.md`. Read it before starting.
- **Never alter locked copy.** The mechanic comment, the retired notices, the caption template, and the brand-voice rules are verbatim constants. This plan does not change a single character of any of them.
- **Zernio is reachable only over MCP.** There is no API key in the shell environment. Any shell step is a bare timer; every status check is an MCP `posts_get` call made by Claude.
- **Foreground `sleep` is blocked** by the harness. Timers must use Bash with `run_in_background: true`.
- **Wake schedule (exact):** `sleep 300` → `sleep 180` → `sleep 240` → `sleep 480`, landing at roughly +5, +8, +12, and +20 minutes after publish.
- **Automatable platforms are youtube, facebook, instagram only.** Threads and TikTok fail at the API (`Platform error: 24` / `PLATFORM_LIMITATION`) and stay manual, every run.
- Commit after each task.

---

### Task 1: `publish-list` — drop the checklist, arm the timer

**Files:**
- Modify: `.claude/skills/publish-list/SKILL.md` (frontmatter `description`; the intro line; step 7; new wake-cycle section)

**Interfaces:**
- Consumes: nothing.
- Produces: the wake cycle that invokes the `finalize-comments` skill with argument `N`. Task 2 makes that skill safe to call before all platforms are live.

- [ ] **Step 1: Update the frontmatter description**

The current `description` ends with `then record results and output the post-publish checklist.` Replace that clause so the skill is not advertised as printing a checklist:

```yaml
description: >-
  Publish or schedule a +Prayer daily prayer list across all five social
  platforms (YouTube, Facebook, Instagram, Threads, TikTok) via the Zernio MCP,
  record the result, then auto-run finalize-comments on a timer once the posts
  go live. Use when the user says "publish list N", "post list N", "schedule
  list N", "publish list N at 9am", "publish list N in 5 minutes", or "publish
  list N now".
```

- [ ] **Step 2: Update the intro line**

Replace:

```markdown
Publishes list **N** to all five platforms with the Zernio MCP, records the result
in `publishing/lists.json`, and outputs the canonical post-publish checklist.
```

with:

```markdown
Publishes list **N** to all five platforms with the Zernio MCP, records the result
in `publishing/lists.json`, and then finalizes the comments by itself — a background
timer wakes Claude a few minutes later to run `finalize-comments` for list N.
```

- [ ] **Step 3: Replace step 7 with the timer-arming step**

Delete step 7 in its entirety:

```markdown
7. Output the canonical 5-section post-publish checklist from `publishing/CLAUDE.md`,
   filled in for N and N-1, with complete copy-paste comment text per platform.
```

Replace it with:

```markdown
7. Arm the auto-finalize timer, then STOP:
   - Launch `sleep 300` with Bash `run_in_background: true`. It is a bare timer —
     do NOT try to check post status from the shell (Zernio is MCP-only, there is no
     API key in the environment).
   - Tell Eric in one line: all five scheduled for <time>, and finalize-comments
     will run itself at ~+5 min.
   - End the turn. Do NOT print a post-publish checklist — `finalize-comments`
     produces the only list of things left to do by hand.
```

- [ ] **Step 4: Add the wake-cycle section**

Insert this as a new `##` section immediately after the `## Steps` section and before `## Gotchas`:

```markdown
## Auto-finalize wake cycle

The background timer's exit re-invokes you. On each wake, for list N:

1. `posts_get` the youtube, facebook, and instagram `post_id`s from
   `lists["N"].published.platforms`.
2. Invoke the `finalize-comments` skill with N. It finalizes every platform that is
   `published` and silently skips the rest — partial passes are safe and expected.
3. If all three are finalized, report what landed and stop. Otherwise arm the next
   timer from the schedule and repeat.

| wake | timer to arm | lands at    |
|------|--------------|-------------|
| 1    | `sleep 300`  | ~+5 min     |
| 2    | `sleep 180`  | ~+8 min     |
| 3    | `sleep 240`  | ~+12 min    |
| 4    | `sleep 480`  | ~+20 min    |

Normally wake 1 finds all three live and the cycle ends in one pass: against a
~2-minute publish lead, YouTube is live ~1.5 min after the create call, Facebook
~3 min, Instagram ~4–5 min. The later wakes exist for a slow Instagram transcode.

**After wake 4, stop.** Report any platform still not `published` with its post id
and current status. Do not arm a fifth timer — at +20 min it is a real failure, not
a lag.

If the session ends mid-cycle the pending timer dies with it. Nothing is corrupted;
`/finalize-comments N` by hand completes whatever the cycle did not.
```

- [ ] **Step 5: Verify the checklist is gone and the timer is documented**

Run:

```bash
grep -n "checklist\|sleep 300\|wake" .claude/skills/publish-list/SKILL.md
```

Expected: no line describing a 5-section post-publish checklist output; `sleep 300` present in both step 7 and the wake table; the only remaining "checklist" mention is the step-7 line saying not to print one.

- [ ] **Step 6: Commit**

```bash
git add .claude/skills/publish-list/SKILL.md
git commit -m "publish-list: drop post-publish checklist, arm auto-finalize timer"
```

---

### Task 2: `finalize-comments` — per-platform gate

**Files:**
- Modify: `.claude/skills/finalize-comments/SKILL.md` (intro line; `## Precondition` section; Half A and Half B intros; `### Finish`; `## Related`)

**Interfaces:**
- Consumes: the wake cycle from Task 1 invokes this skill with argument `N`, possibly while some platforms are still `publishing`.
- Produces: a pass that finalizes only the live platforms and reports which are still pending, so Task 1's cycle knows whether to arm another timer.

- [ ] **Step 1: Update the intro line**

Replace:

```markdown
Runs **once list N's posts are live**. In one idempotent pass it:
```

with:

```markdown
Runs as soon as **any** of list N's posts is live — usually invoked automatically by
`publish-list`'s wake cycle. In one idempotent pass, for each platform that is live:
```

- [ ] **Step 2: Replace the precondition section with the per-platform gate**

Delete this entire section:

```markdown
## Precondition — list N must be LIVE
For each of youtube/facebook/instagram in `lists["N"].published.platforms`, call
`posts_get` on the `post_id` and confirm `status: published`. Instagram is the
usual laggard (it sits at `publishing` for a few minutes). If any of the three is
not yet `published`, STOP and tell the user to re-run in a couple of minutes —
don't do a partial pass. (List N‑1 is already long-live, so Half A has no wait.)
```

Replace it with:

```markdown
## Per-platform gate — finalize each platform as IT goes live
Do NOT wait for all three. For each of youtube/facebook/instagram, call `posts_get`
on `lists["N"].published.platforms[platform].post_id`:

- `status: published` → do **both halves for that platform** in this pass.
- anything else (usually `publishing` — Instagram is the usual laggard) → skip that
  platform silently and leave it for a later pass.

Each platform is gated on its **own** list-N post, never on another's. The retired
copy says "find the newest list on our channel / Page / profile", so posting it on
YouTube while list N isn't live on YouTube yet points people at nothing.

A partial pass is normal, not a failure. The idempotency rules in Gotchas mean a
later pass picks up exactly what was skipped, and re-running is always safe.
(List N‑1 is already long-live, so Half A never waits on anything of its own.)
```

- [ ] **Step 3: Scope both halves to the platforms that passed the gate**

In Half A, replace:

```markdown
Read `lists["N-1"]`. For each of **youtube, facebook, instagram**:
```

with:

```markdown
Read `lists["N-1"]`. For each of **youtube, facebook, instagram that passed the
per-platform gate above**:
```

In Half B, replace:

```markdown
Read `lists["N"]`. For each of **youtube, facebook, instagram**:
```

with:

```markdown
Read `lists["N"]`. For each of **youtube, facebook, instagram that passed the
per-platform gate above**:
```

- [ ] **Step 4: Add the pass summary to the Finish section**

Replace:

```markdown
### Finish
Commit `lists.json`, then output the manual checklist (below).
```

with:

```markdown
### Finish
Commit `lists.json`, then output:

1. One line naming what this pass did, e.g.
   `Finalized: youtube, facebook · Still publishing: instagram` — so the caller
   knows whether another pass is needed.
2. The manual checklist (below), unchanged and in full. It is short, every item on
   it is still owed, and a later pass reprinting it is harmless.
```

- [ ] **Step 5: Update the Related section**

Replace:

```markdown
- Runs after `publish-list` (which schedules the posts and writes
  `published.platforms`). A future enhancement will let `publish-list` wait for
  the posts to go live and call this skill automatically ("publish and walk
  away"); for now invoke it manually once the posts are live.
```

with:

```markdown
- Runs after `publish-list` (which schedules the posts and writes
  `published.platforms`). `publish-list` now invokes this skill automatically from
  its wake cycle at ~+5 min, re-running as later platforms go live — "publish and
  walk away." Invoking it by hand still works and is the recovery path if the
  session ended before the cycle finished.
```

- [ ] **Step 6: Verify the gate replaced the precondition**

Run:

```bash
grep -n "Precondition\|per-platform gate\|STOP" .claude/skills/finalize-comments/SKILL.md
```

Expected: no `## Precondition` heading and no "STOP and tell the user to re-run"; `per-platform gate` appears in the new section heading and in both Half A and Half B intros.

- [ ] **Step 7: Commit**

```bash
git add .claude/skills/finalize-comments/SKILL.md
git commit -m "finalize-comments: gate per platform instead of all-or-nothing"
```

---

### Task 3: `publishing/CLAUDE.md` — delete the checklist section

**Files:**
- Modify: `publishing/CLAUDE.md` (step 8 of "What Claude does on publish"; delete the `### Post-publish todo list` section; one line added to `## Comment aggregation pipeline`)

**Interfaces:**
- Consumes: nothing.
- Produces: nothing. This removes the last instruction that would make an agent print the checklist Task 1 deleted.

- [ ] **Step 1: Update step 8 of "What Claude does on publish"**

Replace:

```markdown
8. Output a post-publish todo list (see below).
```

with:

```markdown
8. Arm the auto-finalize timer (`sleep 300`, backgrounded) and stop. The
   `finalize-comments` skill runs itself at ~+5 min and handles each platform as it
   goes live; its output is the only list of remaining manual steps. Do NOT print a
   post-publish checklist.
```

- [ ] **Step 2: Delete the entire `### Post-publish todo list` section**

Delete from the heading:

```markdown
### Post-publish todo list (CANONICAL — output every time)
```

through the closing fence of its code block, ending with these lines:

```markdown
── 5. Next list ──
- [ ] Ask Claude to harvest 🙏 since the watermark into participants.json pending[[N+1]]
- [ ] Run `npm run participants-pdf` in `scripts/` for the printable list
```

and the ` ``` ` that closes the block. The next heading, `### First comment & pinning
per platform (new video)`, must survive intact with exactly one blank line before it.

Nothing else in the file moves. The per-platform close-out copy lives in
`## Daily transition timing`, the pinning mechanics in `### First comment & pinning
per platform`, and the cover steps in `### Thumbnails / covers per platform` — all
untouched.

- [ ] **Step 3: Relocate the `participants-pdf` pointer**

It is the only prose mention of the printable-list step outside `scripts/package.json`,
so it must not die with the section. At the very end of the `## Comment aggregation
pipeline` section — directly after the line:

```markdown
Filter by **comment** time, not post time — that's what makes a same-day 🙏 on an
old post count toward the next list.
```

append:

```markdown

Once a list's participants are harvested, run `npm run participants-pdf` in
`scripts/` to turn `pending[N]` into the printable list.
```

- [ ] **Step 4: Verify the deletion is clean and nothing was lost**

Run:

```bash
grep -n "participants-pdf\|Post-publish todo\|output every time\|post-publish checklist" publishing/CLAUDE.md
grep -n "^### \|^## " publishing/CLAUDE.md
```

Expected: `participants-pdf` appears exactly once, inside the comment aggregation section; no `Post-publish todo` heading and no "output every time"; the heading list runs `### Scheduling procedure` → `### First comment & pinning per platform` with no gap or orphaned code fence between them.

- [ ] **Step 5: Confirm the retired/mechanic copy still exists in the file**

Run:

```bash
grep -c "is retired — but a 🙏 here still counts" publishing/CLAUDE.md
```

Expected: 4 (the YouTube, Facebook, Instagram, and Threads variants in `## Daily transition timing`). If this returns 0, the wrong section was deleted — revert and redo Step 2.

- [ ] **Step 6: Commit**

```bash
git add publishing/CLAUDE.md
git commit -m "publishing: delete post-publish checklist section, keep participants-pdf pointer"
```

---

## Verification (whole plan)

There are no tests. The change is verified on the next real publish:

1. `publish-list N` prints no checklist and reports that finalize is armed.
2. A wake fires ~5 min later with no user action.
3. `lists.json` gains list N's `comments` block and list N‑1's entries flip to
   `closeout: "done"` for every platform that was live at that wake.
4. Any platform not live at wake 1 lands in a later pass, visible as a separate
   commit.

Until that publish happens, the three `grep` verification steps above are the only
checks available.
