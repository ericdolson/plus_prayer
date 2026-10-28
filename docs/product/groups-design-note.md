# Design note — Prayer groups (future, Stage 4+)

_Recorded 2026-10-28. Not built — direction for when groups are designed.
Linked from design-direction.md and roadmap.md (Stage 4+)._

## Layout on Home
```
(group pic)  Family
   ├ (Mom)  Mom · Rest after surgery
   ├ (Eric) Gary Olson · Heart health        ← shared by me
   └ (Ruth) Ruth · A safe delivery
```
- A **group is a top-level row** like a name: group picture (set by an admin) or
  a monogram, plus the group name.
- On the same thread underneath: each **shared item** shows the **sharer's small
  avatar**, then the item. Same gestures as everywhere else: check it in prayer;
  the prayer is logged to *that member's* item; gold dot = you held it today.
- Your own shared items appear in the group with your avatar (confirmation that
  they're shared).
- **Large groups:** the Home row shows a few items (most recent / your own
  first) + "See all (42)"; the full list lives on the group's page. Large groups
  start collapsed.

## Sharing
- **Any** of your items can be shared, not only items under "Me" — e.g. Dad's
  heart-health intention (like a family prayer chain).
- Aliases stay owner-only. At share time the sharer chooses how it appears to the
  group: default the real name ("Gary Olson · Heart health"), or a group-facing
  label ("My dad", "Eric's dad"). → future optional `Share.displayLabel`.
- One-line confirmation when sharing: "Family will see 'Gary Olson · Heart
  health'." (It's someone else's personal information.)

## Value: seeing each other pray
- Owner's detail page shows the tier-2 count: "Family prayed for this 14 times".
- Gentle FCM social push: "Mom prayed for Gary's heart health."
- Marking an item **Answered** shows to the group — shared gratitude.

## Rules / gotchas
- **Printing is unchanged:** sharing never affects what's printed; the owner's
  carry pool decides; nothing prints twice.
- **Group-owned intentions** ("our family reunion"): maybe later; start with
  member-shared items only.
- **Safety:** group-visible text is user content others see → reporting,
  blocking, and moderation apply (safety.md S7).

## Schema
Fits the planned seams: `Group`, `Membership`, `Share` (subject → group or
PUBLIC; one item, many targets), prayers linking to items owned by others with
permission from group membership, tier-2 counts. Only addition: optional
`Share.displayLabel`. Nothing to build now.
