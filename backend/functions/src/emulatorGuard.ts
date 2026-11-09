// The one gate every emulator-only data script passes before it touches
// anything (seed-emulator, the emulator sweeper). It refuses unless EVERY
// service the script writes is pointed at a local emulator and the project is
// a `demo-` project (which the Firebase emulators and SDKs never connect to
// production). Pure: it reads the environment and throws; the scripts call it
// before initializeApp(), so a refused run never opens a connection.

export class EmulatorGuardError extends Error {}

/** The emulator host variables the Admin SDK honours, one per service written. */
export const EMULATOR_HOST_VARS = [
  "DATA_CONNECT_EMULATOR_HOST",
  "FIREBASE_DATABASE_EMULATOR_HOST",
  "FIREBASE_AUTH_EMULATOR_HOST",
] as const;

const LOOPBACK = new Set(["localhost", "127.0.0.1", "::1", "[::1]", "0.0.0.0"]);

function hostOf(value: string): string | null {
  const v = value.trim();
  if (!v || v.includes("/")) return null; // host:port only, never a URL
  const bracketed = /^\[([^\]]+)\](?::\d+)?$/.exec(v);
  if (bracketed) return `[${bracketed[1]}]`;
  const m = /^([^:]+)(?::\d+)?$/.exec(v);
  return m ? m[1].toLowerCase() : null;
}

export interface EmulatorTarget {
  projectId: string;
  dataConnectHost: string;
  databaseHost: string;
  authHost: string;
  /** The RTDB URL to give initializeApp (the emulator's namespace). */
  databaseURL: string;
}

/**
 * Throws `EmulatorGuardError` (with every reason) unless the environment
 * points only at local emulators:
 * - DATA_CONNECT_EMULATOR_HOST, FIREBASE_DATABASE_EMULATOR_HOST and
 *   FIREBASE_AUTH_EMULATOR_HOST are all set to a loopback host:port;
 * - GCLOUD_PROJECT (or GOOGLE_CLOUD_PROJECT) starts with `demo-`;
 * - FIREBASE_DATABASE_URL, if set, is a loopback http URL;
 * - GOOGLE_APPLICATION_CREDENTIALS is not set (no service account is ever
 *   needed against the emulators).
 */
export function assertEmulatorTarget(env: NodeJS.ProcessEnv = process.env): EmulatorTarget {
  const problems: string[] = [];
  const hosts: Record<string, string> = {};
  for (const name of EMULATOR_HOST_VARS) {
    const value = env[name];
    if (!value) {
      problems.push(`${name} is not set`);
      continue;
    }
    const host = hostOf(value);
    if (!host || !LOOPBACK.has(host)) problems.push(`${name}=${value} is not a local emulator (host:port on localhost)`);
    else hosts[name] = value.trim();
  }
  const projectId = env.GCLOUD_PROJECT || env.GOOGLE_CLOUD_PROJECT || "";
  if (!projectId) problems.push("GCLOUD_PROJECT is not set (use demo-plusprayer)");
  else if (!projectId.startsWith("demo-")) problems.push(`GCLOUD_PROJECT=${projectId} is not a demo- project`);
  if (env.FIREBASE_DATABASE_URL) {
    try {
      const url = new URL(env.FIREBASE_DATABASE_URL);
      if (url.protocol !== "http:" || !LOOPBACK.has(url.hostname.toLowerCase())) {
        problems.push(`FIREBASE_DATABASE_URL=${env.FIREBASE_DATABASE_URL} is not a local emulator`);
      }
    } catch {
      problems.push(`FIREBASE_DATABASE_URL=${env.FIREBASE_DATABASE_URL} is not a URL`);
    }
  }
  if (env.GOOGLE_APPLICATION_CREDENTIALS) {
    problems.push("GOOGLE_APPLICATION_CREDENTIALS is set; emulator scripts never use credentials (unset it)");
  }
  if (problems.length) {
    throw new EmulatorGuardError(
      `Refusing to run: this script only writes to the local emulators.\n  - ${problems.join("\n  - ")}\n` +
        "Run it through `npm run seed:emulator` (backend/functions), which sets the emulator hosts.",
    );
  }
  const databaseHost = hosts.FIREBASE_DATABASE_EMULATOR_HOST;
  return {
    projectId,
    dataConnectHost: hosts.DATA_CONNECT_EMULATOR_HOST,
    databaseHost,
    authHost: hosts.FIREBASE_AUTH_EMULATOR_HOST,
    databaseURL: env.FIREBASE_DATABASE_URL || `http://${databaseHost}?ns=${projectId}-default-rtdb`,
  };
}
