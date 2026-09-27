export type UploadServices = {
  rpc: (name: string, params: Record<string, unknown>) => Promise<unknown>;
  size: (key: string) => Promise<number | null>;
  upload: (key: string, contentType: string) => Promise<string>;
  remove: (keys: string[]) => Promise<void>;
};

// A lost PUT/finalize response is reconciled with R2 and the durable DB receipt.
export async function trackedUpload(
  body: Record<string, unknown>, contentType: string, services: UploadServices,
): Promise<object> {
  const receipt = await services.rpc('begin_document_upload', {
    p_request_id: body.requestId, p_patient_id: body.patientId,
    p_file_name: body.fileName, p_program_id: body.programId ?? null,
    p_content_hash: body.contentHash, p_byte_size: body.byteSize,
  }) as { status: string; object_key: string; byte_size: number; outcome: { ok: boolean } };
  const objectKey = receipt.object_key;
  let outcome = receipt.outcome;
  if (receipt.status === 'pending') {
    const size = await services.size(objectKey);
    if (size === null) {
      if (body.action === 'finish-upload') throw new Error('Upload not yet visible');
      return { uploadUrl: await services.upload(objectKey, contentType), objectKey, contentType };
    }
    if (size !== receipt.byte_size) throw new Error('Upload size mismatch');
    // Never compensate an ambiguous failure: this call may already have committed.
    outcome = await services.rpc('complete_document_upload', {
      p_request_id: body.requestId,
    }) as { ok: boolean };
  }
  if (!outcome.ok) {
    // The failed receipt prevents every subsequent finalize before object deletion.
    try { await services.remove([objectKey]); } catch { /* retained for retry */ }
  }
  return { ...outcome, objectKey };
}
