// Contact info and links are blocked at input (schema-brief §11) — both sides:
// what must be blocked, and what must pass (verses, rooms, dates, "St.").

import assert from "node:assert/strict";
import { beforeEach, describe, it } from "node:test";
import { HttpsError } from "firebase-functions/v2/https";
import { CONTACT_MESSAGE, hasContactInfo } from "../src/contact";
import { addSubject, setSelfName, updateSubject } from "../src/subjects";
import { addSubjectRow, createUser, makeDeps, resetDb } from "./helpers";

const BLOCKED = [
  "Call 555-123-4567",
  "555 1234",
  "(555) 123-4567",
  "555.123.4567",
  "+44 20 7946 0958",
  "Text me 5551234567",
  "Ana 0917 123 4567",
  "jane@example.com",
  "Write to jane.doe@mail.co.uk",
  "www.example.com",
  "example.com",
  "visit example.org/pray",
  "https://x.org/a",
  "See PrayForAna.net",
];

const ALLOWED = [
  "John 3:16",
  "Psalm 23",
  "Isaiah 41:10-13",
  "Romans 8:28-39",
  "Mark 10:45 and Psalm 91",
  "Room 412",
  "Rm 1203, Bed 4",
  "Ward 7B",
  "Apt 12, Unit 5",
  "Flight 1234",
  "10/18/2026",
  "2026-10-18",
  "18.10.26",
  "Oct 18, 2026",
  "Jan 3 2026 surgery at 9",
  "Gary Olson 1945-2023",
  "Gary Olson (1945–2023)",
  "St. Jude",
  "St. Mary's Hospital",
  "Dr. Kim",
  "e.g. healing",
  "Mom (age 84)",
];

describe("contact detection", () => {
  for (const text of BLOCKED) it(`blocks: ${text}`, () => assert.equal(hasContactInfo(text), true));
  for (const text of ALLOWED) it(`allows: ${text}`, () => assert.equal(hasContactInfo(text), false));
});

function isContactError(field: string) {
  return (err: HttpsError) => {
    assert.equal(err.code, "invalid-argument");
    assert.equal(err.message, CONTACT_MESSAGE);
    assert.deepEqual(err.details, { reason: "CONTACT_OR_LINK", field });
    return true;
  };
}

describe("blocked at input with an inline-ready error", () => {
  beforeEach(resetDb);

  it("addSubject: names and intentions (aliases are never printed, so they aren't checked)", async () => {
    const deps = makeDeps();
    const { selfId } = await createUser("c1", { includeLimit: 10, expiresInMs: 86_400_000 });
    await assert.rejects(addSubject(deps, "c1", { kind: "SOUL", publicName: "Ana 555-123-4567" }), isContactError("publicName"));
    await addSubject(deps, "c1", { kind: "SOUL", publicName: "Ana", personalLabel: "Ana 555-123-4567" });
    await assert.rejects(
      addSubject(deps, "c1", { kind: "INTENTION", parentId: selfId, publicName: "Donate at example.org" }),
      isContactError("publicName"),
    );
    // The other side: these save.
    await addSubject(deps, "c1", { kind: "INTENTION", parentId: selfId, publicName: "Strength — Isaiah 41:10" });
    await addSubject(deps, "c1", { kind: "SOUL", publicName: "Gary Olson 1945-2023", personalLabel: "Dad" });
    await addSubject(deps, "c1", { kind: "SOUL", publicName: "St. Jude Room 412" });
  });

  it("updateSubject: name blocked, alias free", async () => {
    const deps = makeDeps();
    await createUser("c2");
    const id = await addSubjectRow("c2", { name: "Bea" });
    await assert.rejects(updateSubject(deps, "c2", { id, publicName: "Bea www.bea.com" }), isContactError("publicName"));
    await updateSubject(deps, "c2", { id, personalLabel: "Bea +1 555 123 4567" });
    await updateSubject(deps, "c2", { id, personalLabel: "Aunt Bea (Psalm 23)" });
  });

  it("setSelfName", async () => {
    const deps = makeDeps();
    await createUser("c3", { self: false });
    await assert.rejects(setSelfName(deps, "c3", "Tom tom@example.com"), isContactError("name"));
    await setSelfName(deps, "c3", "Tom (John 3:16)");
  });
});
