# Onboarding exploration: shared brief (2026-11-09)

Every agent working on this reads this whole file first.

## Why we're here
+Prayer's onboarding was built (2026-11-09) and it doesn't work. Eric, the founder, after using it on his phone:

> - It's just that nothing about it feels like "high end" onboarding. A variety of fonts and buttons. It feels visually cold and not warm.
> - The "Who's someone you pray for" isn't centered like it was for the user's name. It is also cropped on the left. It's also super chunky, even the "What's your name" is chunky. These do not feel warm and inviting. Kinda like yelling.
> - The screens don't feel cohesive from one to the next at all. Not like a single onboarding should feel.
> - The screens also just feel like a next page. There is no indicator showing where I am in the onboarding (prob doesn't matter) to feel like I am sliding through an onboarding. Or the elements could animate morph in/out in place in a single page to feel like I'm not just clunkily hopping from one thing to another. Basically, the onboarding should feel like a single experience and then moving to the home screen for the first time should feel like the transition. This also brings me back to picking a colored background for the onboarding. Something that helps set it apart.
> - I am also not liking the initial page that has nothing but a begin button. It does not scoop me into an onboarding flow. I have to opt into the flow. I think I was wrong to suggest this one.

What he saw: screen 3 had "Welcome, Eric Olson." in big Roca, two body paragraphs in sans, a hairline divider, a bold sans "Who else do you hold?", a faint footer, a bright system-blue "＋ Add someone" capsule and a gray glass "Add others later", on the app's near-black ground (#0E1012). Screen 4 had a Large Title bold sans question left-aligned (and clipped), a big orange avatar, a grouped-form "Name" field and a Continue button that the keyboard pushed into the field. Mixed fonts, mixed alignment, mixed button styles, default iOS chrome, push navigation between unrelated-looking pages.

His reimagined flow (he says: **not a prescription**, "oh we still have work to do"; scrutinize it heavily):

> - Screen 1 — Get name (required): a leader in a medium header font ("Let's pray together", "Here is where we pray", "Welcome to the world's prayer list", "Welcome to the world's prayer community", "Let's pray"). A smaller invitation above a text field ("What is your name?", "Who are we praying for?"; placeholder "Your name"). A CTA, maybe just an arrow. Maybe on tap the name field's text becomes Roca and their avatar materializes out of it. A login button on the page (bottom, or top-right). No keyboard on arrival: they choose to type or log in. Since there's no email/password, maybe just Apple and Google icons, or one "Sign in" with a menu. Should we let them make an account here (Sign in with Apple gives us their name)? Maybe too cumbersome.
> - Intention screen? "Is there something we can help you pray for, for yourself?" An intention field. Help text like "You can add others to pray for later" so they don't put "help my son find a job" here.
> - Mechanic (skippable): no "Welcome, so-and-so" (feels fake; we have real warmth to offer). Something like "We will carry you in prayer". Maybe their avatar subtly lifted (shadow below), praying-hands icons floating upward, the avatar gently drifting as if carried on them (or on a sea of tiny avatars). Maybe too much movement. Or show an image of a real list. "The prayer list is printed each day with your name as you pray for the community." "Hold your loved ones in personal prayer or carry them onto the list too." Skip top-right. CTA "Add someone else to pray for".
> - Another name (skippable): name + alias, no big avatar (loud). CTAs maybe "Add an intention" and "I'll just hold them by name".
> - That name's intention (skippable): very simple. CTA "Let's pray" or "Begin" → Home. Never more than one other name in onboarding.
>
> Think high-end apps, minimal, warm, inviting. The onboarding can have its own words; use your imagination. Think of onboarding holistically, not step by step. Weigh what's important. Think of Hallow, our main competition. "If we get a user to have downloaded the app and they are here, we have to make this so perfect."

## What +Prayer is (facts the onboarding must get right)
- One global daily prayer list. **Pray with today's list → you are carried (printed) on tomorrow's list.** Being on the list is the reward for praying, never a purchase.
- The list is physically printed, stitched, wax-sealed and retired on camera each day. Names are never legible on camera; the list is private, never published. Names are reviewed (curated, not a live feed).
- In the app you keep the people you pray for ("hold" them in personal prayer). You can also **carry** them onto the printed list. Free: you and one intention. The paid tier (14-day trial from the first prayer) carries others: a pool of 10 people, each printed with one chosen intention. Before the first prayer, everyone has the trial pool, so people added during onboarding are carried.
- A person has a **name** (printed: "Julie Olson") and an optional private **alias** ("Mom", only the user sees it). An **intention** is a request (healing, a new job, peace); one can print with its person.
- Praying = open Home, tap Pray, check who you're holding, ~5 s countdown, Amen → wax seal moment. A prayer can carry a private journal entry.
- Auth: anonymous-first (no sign-in wall), plus Sign in with Apple and Google for existing accounts / keeping your list safe. No email/password. Sign in with Apple can supply a name on first authorization.
- Interfaith, tradition-neutral. Audience skews 40+: one decision per screen, labeled buttons, full Dynamic Type, back always possible.
- After onboarding: Home (the user's list of people, a community card with today's list and its wax seal, a floating Liquid Glass pray button). The first Amen later triggers: "You'll be carried on List 53." → reminder time → notification permission (already decided; you may propose moving it).

## Brand rules (mandatory)
- Voice: **observational, spare, human.** Facts, with restraint; one quiet emotional line at most; no hype, no urgency, no "every corner of the world", no "held by strangers", no performed warmth ("We're so glad you're here!"). Numbers aren't editorialized. A quiet inclusive "we" is fine.
- Darker over lighter; antique/aged over bright or modern (wax, light, materials). Every object belongs to the ceremony.
- Color jobs in the app: blue = action, gold = held, everything else neutral; no red, no pink. Onboarding may have its **own ground** (Eric wants a colored background that sets it apart), but must hand off to Home believably.
- Type: **Roca** (a warm serif) for names, list numbers and big lines; system sans (SF Pro) for body. Eric now finds bold sans titles "chunky, like yelling".
- iOS 26, Liquid Glass, SwiftUI. Native-first for forms/chrome; custom effort goes to signature moments. One signature motion in the app today is Amen → seal (onboarding may earn its own moment; justify it).

## Assets you can use in a mock (repo-relative; reference with relative paths from your mock)
- Roca fonts: `app/assets/fonts/Roca_100.otf … Roca_900.otf` (+ italics), also `apps/ios/PlusPrayer/Resources/Fonts/Roca-Regular.otf`, `Roca-Bold.otf`.
- Wax seal PNGs: `app/assets/img/wax_stamps/wax-{blue,brown,gold,green,neutral,orange,purple,red}.png`; iOS seals in `apps/ios/PlusPrayer/Assets.xcassets/Seals/`.
- Wordmark / logo: `app/assets/splash_image.png`, `app/assets/img/+prayer_logo*.svg`, `app/assets/img/+prayer_icon.svg`.
- Design tokens (colors, avatar tones, type, spacing): `design/tokens.json`. Visual system: `docs/product/design-direction.md`. Current onboarding spec: `docs/product/auth-onboarding.md`. Current code: `apps/ios/PlusPrayer/Features/Onboarding/`.
- No photograph of the real list exists in the repo yet (one can be shot; the spec planned a photo/loop of the sealed list on screen 1). Represent it with a tasteful stand-in and say what the real asset should be.

## Rules for every agent
- Write only inside your own folder under `design/explorations/onboarding/`. Don't edit anything else, no git commands, no commits.
- Never touch Firebase, production or the emulators.
- No copying Hallow or any other app's look; learn from patterns only.
- When you're done, your final message is a short summary (≤250 words) pointing to your files; the files hold the detail.
