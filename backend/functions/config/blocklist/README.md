# Moderation blocklist (seed)

Seed terms for the LANGUAGE auto-flag at list assembly. A match only HOLDS an
entry for review; it never excludes it on its own.

## Source and attribution
`ldnoobw/*.txt` are unmodified copies from **List of Dirty, Naughty, Obscene,
and Otherwise Bad Words** by Shutterstock and contributors,
https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words
(commit `5faf2ba42d7b1c0977169ec3611df25a3c08eb13`), licensed under
**CC BY 4.0** (`ldnoobw/LICENSE`). Languages: en, es, pt, fr, de, it, nl, pl, ru,
tr, ar, hi, zh, ja, ko, fil.

## Editing
The live list is RTDB `/moderation/blocklist` (server-only; no client access).
`npm run seed:config` writes these seed terms there if the node is empty, and
the functions fall back to these files when it is missing. Edit the RTDB node to
add or remove terms without a deploy.

## Matching
Case-insensitive. Terms in space-delimited scripts match whole words or whole
phrases. Han / Kana / Hangul / Thai terms of two or more characters match as
substrings (those scripts don't separate words); single characters there only
match a whole token, since many appear inside ordinary names.
