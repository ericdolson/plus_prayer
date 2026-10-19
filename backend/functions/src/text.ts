// Name / intention text rules (subjects.md, screens.md): caps count visible
// characters (grapheme clusters), not bytes or code points; any script.

import { HttpsError } from "firebase-functions/v2/https";
import { CONTACT_MESSAGE, hasContactInfo } from "./contact";

const segmenter = new Intl.Segmenter(undefined, { granularity: "grapheme" });

export function graphemeLength(text: string): number {
  let n = 0;
  for (const _ of segmenter.segment(text)) n++;
  return n;
}

/** Trim, collapse whitespace runs (incl. newlines) to one space, NFC. */
export function cleanText(text: string): string {
  return text.normalize("NFC").replace(/\s+/gu, " ").trim();
}

/** The first `cap` grapheme clusters of `text` (never splits a character). */
export function truncateGraphemes(text: string, cap: number): string {
  let out = "";
  let n = 0;
  for (const { segment } of segmenter.segment(text)) {
    if (n++ === cap) break;
    out += segment;
  }
  return out;
}

export function requireName(raw: unknown, cap: number, field = "name"): string {
  if (typeof raw !== "string") throw new HttpsError("invalid-argument", `${field} is required`);
  const text = cleanText(raw);
  if (text.length === 0) throw new HttpsError("invalid-argument", `${field} is required`);
  if (graphemeLength(text) > cap) {
    throw new HttpsError("invalid-argument", `${field} is limited to ${cap} characters`, { cap });
  }
  return text;
}

/**
 * Printed text (names and intentions — not aliases, which are never printed)
 * may not carry contact info or links. The error is shaped for an inline message: code invalid-argument,
 * details { reason: "CONTACT_OR_LINK", field }.
 */
export function requireNoContact<T extends string | null | undefined>(text: T, field: string): T {
  if (typeof text === "string" && hasContactInfo(text)) {
    throw new HttpsError("invalid-argument", CONTACT_MESSAGE, { reason: "CONTACT_OR_LINK", field });
  }
  return text;
}

/** Optional free text (alias / note): undefined = unchanged, null/"" = clear. */
export function optionalText(raw: unknown, cap: number, field: string): string | null | undefined {
  if (raw === undefined) return undefined;
  if (raw === null) return null;
  if (typeof raw !== "string") throw new HttpsError("invalid-argument", `${field} must be text`);
  const text = cleanText(raw);
  if (text.length === 0) return null;
  if (graphemeLength(text) > cap) {
    throw new HttpsError("invalid-argument", `${field} is limited to ${cap} characters`, { cap });
  }
  return text;
}
