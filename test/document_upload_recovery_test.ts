import assert from 'node:assert/strict';
import { test } from 'node:test';
import { trackedUpload, type UploadServices } from '../supabase/functions/document-storage/uploads.ts';

function setup() {
  let status = 'pending';
  let storedSize: number | null = null;
  let loseFinalizeReply = false;
  let failInsert = false;
  let signed = 0, inserts = 0, deletes = 0;
  const document = { id: 'document' };
  let outcome: object | null = null;
  const services: UploadServices = {
    rpc: async (name) => {
      if (name === 'begin_document_upload') return { status, object_key: 'patient/file', byte_size: 100, outcome };
      if (status === 'pending') {
        if (failInsert) { status = 'failed'; outcome = { ok: false }; }
        else { status = 'completed'; outcome = { ok: true, document }; inserts++; }
      }
      if (loseFinalizeReply) { loseFinalizeReply = false; throw new Error('response lost'); }
      return outcome;
    },
    size: async () => storedSize,
    upload: async () => { signed++; return 'https://example.test/put'; },
    remove: async () => { deletes++; storedSize = null; },
  };
  return {
    run: (action = 'start-upload') => trackedUpload({ action, requestId: 'request' }, 'image/png', services),
    put: (size = 100) => { storedSize = size; },
    loseReply: () => { loseFinalizeReply = true; },
    rejectInsert: () => { failInsert = true; },
    stats: () => ({ signed, inserts, deletes }),
  };
}
test('lost PUT reply is recovered without uploading another object', async () => {
  const env = setup(); await env.run(); env.put();
  assert.deepEqual(await env.run(), { ok: true, document: { id: 'document' }, objectKey: 'patient/file' });
  assert.deepEqual(env.stats(), { signed: 1, inserts: 1, deletes: 0 });
});
test('lost database reply never deletes a committed file', async () => {
  const env = setup(); await env.run(); env.put(); env.loseReply();
  await assert.rejects(env.run('finish-upload'));
  assert.equal(env.stats().deletes, 0);
  assert.equal((await env.run() as { ok: boolean }).ok, true);
  assert.deepEqual(env.stats(), { signed: 1, inserts: 1, deletes: 0 });
});
test('definite insert failure compensates only after the failed receipt', async () => {
  const env = setup(); await env.run(); env.put(); env.rejectInsert();
  assert.equal((await env.run('finish-upload') as { ok: boolean }).ok, false);
  await env.run();
  assert.deepEqual(env.stats(), { signed: 1, inserts: 0, deletes: 2 });
});
test('missing and incomplete objects cannot finalize metadata', async () => {
  const env = setup();
  await assert.rejects(env.run('finish-upload'));
  env.put(50);
  await assert.rejects(env.run());
  assert.deepEqual(env.stats(), { signed: 0, inserts: 0, deletes: 0 });
});
