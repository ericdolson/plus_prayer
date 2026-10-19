// Calendar-day helpers. Dates travel as "YYYY-MM-DD" strings (SQL Connect
// Date); instants as JS Dates / ISO strings.

const DAY_MS = 86_400_000;

export function isValidTimeZone(tz: string | null | undefined): tz is string {
  if (!tz) return false;
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}

/** The calendar date of `at` in `timeZone` (falls back to UTC). */
export function localDateIn(timeZone: string | null | undefined, at: Date): string {
  const tz = isValidTimeZone(timeZone) ? timeZone : "UTC";
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: tz,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(at);
}

export function utcDate(at: Date): string {
  return at.toISOString().slice(0, 10);
}

/** Whole days from `a` to `b` (b - a). */
export function daysBetween(a: string, b: string): number {
  return Math.round((Date.parse(`${b}T00:00:00Z`) - Date.parse(`${a}T00:00:00Z`)) / DAY_MS);
}

export function addDays(date: string, days: number): string {
  return utcDate(new Date(Date.parse(`${date}T00:00:00Z`) + days * DAY_MS));
}

/** 0 = Sunday … 6 = Saturday (ritual/CLAUDE.md wax rotation starts Sunday). */
export function weekday(date: string): number {
  return new Date(`${date}T12:00:00Z`).getUTCDay();
}

export function addMs(at: Date, ms: number): Date {
  return new Date(at.getTime() + ms);
}

export const HOUR_MS = 3_600_000;
export const MINUTE_MS = 60_000;
export { DAY_MS };
