# Privacy & Terms

_Last updated: 2026-10-18. Not legal advice — final text via a policy generator
(Termly/iubenda) + lawyer review before launch._

## DECIDED
- **Plain-language summary first**, legal text behind it. Onboarding says it
  in one line on its second step (2026-11-09, second pass): "The list is
  printed and sealed each day, and kept private." ("never shown" alone
  over-promised, since reviewers see names.)
- **Printed list:** single physical copy, sealed, never shared. Names are never
  legible in recordings.
- **Retention of paper:** kept forever, stored at the +Prayer office in a
  locked filing cabinet (lists are also sealed).
- **Who handles lists:** Eric now; helpers later under a confidentiality
  agreement.
- **Minimum account age: 13+** (COPPA). Adults may add children's names as
  subjects. Child accounts may come later if needed.
- **Data collected:** names, aliases, intentions (often health/grief-adjacent —
  declare as sensitive in App Store / Play privacy labels), prayers, optional
  consent-gated location, device timezone.
- **Social names:** public display name + platform ID from public 🙏 comments.
- **Base set:** public NamUs data; resolved cases removed quietly.
- **Anonymous aggregates** (prayer counts, presence, answered total) may appear
  in the app, on the list, and in social captions.
- **Moderation processing:** new/changed names and intentions are reviewed with
  the help of an AI provider (Anthropic) before printing — disclose as a
  processor.
- **Safety disclosure:** may share information with authorities in rare safety
  emergencies; child-safety content reported as required (see safety.md).
- **Deletion:** immediate; past list entries lose name/owner; counts remain;
  subscriptions cancelled via the store.
- **On-device cache** (2026-11-05): the iOS app keeps the user's last query
  results on the device (names, intentions, history) so it works offline.
  - **Cleared** on sign-out and on account deletion: the SQL Connect cache,
    the Realtime Database local cache, and the offline queue. The queue is
    flushed before sign-out and discarded on deletion.
  - **Never in iCloud backups:** the SQL Connect and Realtime Database caches
    and the offline queue are excluded from backup. (The queue lives in
    Application Support, not Caches, so iOS never purges unsent prayers.)
