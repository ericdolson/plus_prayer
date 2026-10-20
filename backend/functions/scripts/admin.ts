// Admin CLI for Eric's skills — the admin callables, run locally with a
// service account. Commands and output: src/adminCli.ts (`npm run admin -- help`).
//
// Credentials, first match wins:
//   1. GOOGLE_APPLICATION_CREDENTIALS pointing at a service-account key (for a
//      machine that isn't signed in as Eric). Keep the file OUTSIDE the repo.
//   2. Eric's gcloud login (Application Default Credentials). Set up once with
//      `gcloud auth application-default login` and
//      `gcloud auth application-default set-quota-project plusprayer`; the
//      project comes from that quota project.
//   GCLOUD_PROJECT overrides the project. Optional: FIREBASE_DATABASE_URL
//   (default https://<project>-default-rtdb.firebaseio.com)
//
// Config is read like the deployed functions': backend/functions/.env and
// .env.<projectId> (written by `firebase deploy` when it asks for the params),
// then the environment. Against emulators: set DATA_CONNECT_EMULATOR_HOST /
// FIREBASE_DATABASE_EMULATOR_HOST and GCLOUD_PROJECT instead of a key.

import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { applicationDefault, cert, Credential, deleteApp, initializeApp } from "firebase-admin/app";
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

function readJsonFile(path: string | undefined): Record<string, string> | null {
  return path && existsSync(path) ? JSON.parse(readFileSync(path, "utf8")) : null;
}

/** A service-account key, else the gcloud login (Application Default Credentials). */
function resolveCredentials(): { credential: Credential; projectId?: string; source: string } | null {
  const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const file = readJsonFile(keyPath);
  if (file?.type === "service_account") {
    return { credential: cert(file), projectId: file.project_id, source: `service account ${file.client_email}` };
  }
  // GOOGLE_APPLICATION_CREDENTIALS can also hold a gcloud login; otherwise gcloud's default spot.
  const gcloudDir = process.env.CLOUDSDK_CONFIG ?? join(homedir(), ".config", "gcloud");
  const adc = file ?? readJsonFile(join(gcloudDir, "application_default_credentials.json"));
  if (adc?.type !== "authorized_user") return null;
  return { credential: applicationDefault(), projectId: adc.quota_project_id, source: "gcloud login" };
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
  const creds = emulated ? null : resolveCredentials();
  const projectId = process.env.GCLOUD_PROJECT || creds?.projectId;
  if (!projectId || (!creds && !emulated)) {
    process.stderr.write(
      "No credentials. Run `gcloud auth application-default login` and " +
        "`gcloud auth application-default set-quota-project plusprayer`, or set " +
        "GOOGLE_APPLICATION_CREDENTIALS to a service-account key (see the header of scripts/admin.ts).\n",
    );
    return 2;
  }
  loadEnvFile(join(FUNCTIONS_DIR, ".env"));
  loadEnvFile(join(FUNCTIONS_DIR, `.env.${projectId}`));

  const dbHost = process.env.FIREBASE_DATABASE_EMULATOR_HOST;
  const databaseURL = process.env.FIREBASE_DATABASE_URL
    ?? (dbHost ? `http://${dbHost}?ns=${projectId}-default-rtdb` : `https://${projectId}-default-rtdb.firebaseio.com`);
  const app = initializeApp({ projectId, databaseURL, ...(creds ? { credential: creds.credential } : {}) });
  process.stderr.write(`+Prayer admin · project ${projectId} · ${emulated ? "EMULATOR" : `production (${creds!.source})`}\n`);

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
