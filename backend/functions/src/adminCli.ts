// The admin CLI's commands (scripts/admin.ts is the entry point). Each one
// runs the same module the deployed admin callable runs and returns plain
// JSON, so Eric's skills can shell out and parse the result:
//
//   npm --prefix backend/functions run admin -- <command> [options]
//
// Kept separate from the entry point so tests can run every command against
// the emulator with test Deps.

import { parseArgs } from "node:util";
import { HttpsError } from "firebase-functions/v2/https";
import * as accounts from "./accounts";
import { backfillLists, planBackfill } from "./backfill";
import { CLIENT_CONFIG_DEFAULTS } from "./config";
import { Deps } from "./deps";
import * as lists from "./lists";
import { seedBlocklist } from "./moderation";

export const USAGE = `Usage: npm run admin -- <command> [options]   (prints JSON)

Morning flow
  status                                   open lists and the current one
  close-list [--minutes 5]                 set the cutoff; creates N+1
  assemble [--social FILE] [--force]       settle N, fill N+1; returns the review diff
  review [--list ID]                       names / intentions new or changed since the last list
  moderate --decisions FILE [--list ID]    apply the first pass: [{ entryId, decision, reasonCategory?, note? }]
  held [--list ID]                         what's left for Eric (HELD)
  exclude --entry ID --category C [--note TEXT]
  approve --entry ID [--note TEXT]
  print [--list ID]                        everything that prints, grouped by portion
  publish [--list ID]                      draft → published, seal from the weekday
  publish-video --video videos/… [--posts FILE] [--list ID]

Accounts and setup
  set-entitlement --uid UID --tier TIER --limit N [--expires ISO|none]
  seed-config                              seed RTDB /config and /moderation/blocklist (missing keys only)
  backfill [--only N] [--dry-run] [--lists FILE] [--participants FILE]
                                           lists 1..N from publishing/*.json; lists already in the DB are skipped

FILE is a JSON file, or - for stdin. --list defaults to the current list.`;

export interface CliIO {
  /** Read a JSON input (a path, or "-" for stdin). */
  readJson(path: string): Promise<unknown>;
}

function usage(message: string): never {
  throw new HttpsError("invalid-argument", `${message}\n\n${USAGE}`);
}

async function currentListId(deps: Deps, given: string | undefined): Promise<string> {
  if (given) return given;
  const { current } = await lists.listStatus(deps);
  if (!current) throw new HttpsError("failed-precondition", "There is no current list");
  return current.id;
}

export async function runAdminCommand(deps: Deps, argv: string[], io: CliIO): Promise<unknown> {
  const [command, ...rest] = argv;
  const { values: o } = parseArgs({
    args: rest,
    strict: true,
    options: {
      list: { type: "string" },
      minutes: { type: "string" },
      social: { type: "string" },
      force: { type: "boolean" },
      decisions: { type: "string" },
      entry: { type: "string" },
      category: { type: "string" },
      note: { type: "string" },
      video: { type: "string" },
      posts: { type: "string" },
      uid: { type: "string" },
      tier: { type: "string" },
      limit: { type: "string" },
      expires: { type: "string" },
      only: { type: "string" },
      "dry-run": { type: "boolean" },
      lists: { type: "string" },
      participants: { type: "string" },
    },
  });
  const need = (name: keyof typeof o) => {
    const v = o[name];
    if (typeof v !== "string" || !v) usage(`${command}: --${name} is required`);
    return v;
  };

  switch (command) {
    case "status":
      return lists.listStatus(deps);

    case "close-list": {
      const minutes = o.minutes === undefined ? undefined : Number(o.minutes);
      if (minutes !== undefined && !(Number.isFinite(minutes) && minutes >= 0)) usage("--minutes must be a number ≥ 0");
      return lists.closeList(deps, minutes);
    }

    case "assemble":
      return lists.assembleNextList(deps, {
        social: o.social ? await io.readJson(o.social) : [],
        force: o.force === true,
      });

    case "review":
      return lists.getReviewDiff(deps, await currentListId(deps, o.list));

    case "moderate": {
      const decisions = await io.readJson(need("decisions")); // arguments before any lookup
      return lists.moderateEntries(deps, { listId: await currentListId(deps, o.list), decisions });
    }

    case "held":
      return lists.getHeldEntries(deps, await currentListId(deps, o.list));

    case "exclude":
      return lists.moderateEntry(deps, {
        entryId: need("entry"),
        status: "EXCLUDED",
        reasonCategory: need("category"),
        heldReason: o.note ?? null,
      });

    case "approve":
      return lists.moderateEntry(deps, { entryId: need("entry"), status: "APPROVED", heldReason: o.note ?? null });

    case "print":
      return lists.getListForPrint(deps, await currentListId(deps, o.list));

    case "publish":
      return lists.publishList(deps, await currentListId(deps, o.list));

    case "publish-video": {
      const videoPath = need("video");
      const posts = o.posts ? await io.readJson(o.posts) : [];
      return lists.publishListVideo(deps, { listId: await currentListId(deps, o.list), videoPath, posts });
    }

    case "set-entitlement": {
      const limit = Number(need("limit"));
      const expires = o.expires === undefined || o.expires === "none" ? null : o.expires;
      return accounts.setEntitlement(deps, {
        uid: need("uid"),
        planTier: need("tier"),
        includeLimit: limit,
        entitlementExpiresAt: expires,
      });
    }

    case "seed-config": {
      const addedConfigKeys = await deps.live.writeClientConfigDefaults(CLIENT_CONFIG_DEFAULTS);
      const terms = seedBlocklist();
      const blocklistSeeded = await deps.live.writeBlocklistIfMissing(terms);
      return { addedConfigKeys, blocklistSeeded, blocklistTerms: blocklistSeeded ? terms.length : undefined };
    }

    case "backfill": {
      const only = o.only === undefined ? undefined : Number(o.only);
      if (only !== undefined && !(Number.isInteger(only) && only >= 1)) usage("--only must be a list number");
      // npm --prefix runs the CLI from backend/functions.
      const plans = planBackfill(
        await io.readJson(o.lists ?? "../../publishing/lists.json"),
        await io.readJson(o.participants ?? "../../publishing/participants.json"),
        deps.cfg.nameCap,
      );
      return backfillLists(deps, plans, { only, dryRun: o["dry-run"] === true });
    }

    case undefined:
    case "help":
      return { usage: USAGE };

    default:
      usage(`unknown command "${command}"`);
  }
}

/** How a failure is printed for a skill to read. */
export function errorJson(err: unknown) {
  if (err instanceof HttpsError) return { error: { code: err.code, message: err.message, details: err.details ?? null } };
  if (err instanceof Error && (err as { code?: string }).code === "ERR_PARSE_ARGS_UNKNOWN_OPTION") {
    return { error: { code: "invalid-argument", message: `${err.message}\n\n${USAGE}`, details: null } };
  }
  return { error: { code: "internal", message: err instanceof Error ? err.message : String(err), details: null } };
}
