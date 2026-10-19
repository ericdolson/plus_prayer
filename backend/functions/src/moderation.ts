// Auto-flag patterns for assembly (list-lifecycle.md). Evaluated INSIDE
// Postgres (`~*`, case-insensitive ARE syntax) so names never leave the
// database. NOT flagged by design: all-caps, brand-new accounts.

/** Phone numbers, emails, URLs → CONTACT_OR_LINK. */
export const CONTACT_PATTERN = [
  "[^[:space:]@]+@[^[:space:]@]+\\.[a-z]{2,}", // email
  "https?://|www\\.", // URL prefix
  "[a-z0-9-]+\\.(com|net|org|io|co|me|ly|app|info|biz|xyz|us|uk|ca|tv|gg|link)\\M", // bare domain
  "\\+?[0-9][0-9 ().-]{6,}[0-9]", // phone-like digit run (8+ chars)
].join("|");

/** Whole-word, case-insensitive blocklist → LANGUAGE. null when empty. */
export function blockPattern(words: string[]): string | null {
  const cleaned = words.map((w) => w.trim()).filter(Boolean);
  if (cleaned.length === 0) return null;
  const escaped = cleaned.map((w) => w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
  return `\\m(${escaped.join("|")})\\M`;
}
