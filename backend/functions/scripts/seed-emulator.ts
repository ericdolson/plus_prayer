// seed-emulator — rich test data in the LOCAL EMULATORS (never production).
//
//   npm --prefix backend/functions run seed:emulator                 # every user in the Auth emulator
//   npm --prefix backend/functions run seed:emulator -- --uid UID    # one (repeatable)
//   npm --prefix backend/functions run seed:emulator -- --name "Ann Lee"
//
// The test user is whoever signed in: open the app once against the
// emulators (it signs in anonymously), then run this. With no --uid it seeds
// every user the Auth emulator holds. It wipes the SQL Connect data first.
// What it writes: src/seedEmulator.ts. How to snapshot and restore it:
// backend/CLAUDE.md, "Test on your phone with the emulators".
//
// Refuses to run (exit 2, before any connection) unless every service is
// pointed at a local emulator and the project is demo-* (src/emulatorGuard.ts).

import { parseArgs } from "node:util";
import { assertEmulatorTarget, EmulatorGuardError } from "../src/emulatorGuard";

async function main(): Promise<number> {
  let target;
  try {
    target = assertEmulatorTarget(process.env);
  } catch (err) {
    if (err instanceof EmulatorGuardError) {
      process.stderr.write(`${err.message}\n`);
      return 2;
    }
    throw err;
  }
  const { values } = parseArgs({
    args: process.argv.slice(2),
    strict: true,
    options: { uid: { type: "string", multiple: true }, name: { type: "string" } },
  });

  // Only now load firebase-admin and connect (to the emulators).
  const { deleteApp, initializeApp } = await import("firebase-admin/app");
  const { getAuth } = await import("firebase-admin/auth");
  const { productionDeps, serverConfigFromEnv } = await import("../src/runtime");
  const { seedEmulator } = await import("../src/seedEmulator");
  const app = initializeApp({ projectId: target.projectId, databaseURL: target.databaseURL });
  process.stderr.write(`+Prayer seed-emulator · project ${target.projectId} · EMULATOR (${target.dataConnectHost}, ${target.databaseHost}, ${target.authHost})\n`);
  try {
    let uids = values.uid ?? [];
    if (uids.length === 0) {
      const { users } = await getAuth().listUsers(1000);
      uids = users.map((u) => u.uid);
      if (uids.length === 0) {
        process.stderr.write(
          "No users in the Auth emulator yet. Open the app once against the emulators (it signs in " +
            "anonymously), then run this again, or pass --uid.\n",
        );
        return 1;
      }
    }
    const summary = await seedEmulator(productionDeps(serverConfigFromEnv()), { uids, name: values.name });
    process.stdout.write(`${JSON.stringify(summary, null, 2)}\n`);
    return 0;
  } catch (err) {
    process.stderr.write(`${err instanceof Error ? err.stack ?? err.message : String(err)}\n`);
    return 1;
  } finally {
    await deleteApp(app);
  }
}

main().then((code) => process.exit(code));
