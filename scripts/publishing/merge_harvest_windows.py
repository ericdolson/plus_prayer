#!/usr/bin/env python3
"""Merge the overlapping enumeration windows from a harvest-comments run.

The Zernio MCP auto-saves large `comments_list_inbox_comments` responses to disk as
`{"result": "<python dict repr>"}` — single quotes, True/False/None — so the payload
is parsed with ast.literal_eval, not json.loads. That is why this is Python.

Usage:
    merge_harvest_windows.py WINDOW_A WINDOW_B [WINDOW_C ...] --out DIR
        [--participants PATH]

Takes two or more window files IN ORDER (A = newest page, each later window
continuing from a cursor inside the previous one). Asserts the safety properties the
harvest depends on, then writes merged.json and fetchlist.json into --out and prints
the deep-fetch decision.

Exits non-zero if any assertion fails — a failed assert means the enumeration may be
missing posts, so the harvest must NOT advance its watermark.
"""
import argparse, ast, json, os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DEFAULT_PARTICIPANTS = os.path.join(REPO, "publishing", "participants.json")


def load_window(path):
    raw = json.load(open(path))["result"]
    return ast.literal_eval(raw)


def key(post):
    return f"{post['platform']}:{post['id']}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("windows", nargs="+", help="window files, in page order")
    ap.add_argument("--out", required=True, help="dir for merged.json + fetchlist.json")
    ap.add_argument("--participants", default=DEFAULT_PARTICIPANTS,
                    help="defaults to <repo>/publishing/participants.json, so cwd does not matter")
    a = ap.parse_args()

    if len(a.windows) < 2:
        sys.exit("need at least 2 windows — a single page cannot be overlap-checked")

    wins = []
    for name, path in zip("ABCDEFG", a.windows):
        w = load_window(path)
        assert w["meta"]["accountsFailed"] == 0, \
            f"window {name}: accountsFailed={w['meta']['accountsFailed']} {w['meta'].get('failedAccounts')}"
        ks = [key(p) for p in w["data"]]
        assert len(ks) == len(set(ks)), f"window {name}: duplicate post within the window"
        print(f"{name} posts {len(w['data'])} hasMore {w['pagination']['hasMore']} "
              f"accountsQueried {w['meta']['accountsQueried']}")
        wins.append((name, w))

    # the final window must reach the tail, or posts are silently missing
    last_name, last = wins[-1]
    assert last["pagination"]["hasMore"] is False, \
        f"window {last_name}: hasMore is True — the tail was never reached"

    # consecutive windows must overlap and agree
    maps = [(n, {key(p): p for p in w["data"]}) for n, w in wins]
    for (n1, m1), (n2, m2) in zip(maps, maps[1:]):
        ov = set(m1) & set(m2)
        assert ov, f"windows {n1}/{n2} do not overlap — possible gap between them"
        for k in ov:
            assert m1[k]["commentCount"] == m2[k]["commentCount"], \
                f"windows {n1}/{n2} disagree on commentCount for {k}"
        print(f"overlap {n1}/{n2}: {len(ov)}")

    merged = {}
    for _, m in maps:
        merged.update(m)
    print("merged total posts", len(merged))

    json.dump({k: {"platform": v["platform"], "id": v["id"], "accountId": v["accountId"],
                   "commentCount": v["commentCount"], "content": v["content"][:60],
                   "permalink": v["permalink"], "createdTime": v["createdTime"]}
               for k, v in merged.items()},
              open(f"{a.out}/merged.json", "w"), indent=1)

    pc = json.load(open(a.participants)).get("post_counts", {})

    def listnum(c):
        m = re.match(r"List (\d+)", c or "")
        return int(m.group(1)) if m else None

    nums = sorted({n for v in merged.values() if (n := listnum(v["content"]))})
    floor = set(nums[-2:])
    print("list numbers seen:", nums[-4:], "| floor =", sorted(floor))

    fetch, skip = [], []
    for k, v in merged.items():
        n = listnum(v["content"])
        if n in floor:
            why = "floor"
        elif k not in pc:
            why = "new"
        elif pc[k] != v["commentCount"]:
            why = f"changed {pc[k]}->{v['commentCount']}"
        else:
            skip.append(k)
            continue
        fetch.append((k, v, why))

    print(f"\nDEEP-FETCH {len(fetch)} SKIP {len(skip)}")
    for k, v, why in sorted(fetch):
        print(f"  {k}  count={v['commentCount']}  [{why}]  {v['content'][:28]!r}")

    json.dump([[k, v["accountId"], v["id"], v["platform"]] for k, v, _ in fetch],
              open(f"{a.out}/fetchlist.json", "w"), indent=1)


if __name__ == "__main__":
    main()
