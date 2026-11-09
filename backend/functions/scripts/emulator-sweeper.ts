// emulator-sweeper — stands in for the triggers the Functions emulator can't
// run, so a prayer logged by the app against the emulators has its effects
// (list count + RTDB /lists/current mirror, streak and grace, trial,
// DailyStats) within a few seconds, as onPrayerLogged gives in production.
//
// The Functions emulator ignores SQL Connect `onMutationExecuted` triggers
// (onPrayerLogged) and scheduled functions without a Pub/Sub emulator
// (sweepUncountedPrayers). This runs the same module those run
// (src/prayers.ts sweepUncountedPrayers, which calls processPrayer) every
// few seconds. scripts/emulators.sh starts it next to the emulators.
//
// Refuses to run unless pointed at the local emulators (src/emulatorGuard.ts).

import { assertEmulatorTarget, EmulatorGuardError } from "../src/emulatorGuard";

const INTERVAL_MS = Number(process.env.SWEEP_INTERVAL_MS ?? 3000);

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
  const { initializeApp } = await import("firebase-admin/app");
  const { productionDeps, serverConfigFromEnv } = await import("../src/runtime");
  const { sweepUncountedPrayers } = await import("../src/prayers");
  initializeApp({ projectId: target.projectId, databaseURL: target.databaseURL });
  const deps = productionDeps(serverConfigFromEnv());
  process.stderr.write(`+Prayer emulator sweeper · ${target.projectId} · every ${INTERVAL_MS} ms\n`);
  let quietErrors = 0;
  for (;;) {
    try {
      const applied = await sweepUncountedPrayers(deps, 0);
      if (applied > 0) process.stderr.write(`sweeper: applied ${applied} prayer(s)\n`);
      quietErrors = 0;
    } catch (err) {
      // The emulators may still be starting, or be restarting.
      if (quietErrors++ % 20 === 0) process.stderr.write(`sweeper: ${err instanceof Error ? err.message : String(err)}\n`);
    }
    await new Promise((r) => setTimeout(r, INTERVAL_MS));
  }
}

main().then((code) => process.exit(code));
