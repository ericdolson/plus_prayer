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
  grants), server-written only on billing events. **Free = 1** (an intention
  under "Me"). The **pool** = everything carried beyond the user's own name; each
  extra name and each intention counts as one.
- **`basePremiumPool = 10`** (2026-10-18, server config): the reverse trial grants
  exactly the base subscription's pool, so subscribing changes nothing. One
  value drives both; tune before launch.
- **Effective entitlement is computed:** expired entitlement + no active
  subscription ⇒ free limit (no scheduled job).
- **Trial-end soft landing:** assembly keeps carrying the full trial portion
  until the user completes the trial-end choice, up to 7 days; after that only
  the self name until they choose. Portion screen shows "Waiting for your choice".
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
  paywall. Power users like pastors are the future group/organization customer.

- **Paid unit = a pool of carried names and intentions** (2026-10-17). Each
  name or intention counts as one; not called "lines" (printing word-wraps).
  Managed on the **"your portion"** screen, which shows an illustrative preview
  of how it reads on the list (not an exact print layout). An intention can only
  be carried if its name is.
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
- **Auto-carry** (2026-10-17): new names/intentions are carried automatically
  while the pool has room. When the pool is full, a new item is saved for
  private prayer and clearly marked as not on the list (never silently).

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
