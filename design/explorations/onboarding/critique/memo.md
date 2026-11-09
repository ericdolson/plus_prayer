# Onboarding critique memo

_Critic / researcher, 2026-11-09. Read with `../BRIEF.md`. Ten minutes._

**The short version.** The built flow fails for three reasons, in order of weight: it asks the user to opt in before it has given them anything (Begin), it lectures (two paragraphs, a divider, a footer), and it changes visual register every screen. Eric's reimagined flow fixes the first two and is right about most things, but it is still too long (five screens, three fields, two intentions) and it is tempted by decoration (drifting avatars, floating hands) where the brand says: state the fact and stop. The shape I'd measure the concepts against is **three screens, two fields, under 45 seconds, one true sentence about the mechanic, one moment (the name set in Roca), then Home with Pray as the only lit thing.** Detail below.

---

## 1. Research: the first 60 seconds elsewhere

What matters for us is in bold. Sources are third-party teardowns (Screensdesign, Lazyweb) plus Apple's own text; timings are theirs, not measured by me.

**Hallow (main competitor).** 26 onboarding screens in Lazyweb's capture (11 in another). Order: Welcome ("continue or log in") → **goal selection grid** ("grow closer to God", "pray more", "reduce stress") → **full-name entry** → birthday → App Tracking prompt → a two-part personalization quiz (~0:32–0:54) → **paywall at ~0:54, right at the end of the quiz**: 7-day trial converting to yearly, star ratings and scrolling testimonials. Account is email / US phone / Apple / Google; Apple's Hide My Email is supported. Premium cues: tactile feedback, smooth transitions, one consistent visual register. Cheap cues: the quiz is long, and reviewers' recurring complaint is the trial — surprise charges, "difficult to decipher" terms, 5–7 confirmations to cancel. App Store rating still 4.9 (26k reviews, 2024); Trustpilot 2.5. **Lesson: Hallow asks the name after it has asked what you want, and it monetizes before you have prayed once. We should be the opposite on both.** ([Lazyweb flow](https://design.lazyweb.com/flow/hallow/onboarding), [Screensdesign](https://screensdesign.com/showcase/hallow-prayer-meditation), [help: sign-in](https://help.hallow.com/en/articles/4777807-how-do-i-log-into-the-app), [reviews](https://apptail.io/app/hallow-prayer-meditation-wjp/united-states), [Pillar](https://www.pillarcatholic.com/i/36959783/The%20Pillar))

