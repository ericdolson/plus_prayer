# Build notes

The build-side twin of `docs/decisions.md`. One file per feature area,
written by whoever builds it (a build agent or subagent), read first by
whoever builds there next.

`docs/product/` says **what** the product does and `docs/decisions.md` says
**why it was decided**. These notes say **how it was built and what not to
undo**: non-obvious implementation choices and why, workarounds and what
they prevent, and approaches tried and dropped.

## Rules
- Read the area's notes before changing code there. If a note explains a
  workaround, keep it unless the brief says otherwise.
- Update the notes in the same commit as the code: add new workarounds,
  remove notes for code that's gone.
- Keep entries short: what, why, where in the code. Date each entry.
- Product behavior belongs in `docs/product/`, not here.

## Files
| File | Area |
|---|---|
| [add-sheet.md](add-sheet.md) | Add sheet (Name / Intention tabs, add-intention form for a person) |
