# Notifications

_Last updated: 2026-10-17_

## DECIDED
- **Daily prayer reminders are on-device scheduled (local) notifications.**
  Choices: Morning / Midday / Evening. (The hourly-topic idea was dropped.)
- **Social/event notifications use server push (FCM).**
- **Last call at ~8pm local** (2026-10-18; seed's ~9pm rejected — 8pm feels less
  intrusive).
- **"Last call"** streak reminder — see streaks-reminders.md. Local notification
  is the natural fit (it knows the user's timezone and whether they've prayed).

- **MVP server push (FCM):** only an opt-in, default-off "Today's list is live"
  (video published). (2026-10-18)
- **Everything else is local:** daily reminder, ~8pm last call, day-10 trial
  notice (scheduled at first prayer). Grace-day offers appear in-app (no push).
- **Last call fires only if the user hasn't prayed WITH THE LIST today**
  (revised 2026-10-18, matches the days-with-the-world streak). Two wordings:
  not prayed at all → "A moment for prayer before the day ends."; prayed but not
  with the list → "Today's list is still open. Hold them with you before the day
  ends." A prayer with the list cancels today's local last call (works offline).
- Skip "You were carried on List N" push — shown in-app.
- "List is live" copy (2026-10-18): "List 52 is up · 4,345 people, including you."

## Notification content & privacy (2026-10-18)
- **Names and aliases are allowed** in notifications by default ("Today's list ·
  you, Dad + 4 others").
- **Intention text never appears** in notifications — except a moment reminder's
  own words, which the user wrote for that reminder.
- **Setting:** You → Notifications → "Show names in notifications" (on by
  default) for fully blank reminders.
- Note: the seed's 2026-10-11 PROPOSED "intention text hidden on lock screen"
  was narrower; this decision settles it.

## From seed 2026-10-11 (SETTLED there unless noted)
- Local scheduling via `flutter_local_notifications` `zonedSchedule`;
  reschedule ~7 days ahead on each app open (iOS 64-pending cap) so content can
  vary ("3 of your intentions are on today's list"). Android inexact-alarm drift
  acceptable; test Samsung/Xiaomi early.
- Presets Morning / Midday / Evening, each with toggle + adjustable time.
- PROPOSED: default one reminder on at onboarding (Morning).
- LEANING: custom reminders ("Add reminder", labels, cap 5–7 total).
- LEANING: no per-intention reminders; later, one-off **moment reminders**
  ("Surgery Thursday 9am").
- PROPOSED: reminder prefs synced to the server (time + IANA tz), scheduled on
  device — consistent with "settings stored on the User record".
- PROPOSED (later): check in if a reminder is ignored for 1–2 weeks.
- Broken-streak framing: "Welcome back, your intentions are still here."

## OPEN

- Default reminder times for Morning / Midday / Evening; multi-select?
- Copy for every notification (brand voice).
