// RTDB /config, read by the server for the values it enforces (grace cap and
// interval) — one source for app display and server rules. Cached briefly.

import { ClientConfig, resolveClientConfig } from "./config";
import { Live } from "./deps";

const TTL_MS = 60_000;
let cache: { at: number; value: ClientConfig } | null = null;

export async function getClientConfig(live: Live, now = Date.now()): Promise<ClientConfig> {
  if (cache && now - cache.at < TTL_MS) return cache.value;
  let stored: Partial<ClientConfig> | null = null;
  try {
    stored = await live.readClientConfig();
  } catch {
    // RTDB unavailable: fall back to the compiled defaults.
  }
  cache = { at: now, value: resolveClientConfig(stored) };
  return cache.value;
}

/** Tests: drop the cache between cases. */
export function resetClientConfigCache(): void {
  cache = null;
}
