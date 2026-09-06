import assert from "node:assert/strict";
import { test } from "node:test";
import { handleStorageRequest, type StorageServices } from "../supabase/functions/document-storage/handler.ts";

const allowed = "00000000-0000-0000-0000-000000000001";
const denied = "00000000-0000-0000-0000-000000000002";
function setup(overrides: Partial<StorageServices> = {}) {
  const signed: string[] = [];
  const deleted: string[][] = [];
  const services: StorageServices = {
    canAccess: async (id) => id === allowed,
    patientExists: async () => true,
    upload: async (key) => { signed.push(key); return "https://example.test/upload"; },
    download: async (key) => { signed.push(key); return "https://example.test/download"; },
    remove: async (keys) => { deleted.push(keys); },
    removeFolder: async (id) => { deleted.push([id]); return 1; },
    ...overrides,
  };
  const request = (body: unknown, authorization = "Bearer test") =>
    handleStorageRequest(new Request("https://example.test", {
      method: "POST", headers: authorization ? { Authorization: authorization } : {},
      body: JSON.stringify(body),
    }), services);
  return { request, signed, deleted };
}
test("cannot sign another patient's file using an authorized patient ID", async () => {
  const { request, signed } = setup();
  assert.equal((await request({ action: "get-download-url", patientId: allowed, objectKey: `${denied}/scan.pdf` })).status, 403);
  assert.deepEqual(signed, []);
});
test("object key determines access with or without an explicit patient ID", async () => {
  const { request, signed } = setup();
  assert.equal((await request({ action: "get-download-url", objectKey: `${denied}/scan.pdf` })).status, 403);
  assert.equal((await request({ action: "get-download-url", objectKey: `${allowed}/scan.pdf` })).status, 200);
  assert.deepEqual(signed, [`${allowed}/scan.pdf`]);
});
test("mixed-patient deletion fails before deleting any object", async () => {
  const { request, deleted } = setup();
  assert.equal((await request({ action: "delete-objects", objectKeys: [`${allowed}/a.pdf`, `${denied}/b.pdf`] })).status, 403);
  assert.deepEqual(deleted, []);
});
test("folder cleanup requires prior database deletion", async () => {
  const { request, deleted } = setup();
  assert.equal((await request({ action: "delete-patient-folder", patientId: allowed })).status, 409);
  assert.deepEqual(deleted, []);
  const cleanup = setup({ patientExists: async () => false });
  assert.equal((await cleanup.request({ action: "delete-patient-folder", patientId: allowed })).status, 200);
  assert.deepEqual(cleanup.deleted, [[allowed]]);
});
test("malformed keys and bodies are rejected", async () => {
  const { request, signed, deleted } = setup();
  for (const objectKey of [null, 12, {}, "", `${allowed}/../scan.pdf`, `${allowed}/`, `${allowed}\\scan.pdf`]) {
    assert.equal((await request({ action: "get-download-url", objectKey })).status, 400);
  }
  for (const body of [null, [], 1, "text"]) assert.equal((await request(body)).status, 400);
  assert.equal((await request({ action: "delete-objects", objectKeys: [12] })).status, 400);
  assert.deepEqual(signed, []);
  assert.deepEqual(deleted, []);
});
test("uploads require existing accessible patients and use unique keys", async () => {
  const { request, signed } = setup();
  const body = { action: "get-upload-url", patientId: allowed, fileName: "scan.pdf" };
  assert.equal((await request(body)).status, 200);
  assert.equal((await request(body)).status, 200);
  assert.notEqual(signed[0], signed[1]);
  assert.equal((await request({ ...body, patientId: denied })).status, 403);
  assert.equal((await request({ ...body, fileName: "script.html" })).status, 400);
  assert.equal((await setup({ patientExists: async () => false }).request(body)).status, 404);
});
test("missing authentication and storage failures cannot report success", async () => {
  const { request } = setup({ remove: async () => { throw new Error("private server details"); } });
  assert.equal((await request({}, "")).status, 401);
  const response = await request({ action: "delete-objects", objectKeys: [`${allowed}/a.pdf`] });
  assert.equal(response.status, 500);
  assert.equal((await response.text()).includes("private server details"), false);
});
