// Contact info and links are blocked at input (list-lifecycle.md "Moderation
// for MVP / beta", schema-brief §11): names, aliases, and intentions can't
// contain a phone number (7+ digits, allowing separators), an email address,
// or a URL / domain. The same check excludes matching social names at ingest.
//
// Must pass: verse references ("John 3:16", "Isaiah 41:10-13", "Psalm 23"),
// room / ward numbers, dates ("10/18/2026", "2026-10-18", "Oct 18, 2026"),
// memorial year ranges ("1945-2023"), and abbreviations like "St.".

/** The inline message the app shows (same text the app checks against). */
export const CONTACT_MESSAGE = "Names and intentions can't include phone numbers, emails, or links.";

const EMAIL = /[^\s@]+@[^\s@]+\.[a-z]{2,}/i;
const URL_PREFIX = /\bhttps?:\/\/|\bwww\./i;
// A label followed by a real TLD, not followed by more letters ("St. Jude",
// "e.g." and initials don't qualify).
const DOMAIN =
  /\b[a-z0-9][a-z0-9-]*\.(com|net|org|edu|gov|info|biz|io|co|me|ly|app|dev|ai|xyz|online|site|store|blog|page|link|tv|gg|us|uk|ca|au|nz|ie|in|de|fr|es|it|nl|be|ch|at|pt|br|mx|ph|za|ng|ke)(?![a-z])/i;

// Things that look numeric but aren't phone numbers — removed before counting.
const NOT_PHONE = [
  /\b\d{4}-\d{1,2}-\d{1,2}\b/g, // 2026-10-18
  /\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b/g, // 10/18/2026, 18.10.26, 10-18-2026
  /\b(1[89]|20)\d{2}\s*[-–—]\s*(1[89]|20)\d{2}\b/g, // 1945-2023
  /\b\d{1,3}:\d{1,3}(\s*[-–]\s*\d{1,3}(:\d{1,3})?)?\b/g, // 3:16, 41:10-13, 3:16-4:2
];

// A run of digits joined by phone separators (space, dot, dash, parens, plus).
const DIGIT_RUN = /\+?\(?\d[\d\s.()-]*\d/g;

export function hasPhoneNumber(text: string): boolean {
  let t = text;
  for (const re of NOT_PHONE) t = t.replace(re, " ");
  for (const run of t.match(DIGIT_RUN) ?? []) {
    if ((run.match(/\d/g) ?? []).length >= 7) return true;
  }
  return false;
}

export function hasContactInfo(text: string): boolean {
  return EMAIL.test(text) || URL_PREFIX.test(text) || DOMAIN.test(text) || hasPhoneNumber(text);
}
