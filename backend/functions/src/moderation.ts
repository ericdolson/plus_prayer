// Word-blocklist inputs for assembly (list-lifecycle.md). Matching happens
// INSIDE Postgres (admin/lists.gql AssembleList) so names never leave the
// database. OFF for the beta (ServerConfig.wordBlocklistEnabled); returns at
// Stage 2. Contact info / links are a separate, always-on check (contact.ts).
// NOT flagged by design: all-caps, brand-new accounts, base-set names.

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { Live } from "./deps";

/**
 * Same normalization the SQL applies to names: lower case, runs of
 * whitespace / ASCII punctuation → one space, trimmed.
 */
export function normalizeTerm(term: string): string {
  return term.normalize("NFC").toLowerCase().replace(/[\s!-/:-@[-`{-~]+/gu, " ").trim();
}

// Scripts written without spaces between words.
const UNSPACED = /[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Hangul}\p{Script=Thai}]/u;
const segmenter = new Intl.Segmenter(undefined, { granularity: "grapheme" });
const graphemes = (s: string) => [...segmenter.segment(s)].length;

export interface BlockTerms {
  /** Whole words / phrases (matched between spaces after normalization). */
  words: string[];
  /** Matched anywhere: unspaced-script terms of 2+ characters. */
  substrings: string[];
}

/**
 * Unspaced-script terms of two or more characters match as substrings; a
 * single character there (many occur inside ordinary names) only matches a
 * whole token, like every other term.
 */
export function splitTerms(raw: string[]): BlockTerms {
  const words = new Set<string>();
  const substrings = new Set<string>();
  for (const r of raw) {
    const t = normalizeTerm(r);
    if (!t) continue;
    if (UNSPACED.test(t) && graphemes(t) >= 2) substrings.add(t);
    else words.add(t);
  }
  return { words: [...words].sort(), substrings: [...substrings].sort() };
}

function seedDir(): string | null {
  // src/ (tsx, tests) or lib/src/ (compiled, deployed)
  for (const dir of [resolve(__dirname, "..", "config", "blocklist"), resolve(__dirname, "..", "..", "config", "blocklist")]) {
    if (existsSync(dir)) return dir;
  }
  return null;
}

const lines = (path: string) =>
  readFileSync(path, "utf8").split(/\r?\n/).map((l) => l.trim()).filter((l) => l && !l.startsWith("#"));

/**
 * The bundled seed: config/blocklist/ldnoobw/*.txt (CC BY 4.0, see README),
 * minus name-exclusions.txt (words that are also given names / nicknames).
 */
export function seedBlocklist(): string[] {
  const dir = seedDir();
  if (!dir) return [];
  const src = join(dir, "ldnoobw");
  const excludeFile = join(dir, "name-exclusions.txt");
  const excluded = new Set(existsSync(excludeFile) ? lines(excludeFile).map(normalizeTerm) : []);
  return readdirSync(src)
    .filter((f) => f.endsWith(".txt"))
    .sort()
    .flatMap((f) => lines(join(src, f)))
    .filter((t) => !excluded.has(normalizeTerm(t)));
}

/** The editable list (RTDB /moderation/blocklist), else the bundled seed. */
export async function loadBlockTerms(live: Live): Promise<BlockTerms> {
  let terms: string[] | null = null;
  try {
    terms = await live.readBlocklist();
  } catch {
    // RTDB unavailable: use the seed.
  }
  return splitTerms(terms && terms.length ? terms : seedBlocklist());
}
