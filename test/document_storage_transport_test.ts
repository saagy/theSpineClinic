import assert from "node:assert/strict";

// Synthetic configuration only. Network access stays disabled for this suite.
Deno.env.set("R2_BUCKET_NAME", "test-bucket");
Deno.env.set("R2_ACCOUNT_ID", "test-account");
Deno.env.set("R2_ACCESS_KEY_ID", "test-access");
Deno.env.set("R2_SECRET_ACCESS_KEY", "test-secret");
const storage = await import("../supabase/functions/document-storage/storage.ts");

Deno.test("R2 HEAD uses native fetch and handles absent, present and denied objects", async () => {
  const originalFetch = globalThis.fetch;
  let status = 404;
  const methods: string[] = [];
  globalThis.fetch = (input) => {
    const request = input as Request;
    methods.push(request.method);
    assert.equal(new URL(request.url).hostname, "test-bucket.test-account.r2.cloudflarestorage.com");
    return Promise.resolve(new Response(null, {
      status, headers: status === 200 ? { "content-length": "1234" } : {},
    }));
  };
  try {
    assert.equal(await storage.size("patient/missing"), null);
    status = 200;
    assert.equal(await storage.size("patient/present"), 1234);
    status = 403;
    await assert.rejects(storage.size("patient/denied"));
    assert.deepEqual(methods, ["HEAD", "HEAD", "HEAD"]);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("R2 listing and cleanup share the native fetch transport", async () => {
  const originalFetch = globalThis.fetch;
  const methods: string[] = [];
  globalThis.fetch = (input) => {
    const request = input as Request;
    methods.push(request.method);
    const body = request.method === "GET"
      ? "<ListBucketResult><IsTruncated>false</IsTruncated><Contents><Key>patient/file</Key></Contents></ListBucketResult>"
      : "<DeleteResult/>";
    return Promise.resolve(new Response(body, { headers: { "content-type": "application/xml" } }));
  };
  try {
    assert.equal(await storage.removeFolder("patient"), 1);
    assert.deepEqual(methods, ["GET", "POST"]);
    const signed = new URL(await storage.upload("patient/file", "image/jpeg"));
    assert.equal(signed.searchParams.get("X-Amz-Expires"), "300");
    assert.deepEqual(methods, ["GET", "POST"]);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
