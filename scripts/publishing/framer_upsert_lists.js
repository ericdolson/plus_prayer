// Upsert +Prayer lists into the Framer CMS (Lists + List Socials collections).
// Runs inside `npx @framer/agent@latest exec`, which has no argv: prepend a line
// defining PAYLOAD (the file framer_payload.py wrote) and pipe the result in:
//
//   { echo "const PAYLOAD = '<payload.json>';"; cat scripts/publishing/framer_upsert_lists.js; } \
//     | npx @framer/agent@latest exec -s <session>
//
// Idempotent: a list is matched by slug (its number) and a link by (list, platform).
// Missing entries are created, changed values are updated, nothing is deleted.
// New lists are placed directly above the next-lower list number, so the
// collection stays in descending order.

const fs = require("fs");
const rows = JSON.parse(fs.readFileSync(PAYLOAD, "utf8"));

const LISTS = "ECDTh2hoB";
const LIST_SOCIALS = "N1Iy6Nn6Y";
const WAX = { Red: "NoLnuZfeH", Orange: "To0bQewMx", Purple: "doPUMh4iV", Green: "kRBFTbrOw", Brown: "MyoDU4Nhe", Blue: "pOrL1NijW", Gold: "UD8DPbufa" };
const SOCIAL = { instagram: "hwLZTaRr_", youtube: "gvVghrCTU", facebook: "v5goi_ka9", tiktok: "vqE1mUPFt", threads: "B6VltCzDz" };
const PLATFORM_ORDER = ["threads", "tiktok", "facebook", "youtube", "instagram"];

const q = (s) => JSON.stringify(String(s));
const report = [];

for (const row of rows.sort((a, b) => a.n - b.n)) {
  const lists = (await framer.agent.serialize({ id: LISTS, depth: 1 })).children ?? [];
  const socials = (await framer.agent.serialize({ id: LIST_SOCIALS, depth: 1 })).children ?? [];

  const fields = {
    $control__slug: row.n,
    $control__souls_count: row.souls,
    $control__count: row.souls + row.intentions,
    $control__date: `${row.date}T00:00:00.000Z`,
    $control__wax_color: WAX[row.wax],
  };
  if (row.intentions) fields.$control__intentions_count = row.intentions;

  let cmd = "";
  let listRef;
  const existing = lists.find((l) => l.attributes.$control__slug === String(row.n));
  if (existing) {
    listRef = existing.id;
    const changed = Object.entries(fields).filter(([k, v]) => existing.attributes[k] !== String(v));
    if (changed.length) cmd += `SET ${listRef} ${changed.map(([k, v]) => `${k}=${q(v)}`).join(" ")};\n`;
  } else {
    listRef = `L${row.n}`;
    let index = lists.findIndex((l) => Number(l.attributes.$control__slug) < row.n);
    if (index < 0) index = lists.length;
    cmd += `+CollectionItemNode ${listRef} parent="${LISTS}" index=${index};\n`;
    cmd += `SET ${listRef} ${Object.entries(fields).map(([k, v]) => `${k}=${q(v)}`).join(" ")};\n`;
  }

  const added = [], updated = [];
  for (const platform of PLATFORM_ORDER) {
    const url = row.urls[platform];
    if (!url) continue;
    const link = existing && socials.find((s) => s.attributes.$control__list === existing.id && s.attributes.$control__social === SOCIAL[platform]);
    if (link) {
      if (link.attributes.$control__deep_link !== url) {
        cmd += `SET ${link.id} $control__deep_link=${q(url)};\n`;
        updated.push(platform);
      }
    } else {
      const ref = `S${row.n}${platform}`;
      cmd += `+CollectionItemNode ${ref} parent="${LIST_SOCIALS}" index=0;\n`;
      cmd += `SET ${ref} $control__list="${listRef}" $control__social="${SOCIAL[platform]}" $control__deep_link=${q(url)};\n`;
      added.push(platform);
    }
  }

  if (cmd) await framer.agent.applyChanges(cmd);
  report.push(`List ${row.n}: ${existing ? (cmd ? "updated" : "unchanged") : "created"}`
    + (added.length ? ` · links added: ${added.join(", ")}` : "")
    + (updated.length ? ` · links changed: ${updated.join(", ")}` : ""));
}

console.log(report.join("\n"));
