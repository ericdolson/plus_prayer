// Admin CLI for Eric's skills — the admin callables, run locally with a
// service account. Commands and output: src/adminCli.ts (`npm run admin -- help`).
//
// Setup (once):
//   1. Firebase console → Project settings → Service accounts → "Generate new
//      private key". Keep the file OUTSIDE the repo (e.g. ~/.config/plusprayer/).
//   2. export GOOGLE_APPLICATION_CREDENTIALS=~/.config/plusprayer/service-account.json
//   Optional: FIREBASE_DATABASE_URL (default https://<project>-default-rtdb.firebaseio.com)
//
// Config is read like the deployed functions': backend/functions/.env and
// .env.<projectId> (written by `firebase deploy` when it asks for the params),
// then the environment. Against emulators: set DATA_CONNECT_EMULATOR_HOST /
// FIREBASE_DATABASE_EMULATOR_HOST and GCLOUD_PROJECT instead of a key.

import { existsSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { cert, deleteApp, initializeApp } from "firebase-admin/app";
import { errorJson, runAdminCommand, USAGE } from "../src/adminCli";
import { productionDeps, serverConfigFromEnv } from "../src/runtime";

const FUNCTIONS_DIR = resolve(__dirname, "..");

/** KEY=VALUE lines (# comments); never overrides what's already set. */
function loadEnvFile(path: string): void {
  if (!existsSync(path)) return;
  for (const line of readFileSync(path, "utf8").split(/\r?\n/)) {
    const m = /^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/.exec(line);
    if (!m || line.trimStart().startsWith("#")) continue;
    process.env[m[1]] ??= m[2].replace(/^(["'])(.*)\1$/, "$2");
  }
}

async function readStdin(): Promise<string> {
  const chunks: Buffer[] = [];
  for await (const chunk of process.stdin) chunks.push(chunk as Buffer);
  return Buffer.concat(chunks).toString("utf8");
}

async function main(): Promise<number> {
  const command = process.argv[2];
  if (command === undefined || command === "help" || command === "--help") {
    process.stdout.write(`${USAGE}\n`);
    return 0;
  }
  const emulated = !!(process.env.DATA_CONNECT_EMULATOR_HOST || process.env.FIREBASE_DATABASE_EMULATOR_HOST);
  const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const key = keyPath && existsSync(keyPath) ? JSON.parse(readFileSync(keyPath, "utf8")) : null;
  const projectId = process.env.GCLOUD_PROJECT || key?.project_id;
  if (!projectId || (!key && !emulated)) {
    process.stderr.write(
      "Set GOOGLE_APPLICATION_CREDENTIALS to the service-account key (see the header of scripts/admin.ts).\n",
    );
    return 2;
  }
  loadEnvFile(join(FUNCTIONS_DIR, ".env"));
  loadEnvFile(join(FUNCTIONS_DIR, `.env.${projectId}`));

  const dbHost = process.env.FIREBASE_DATABASE_EMULATOR_HOST;
  const databaseURL = process.env.FIREBASE_DATABASE_URL
    ?? (dbHost ? `http://${dbHost}?ns=${projectId}-default-rtdb` : `https://${projectId}-default-rtdb.firebaseio.com`);
  const app = initializeApp({ projectId, databaseURL, ...(key && !emulated ? { credential: cert(key) } : {}) });
  process.stderr.write(`+Prayer admin · project ${projectId} · ${emulated ? "EMULATOR" : "production"}\n`);

  try {
    const result = await runAdminCommand(productionDeps(serverConfigFromEnv()), process.argv.slice(2), {
      async readJson(path) {
        return JSON.parse(path === "-" ? await readStdin() : readFileSync(resolve(process.cwd(), path), "utf8"));
      },
    });
    process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
    return 0;
  } catch (err) {
    process.stderr.write(`${JSON.stringify(errorJson(err), null, 2)}\n`);
    return 1;
  } finally {
    await deleteApp(app); // closes the RTDB connection so the process can exit
  }
}

main().then((code) => process.exit(code));