**Abide.** System notification prompt at **0:00, before the user has done anything** (the teardown calls this out) → goals at 0:15 → signup → trial timeline 0:41 → paywall 0:46 → a post-purchase "Limited Time Offer" and an "Excellent Choices!" screen. The warm tone is undercut by the sequence. ([Screensdesign](https://screensdesign.com/showcase/abide-bible-meditation-sleep))

**Pray.com.** Opens on a testimonial and star rating (0:22) → "new to prayer?" → a **pre-checked list of leaders to follow** (teardown: opt-in would be friendlier; this seeds irrelevant notifications) → quiz → paywall 1:07, 7-day trial → a 50% upsell after subscribing ("aggressive"). ([Screensdesign](https://screensdesign.com/showcase/praycom-bible-daily-prayer))

**Glorify.** Name entry, a themed "Plant a new seed" step, paywall with a sponsorship waitlist. Review aggregators flag paywall friction as the driver of one-star spikes. ([Screensdesign](https://screensdesign.com/apps/glorify-devotional-prayer/))

**Lectio 365.** Free, donation-funded, no paywall. I could not confirm whether it asks for an account at first open; it appears to open directly into today's prayer. Its reputation is built on that absence of friction. ([lectio365.com](https://lectio365.com/the-app/))

**Calm.** Goals → permission → a short first session → account → paywall late in onboarding (the category norm: 54% of health apps paywall in onboarding). Blue gradients, quiet language. The teardown's warning is exactly ours: copying "gradients, nature imagery, and quiet language" without a strong route to the first action "produces mood but not activation." ([Screensdesign](https://screensdesign.com/articles/calm-onboarding-design/), [Lazyweb](https://www.lazyweb.com/research/do-health-and-fitness-apps-paywall-in-onboarding))

**Headspace.** A **three-question quiz**; their own team reports that both very short and very long onboarding tested worse. Paywall before any full session is the standard critique. ([Appcues](https://goodux.appcues.com/blog/headspaces-mindful-onboarding-sequence), [Sub Club](https://metacast.app/podcast/sub-club-by-revenuecat/DlWjuiPD/how-headspace-optimized-revenue-by-gating-content-shreya-oswal-and-keya-patel-headspace/7BAelw9D))

**Duolingo.** The canonical case: **do the core action (a lesson) before any account**, then ask to "save your progress." Their delayed-signup A/B is reported at roughly +20% DAU (the source is fragmentary; the direction is well attested). ([Taplytics](https://taplytics.com/blog/duolingo-ab-test-onboarding), [Appcues](https://goodux.appcues.com/blog/duolingo-user-onboarding))

**Finch.** Hatch an egg → color → pronouns → **name the bird** → trait → the bird asks **your** name in a chat bubble → then a long tail of self-care questions, which critiques flag as the friction point. The hook works because the first thing you name is not yourself. ([Screensdesign](https://screensdesign.com/articles/finch-app-onboarding-design/), [Pratt critique](https://ixd.prattsi.org/2025/09/design-critique-finch-ios-app-2/))

**Apple's own setup (iOS Setup Assistant; from direct knowledge).** One decision per screen, a large light title and one sentence of body, a single blue button, "Set Up Later" on nearly every step, no progress indicator, sign-in offered but skippable. The HIG's words: "design a flow that's fast, fun, and optional"; "Teach through interactivity"; "Postpone nonessential setup flows or customization steps"; "Prefer letting people experience your app… before prompting them for ratings or purchases." ([HIG Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding))

**Beautiful minimal onboarding (direct knowledge).** *Things 3* has none: you land in an inbox pre-seeded with a few to-dos that teach by being there. *Flighty* asks for one thing (a flight) and then shows you what it does with it. *Bear* opens on a set of welcome notes that are themselves the tutorial. Common thread: **the product's own object is the onboarding.** For us, that object is the list.

**App Store rules that bind us.** 5.1.1(v): "If your app doesn't include significant account-based features, let people use it without a login… Apps may not require users to enter personal information to function, except when directly relevant to the core functionality." Our name is core functionality (it prints); anonymous-first satisfies the rest. 4.8: because we offer Google, we must also offer a login service that limits data to name and email and allows a private email, i.e. Sign in with Apple, which is already planned. If we support account creation we must offer in-app deletion (already decided). ([Guidelines](https://developer.apple.com/app-store/review/guidelines/))

**Notification permission.** Apple: "sending the request in context provides a better experience than automatically requesting authorization on first launch." Vendor data claims 2–3x opt-in with a primer screen and iOS averages near 50%; treat the numbers as directional, the direction as solid. ([Apple](https://developer.apple.com/design/human-interface-guidelines/notifications), [Plotline](https://www.plotline.so/blog/how-to-improve-push-notification-opt-in-rates))

**What "premium" is, across all of this.** One typographic register. One ground. Large, light type, short sentences. The product's own object on screen. Asking for little, and asking late. "Cheap" is: a quiz, testimonials before value, a prompt at 0:00, mixed button styles, a lecture.

---

## 2. Critique

### (a) The built flow: Welcome → Name → Welcome back → Someone → Intention

| Screen | Verdict | Why |
|---|---|---|
| **Welcome** (seal, two lines, Begin, sign-in link) | **Change: merge into Name.** | Eric is right. A screen whose only action is "Begin" makes the user opt in to being onboarded. Keep the ground and the photograph; put the name field on it. The sign-in link stays here, quiet, at the bottom. |
| **Name** ("What's your name?", 96 pt avatar, field, Continue) | **Keep the one-field principle; change the register.** | Large Title bold sans is the "yelling" Eric felt. Use a lighter sans or Roca medium at Title 1, left-and-center consistent with the rest. The 96 pt empty avatar before anything is typed is a hole; let the avatar materialize when the name does. |
| **Welcome back** ("Welcome, Eric Olson." + two paragraphs + divider + "Who else do you hold?" + footer + two differently styled buttons) | **Cut.** | This screen is the lecture. "Welcome, Eric Olson." is performed warmth (Eric: "feels fake"). Two paragraphs teach three verbs (pray, carried, hold) at once. The footer is a privacy policy. Two button styles (blue capsule, gray glass) are the visual incohesion in miniature. What survives: one sentence about the mechanic and one optional question, each on its own screen. |
| **Someone** (grouped Form, Name + alias, big avatar, Continue) | **Change: one field, no form chrome, no alias.** | Tier B form chrome belongs in Settings, not a ceremony. The clipped left-aligned title is a bug, but the deeper fault is two fields with two captions teaching the printed/private distinction before the user has seen a single row on Home. Alias is learned in the add sheet later. |
| **Intention** for that person | **Cut from onboarding.** | A third concept (intention, "one can be printed") on screen five. Home teaches it in context the first time they open a person. |
| **Return to Welcome back** with avatar row, "Add another" | **Cut.** | Looping back to a screen the user already left is the clunk. After the optional person, go to Home. |

Underneath the screens: push navigation between pages with different alignment, type and button grammar is the real failure. No amount of copy fixes it. The flow needs **one stage** (see §3, Continuity).

### (b) Eric's reimagined flow

**Screen 1: leader + name field + CTA + login.** **Keep, with changes.** Right call to lead with the name on the first screen: the name is the product (it prints), and there is no keyboard on arrival so the photograph can breathe. Changes: (1) The CTA must be labeled, not an arrow. An unlabeled arrow is the cheap kind of minimal and fails the 40+ rule (labeled buttons) and VoiceOver. "Continue" is fine. (2) Of the leaders, cut "Welcome to the world's prayer community" (performs community) and "Let's pray" (chummy). "Welcome to the world's prayer list" is factual and distinct; "Here is where we pray" is closest to the voice. Candidates in §5. (3) Login: one quiet link, not two logo buttons (see §3). (4) The name becoming Roca with the avatar materializing: **this is the moment. Keep it, and make it the only motion the flow owns.**

**Intention screen ("for yourself").** **Cut from onboarding** (see §3). The help text "You can add others later" proves the question is in the wrong place: you are writing copy to stop people answering the question they want to answer.

**Mechanic screen.** **Keep, as the quietest screen in the app.** One sentence, the photograph of the real list, one CTA. Cut "We will carry you in prayer" (a "we" narrating a feeling; also not quite true, the list carries them, people pray). Cut the floating praying hands and the drifting avatar: Eric already suspects "too much movement," and he is right; it would be the brand performing. Cut "Hold your loved ones in personal prayer or carry them onto the list too": two verbs, one of them a paid feature, before the first prayer. The CTA should not be "Add someone else to pray for" (it buries the option to skip inside a question); make it "Continue" and let the next screen ask.

**Another name.** **Keep, optional, one field.** Agree on no big avatar. Cut the alias field here (it is the add sheet's job) and cut both proposed CTAs: "Add an intention" opens a fourth concept and "I'll just hold them by name" is cute copy that assumes vocabulary. One primary "Continue", one text link "Not now".

**That name's intention.** **Cut.** Same reason as above.

**Never more than one other name.** **Agree.**

**Net:** Eric's five screens become three. Name → one sentence → one optional person → Home.

---

## 3. Positions

**End in the first prayer, or on Home with Pray primed?** **On Home, Pray primed; do not auto-open prayer.** The last onboarding transition should deliver the user onto Home with the pray button arriving last and alone, the community card showing today's list, and nothing else asking for attention. Rationale: a prayer should be chosen, not be step four of a form; the brand lets people fill in the meaning. The counter-argument (Duolingo: do the core action before anything else) is weaker here because Pray is one tap away and takes ten seconds, so the hand-off *is* the invitation. PM: the 14-day clock still starts at a chosen first prayer, not at install, which is what we want. Engineer: Home is already the only surface that knows today's list; no onboarding-only prayer path. UX: one transition to design (onboarding → Home), which is the one Eric asked for. 40+: landing on a screen and seeing it before acting is the reassuring order.

**Self intention?** **Not in onboarding. Ask it at "You'll be carried on List 53," after the first Amen.** That is the first moment the user knows their name prints, so "Is there something you're praying for, for yourself? It can print beside your name." is understood, and it lands on the self because the frame is "beside your name." It is the free tier's one printed intention, so it matters; it also matters that it is answered well. If Eric insists on onboarding, the only framing that routes it correctly is the printed-name frame plus a placeholder that models a self request ("steadiness this week"), and it still becomes the screen most people skip. PM: a later ask has a higher answer rate at the moment of payoff. Engineer: the post-Amen sheet already exists. UX: one less field in onboarding. 40+: fewer decisions before the first screen they can look at.

**Sign-in.** **One quiet text link at the bottom of screen 1, "Already have an account? Sign in", opening a native sheet with Apple and Google buttons.** Two logo buttons on a first screen read as a sign-in wall to a new user, who is 95% of first screens. Apple + Google must both exist (4.8), and anonymous-first satisfies 5.1.1(v). **"Continue with Apple" as a way to supply the name: not worth making primary.** Apple returns the name only on the first authorization, users edit or hide it, and it turns the name step into account creation, which is the opposite of anonymous-first. Typing a name is three seconds. Do the cheap version: if someone signs in on screen 1 and the account is new, prefill the field and show it set in Roca: "This is how it prints. Change it if you like." If the account exists, skip onboarding (already decided).

**Continuity.** **One stage; elements morph in place; back is always a labeled control; no progress dots; no paging.** A progress indicator tells the user they are in a quiz; for three steps it adds noise. Paging/swiping fails the 40+ rule. What makes one-stage morphing read premium rather than disorienting: the ground, the type scale, the field's position and the CTA's position never move; only content changes, and the avatar is the one object that persists and travels (matchedGeometryEffect). Honor Reduce Motion with a cross-dissolve. Engineer: one SwiftUI view with a phase enum, not a NavigationStack; the "‹" becomes an explicit Back button in the same spot every time.

**Ground.** **The warm near-black already defined, `welcomeGround` #15110E, for the whole of onboarding, in both appearances. The hand-off to Home is a color-temperature shift: warm dark → cool dark (#0E1012), or warm dark → light (#E9EEF9) with a 600 ms dissolve.** The spec scopes "antique" to the ritual on camera; onboarding is where the ritual is shown, so the warm ground is earned there and only there. Not a blue/purple gradient (that is Calm's and Headspace's register and says "wellness app"); not parchment or cream (craft); no texture or vignette heavier than what a photograph brings on its own. Light-mode risk: a dark-to-bright step; the dissolve and Home's pray button arriving last make it feel like stepping out, not a flash.

**Teach the mechanic.** **One sentence before the first prayer. Minimum true sentence: "Pray with today's list, and tomorrow your name is on it."** Optionally a second, factual: "The list is printed and sealed each day. It's never published." Nothing about hold/carry/alias/intention/trial. Home's rows and captions teach those by doing. If a concept needs a paragraph in onboarding, it is in the wrong place.

**Another person in onboarding.** **Yes, one, optional, one field.** The person is why most people came. A Home with only "Me" is empty, and "Who's someone you pray for?" is the question that makes the product real. But each extra field halves completion and each caption is a lesson; so: name only, "Printed on the list" as the single caption, "Not now" always visible. Alias and intention live in the add sheet.

**Notification timing.** **Keep it after the first Amen: "You'll be carried on List 53" → reminder time → system prompt.** This is the textbook contextual ask (Apple's guidance, and Abide's 0:00 prompt is the cautionary example). The reminder-time choice is the primer; the user has just been told what the reminder is for. Do not move it into onboarding; nothing in onboarding has earned it yet.

**The moment.** **One: the user's name becoming Roca and the avatar materializing out of it, under the words "This is how your name prints."** It is small, true, and theirs. The wax seal belongs to Amen, already the app's signature motion; spending it in onboarding cheapens the first real one. The photograph of the actual sealed list is the proof, not the moment: it belongs on screen 1 as the ground, saying what this is without a sentence. (Asset to shoot: the sealed list in warm low light, names illegible, slow 5–8 s loop later.)

---

## 4. Eight principles to judge the concepts by

1. **Ask for one thing before you give anything, and give something right after.** The name, then the name set as it prints.
2. **One sentence of mechanic, true in every word.** No verbs the user hasn't needed yet.
3. **One stage, one register.** Same ground, type scale, field and CTA position from first screen to last; only content morphs.
4. **Nothing optional looks mandatory; "Not now" is always visible and never shamed.**
5. **No performed warmth.** No "Welcome, {name}", no narrated feelings, no testimonials. Facts, and space.
6. **One moment, earned.** The name in Roca. The seal waits for Amen.
7. **The product's own object is the onboarding.** The real list on screen, not an illustration of the idea of a list.
8. **Everything after onboarding is asked in context:** sign-in to keep the list safe, the self intention at "List 53," notifications after the first Amen, payment after the trial.

---

## 5. Copy bank

Top pick per slot marked **▶**.

**Leader (screen 1)**
- ▶ "Here, we pray for each other."
- "The world's prayer list."
- "One list. Everyone. Every day." (already in use; works as a second line)
- "Your name, carried by the world." (the splash line; strong, but it is already on the launch screen a second earlier)

**Invitation above the name field**
- ▶ "What's your name?"
- "Your name, as it will print."

**Field placeholder**
- ▶ "Your name"

**After the name is entered (the moment)**
- ▶ "This is how your name prints."
- "This is how it prints on the list."

**The mechanic, one sentence**
- ▶ "Pray with today's list, and tomorrow your name is on it."
- "Pray with the list today. Tomorrow it carries you."
- "Each day the list is printed and sealed. Pray with it, and your name is on the next one."

**Second factual line (optional)**
- ▶ "The list is printed and sealed each day. It's never published."
- "Names are reviewed before they are printed. The list is kept private."

**The other person**
- ▶ "Who's someone you pray for?"
- "Is there someone you pray for?"
- Caption: ▶ "Printed on the list" · "They'll be on the list with you."

**CTAs**
- Primary: ▶ "Continue" throughout; last screen ▶ "Begin" (one word, then Home)
- Secondary: ▶ "Not now" · "Skip for now"
- Sign-in link: ▶ "Already have an account? Sign in"
- Prefilled-from-Apple confirm: ▶ "Change it if you like."

**Landing on Home, one line if any**
- ▶ "Today's list is ready."
- (or nothing: the pray button and the community card say it)

**Post-Amen self intention (not onboarding, for reference)**
- ▶ "Is there something you're praying for, for yourself? It can print beside your name."

Lines to avoid, with the reason: "Welcome, Eric Olson." (performed); "We will carry you in prayer" (we, narrating); "I'll just hold them by name" (cute, assumes vocabulary); "Let's pray together" (chummy); anything with "community," "strangers," "around the world."
