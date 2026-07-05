# List caption template (locked; updated 2026-07-05)

The standard description shape for a daily list. Voice: spare + subtle human
warmth (see root CLAUDE.md Brand Voice). Fill `{variables}` from the `lists.json`
entry.

## The count line

`List {N} — {X} souls[ & {Y} intentions]`

- Show souls and/or intentions **only when greater than zero**, joined by " & ".
  Right now everything is souls-only.
- Examples: `List 4 — 4,600 souls` · `List 12 — 4,600 souls & 37 intentions`
- Never publish "& 0 intentions" or "0 souls".

## Building blocks

- **Intro** (identical every list, every platform):
  > +Prayer is a daily prayer list, filled by the people who showed up to pray
  > for everyone on the list before. Here, we hold each other. Here is the world
  > plus prayer.
- **Optional source note** (most lists have none). One restrained line max,
  appended to the count line:
  > , filled entirely with {source}. {one optional quiet line, e.g. "May they be found."}
- **Ritual + CTA** — per platform (below); the CTA is always LAST.

## Where the count line goes

- **YouTube** — the count line IS the video **title** (no "— +Prayer" suffix).
  Do NOT repeat it in the description. Description = intro paragraph, then (only if
  there's a source note) the source note on its own line, then ritual + CTA.
- **Everyone else** (Instagram, Facebook, Threads, TikTok) — the count line is the
  **first line** of the description (source note appended if present), then the
  intro paragraph, then ritual + CTA. Leading with the number is the scroll-stopper
  in the truncated preview.

## Per-platform ritual + CTA

- **YouTube / Facebook / Instagram:**
  > Each day's list is printed, sealed, and placed on the table, and the current
  > one is there now. Pray for those on it, and leave a 🙏 when you have — you'll
  > be on the next.

  (Instagram first comment: `How it works — link in bio.`)

- **Threads** (~500-char limit; trim the intro slightly if needed):
  > Printed, sealed, and set on the table each day; the current list is there
  > now. Pray for it, and leave a 🙏 when you have — you'll be on the next.

- **TikTok** — no 🙏-here mechanic (comment aggregation blocked). Keep a 🙏 for
  the eye-draw but anchor it to YouTube/Instagram:
  > Each day's list is printed, sealed, and placed on the table. The current one
  > is there now — head to YouTube or Instagram to leave a 🙏 and join the next.

## Conventions
- Use **souls**, not "names."
- Count line: souls/intentions shown only when > 0 (join with " & ").
- Keep "the world plus prayer" un-commaed — don't over-wink at the pun.
- Do not use "retired" for the ritual — lists are kept, not destroyed. ("Retired"
  is only for the close-out status copy.)
- Covers: Instagram is auto-set via `posts_create_post`; TikTok and YouTube covers
  are manual (see root CLAUDE.md — do NOT set the TikTok cover via Zernio).

## Worked examples

**Other platforms — List 1 (had a source note):**
> List 1 — 4,604 souls, filled entirely with the names of missing children from
> the NamUs database. May they be found.
>
> +Prayer is a daily prayer list, filled by the people who showed up to pray for
> everyone on the list before. Here, we hold each other. Here is the world plus
> prayer.
>
> Each day's list is printed, sealed, and placed on the table, and the current
> one is there now. Pray for those on it, and leave a 🙏 when you have — you'll
> be on the next.

**YouTube — List 3 (no source note):**
Title: `List 3 — 4,568 souls`
> +Prayer is a daily prayer list, filled by the people who showed up to pray for
> everyone on the list before. Here, we hold each other. Here is the world plus
> prayer.
>
> Each day's list is printed, sealed, and placed on the table, and the current
> one is there now. Pray for those on it, and leave a 🙏 when you have — you'll
> be on the next.
