// Seed RTDB /config with the compiled defaults — only keys that are missing,
// so tuned values are never overwritten — and /moderation/blocklist with the
// bundled seed (config/blocklist, CC BY 4.0) if it is empty.
//   FIREBASE_DATABASE_URL=https://<db>.firebaseio.com npm run seed:config
//   (emulator: FIREBASE_DATABASE_EMULATOR_HOST=127.0.0.1:9000 and
//    FIREBASE_DATABASE_URL=http://127.0.0.1:9000?ns=demo-plusprayer-default-rtdb)

import { initializeApp } from "firebase-admin/app";
import { CLIENT_CONFIG_DEFAULTS } from "../src/config";
import { rtdbLive } from "../src/live";
import { seedBlocklist } from "../src/moderation";

const databaseURL = process.env.FIREBASE_DATABASE_URL;
if (!databaseURL) {
  console.error("Set FIREBASE_DATABASE_URL (see the header of this script).");
  process.exit(1);
}
initializeApp({ databaseURL, projectId: process.env.GCLOUD_PROJECT ?? "demo-plusprayer" });

const live = rtdbLive();
live
  .writeClientConfigDefaults(CLIENT_CONFIG_DEFAULTS)
  .then(async (added) => {
    console.log(added.length ? `Added /config keys: ${added.join(", ")}` : "/config already has every key");
    const terms = seedBlocklist();
    const wrote = await live.writeBlocklistIfMissing(terms);
    console.log(wrote ? `Seeded /moderation/blocklist (${terms.length} terms)` : "/moderation/blocklist already set");
    process.exit(0);
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
