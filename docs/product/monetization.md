# Monetization

_Last updated: 2026-10-17_

## DECIDED
- **App subscription is the sole meaningful revenue vehicle.** No brand deals
  (permanently), no donations (redirected to 🙏 participation). Ads negligible.
  Social content is ad-free and sponsor-free; it's a funnel to the app.
- **Model A — self is the dividend, not a slot.** A participant is always carried
  for free. Paid tiers let users carry OTHERS. Never "pay to be carried."
- **Engagement gate applies to all tiers.** Paid users must pray the list like
  everyone else; no convenience bypass.
- **`includeLimit`** stored as a concrete number on User (supports one-off
  grants), server-written only on billing events. The **pool** = carried
  **people** beyond the user's own name (Q32, 2026-11-08); intentions never
  cost a place. **Free = 0** (you, with your intention).
- **`basePremiumPool = 10`** (2026-10-18, server config): the reverse trial grants
  exactly the base subscription's pool, so subscribing changes nothing. One
  value drives both; tune before launch. **One source:** RTDB `/config`
  `basePremiumPool`, read by the server's grant and by the app (2026-11-06).
- **Effective entitlement is computed:** expired entitlement + no active
  subscription ⇒ free limit (no scheduled job).
- **Trial-end soft landing:** assembly keeps carrying the full trial portion
  until the user completes the trial-end choice, up to 7 days; after that only
  the self name, with its chosen intention (free under Q32), until they choose. Portion screen shows "Waiting for your choice".
  Never a silent drop. **Applies to any entitlement ending** — trial end or a
  lapsed subscription (2026-10-18). No extra field: "over the free limit with no
  active entitlement" triggers it. For lapsed payments, the store's own billing
  grace period comes first (entitlement stays active); the 7 days start after.
- **Quality bar:** very premium-feeling app, accessibly priced.

- **Free tier = you + one intention of your own** (2026-10-17, "option C").
  Social carries only your name; the free app adds one printed request of your
  own (under your self-row); premium carries others. SUPERSEDES the earlier note
  that non-premium intentions are never on the global list.
- **Reverse trial** (2026-10-17, "option D"): every new user gets premium free
  for ~14 days with NO payment info and NO auto-renew (not an App Store
  free-trial/intro offer). A heads-up comes before it ends (~day 10). After it
  ends, the account settles to the free tier and is invited — gently — to
  subscribe. Carried history from the trial stays permanently visible
  ("Daniel was carried on 14 lists").
- **Private adding is unlimited and free** (reconfirmed 2026-10-18): any number
  of names and intentions for personal prayer, no private paywall. Growth is the
  priority; every private name is a future reason to carry (the real conversion
  lever), and a private cap would read as "paying to remember people". Only
  printed-list capacity (and later, guided prayer) is gated. A ~500-name soft
  safety cap per account exists only against abuse ("contact us"), not as a
  paywall. It counts only active items, so archiving frees room (add-sheet
  copy: "Archive some to add more."); a quiet ~5,000 total-row hard cap
  backs it (2026-11-06). Power users like pastors are the future group/organization customer.

- **Paid unit = carried people** (Q32, decided 2026-11-08; supersedes
  "names and intentions", 2026-10-17). One carried person = one **place**
  (the word the app uses; upsell copy may say "Carry 10 people"). Me is
  free and always carried. Each carried person, Me included, prints with
  **up to 1 chosen intention** (`/config` `intentionsPerPerson`, start at
  1; raising is the generous direction, never lower it). Intentions cost
  nothing; choosing which one prints is the choice. Private intentions stay
  unlimited. No "and N more" on the paper: with a chosen intention there's
  nothing left over to count, and printing how many private intentions
  someone has would leak what they didn't choose to print. **Free tier:**
  you, with your intention; carrying others is membership. More intentions
  per person, if ever wanted, is a **tier property** (a higher per-person
  cap, e.g. Plus: up to 3 each), never an à la carte add-on. Tiers and
  prices stay open. Managed on the person's page and the **"your portion"**
  screen (illustrative preview: each person with their chosen intention).
  Not called "lines" (printing word-wraps).
- **Over-limit paywall** (2026-10-17): users may select beyond their limit; the
  meter shows e.g. "17 / 15" with an upgrade mark, and saving invites the
  upgrade.
- **Trial end flow** (2026-10-17): 14 days, heads-up ~day 10. At the end, first
  invite them to subscribe to keep everything as is. If they decline, open the
  portion selection so they can trim to the free limit (1 intention + self). If
  they still save above the limit, the paywall invitation appears again as a
  second chance.

- **Declining at an over-limit save blocks the save** (2026-10-17): the user
  returns to the portion screen to trim, extras highlighted. We never make silent
  choices about who is carried.
- **Auto-carry** (2026-10-17; Q32 2026-11-08): new names are carried
  automatically while the pool has room; a new intention is auto-chosen to
  print when its person has fewer than the cap chosen (else it's saved
  unchosen, and the add sheet offers to print it instead). When the pool is full, a new item is saved for
  private prayer and the add sheet says so (never silently); on Home it simply
  has no carried mark (design-direction §5 — absence is never marked).
- **Add-sheet upsell cadence — PROPOSED, not decided** (2026-11-06; build as a
  placeholder, see open-questions Q31): a stronger membership invitation
  only on the **first** full-pool add of the user's local day; later adds that
  day get only a small "Your portion" link. No upsell when there's no larger
  pool to offer. Copy and layout in screens.md (add sheet). To be refined with
  the rest of the monetization flow.

## OPEN (product meeting)
- **Price.** Earlier target $20–30/yr ("membership, not paywall"). Later idea
  ~$3–5/mo ($36–60/yr). Monthly, annual, or both?
- Trial abuse via fresh anonymous accounts (low stakes).
- **Tiers.** One premium tier or several (`plan_a`, `plan_b` with different slot
  counts)?
- **Billing provider:** RevenueCat vs. StoreKit / Play Billing direct.
- **Upgrade surfaces** and their tone (humane; never on a crisis subject).

## DEFERRED
- Group plans / gifting a membership.
