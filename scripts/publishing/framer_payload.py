#!/usr/bin/env python3
"""Build the Framer CMS payload for one or more lists from publishing/lists.json.

Usage: python3 scripts/publishing/framer_payload.py N [N ...] --out <file>

Writes a JSON array, one object per list:
  {n, date, souls, intentions, wax, urls: {platform: url}}

- wax comes from the weekday of the list's `date` (ritual/CLAUDE.md rotation),
  named as the website's Wax Colors collection names it (Friday's Antique Brass
  is "Orange" there).
- urls come from each platform's `platform_post_url`. A platform without one is
  left out, which is how an unconfirmed TikTok stays off the site until the
  next day's run confirms it. YouTube and Facebook links are rewritten to the
  /shorts/ and /reel/ forms the site already uses.
"""
import argparse
import datetime
import json
import re
from pathlib import Path

LISTS = Path(__file__).resolve().parents[2] / "publishing" / "lists.json"

# date.weekday(): Monday == 0
WAX_BY_WEEKDAY = {0: "Blue", 1: "Red", 2: "Purple", 3: "Green", 4: "Orange", 5: "Brown", 6: "Gold"}


def normalize(platform, url):
    if platform == "youtube":
        m = re.search(r"[?&]v=([\w-]+)", url)
        if m:
            return f"https://www.youtube.com/shorts/{m.group(1)}"
    if platform == "facebook":
        m = re.search(r"[?&]v=(\d+)", url)
        if m:
            return f"https://www.facebook.com/reel/{m.group(1)}"
    return url


def build(n, entry):
    published = entry.get("published") or {}
    date = entry.get("date") or published.get("date")
    urls = {}
    for platform, info in published.get("platforms", {}).items():
        url = info.get("platform_post_url")
        if url:
            urls[platform] = normalize(platform, url)
    return {
        "n": int(n),
        "date": date,
        "souls": entry.get("soul_count", 0),
        "intentions": entry.get("intention_count", 0),
        "wax": WAX_BY_WEEKDAY[datetime.date.fromisoformat(date).weekday()],
        "urls": urls,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("lists", nargs="+")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    lists = json.loads(LISTS.read_text())["lists"]
    payload = [build(n, lists[n]) for n in args.lists]
    Path(args.out).write_text(json.dumps(payload, indent=1, ensure_ascii=False))
    for row in payload:
        missing = sorted({"youtube", "facebook", "instagram", "threads", "tiktok"} - set(row["urls"]))
        print(f"List {row['n']} · {row['date']} · {row['wax']} · {row['souls']} souls"
              + (f" · no link yet: {', '.join(missing)}" if missing else ""))


if __name__ == "__main__":
    main()
