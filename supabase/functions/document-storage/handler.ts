export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export type StorageServices = {
  canAccess: (patientId: string) => Promise<boolean>;
  patientExists: (patientId: string) => Promise<boolean>;
  upload: (key: string, contentType: string) => Promise<string>;
  download: (key: string) => Promise<string>;
  remove: (keys: string[]) => Promise<void>;
  removeFolder: (patientId: string) => Promise<number>;
};

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const contentTypes: Record<string, string> = {
  pdf: "application/pdf", jpg: "image/jpeg", jpeg: "image/jpeg",
  png: "image/png", webp: "image/webp", txt: "text/plain",
};
const json = (body: object, status = 200) => Response.json(body, { status, headers: corsHeaders });

function patientFromKey(key: unknown): string | null {
  if (typeof key !== "string" || key.length > 1024) return null;
  const parts = key.split("/");
  if (parts.length < 2 || !uuid.test(parts[0])) return null;
  if (parts.some((part) => !part || part === "." || part === "..")) return null;
  if (/[\x00-\x1f\x7f\\]/.test(key)) return null;
  return parts[0];
}

export async function handleStorageRequest(req: Request, services: StorageServices): Promise<Response> {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!req.headers.get("Authorization")) return json({ error: "Missing Authorization header" }, 401);
  let body: Record<string, unknown>;
  try {
    const parsed: unknown = await req.json();
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      return json({ error: "Expected an object" }, 400);
    }
    body = parsed as Record<string, unknown>;
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }
  try {
    if (body.action === "get-upload-url") {
      const { patientId, fileName } = body;
      if (typeof patientId !== "string" || !uuid.test(patientId) ||
          typeof fileName !== "string" || !fileName.trim() || fileName.length > 255) {
        return json({ error: "Invalid patientId or fileName" }, 400);
      }
      if (!await services.canAccess(patientId)) return json({ error: "Forbidden" }, 403);
      if (!await services.patientExists(patientId)) return json({ error: "Patient not found" }, 404);
      const contentType = contentTypes[fileName.split(".").pop()?.toLowerCase() ?? ""];
      if (!contentType) return json({ error: "Unsupported file type" }, 400);
      const name = fileName.replace(/[^a-zA-Z0-9._-]/g, "_");
      const objectKey = `${patientId}/${crypto.randomUUID()}_${name}`;
      return json({ uploadUrl: await services.upload(objectKey, contentType), objectKey, contentType });
    }
    if (body.action === "get-download-url") {
      const patientId = patientFromKey(body.objectKey);
      if (!patientId) return json({ error: "Invalid objectKey" }, 400);
      // Authorize the actual object's patient, never a separate supplied ID.
      if (body.patientId !== undefined && body.patientId !== patientId) {
        return json({ error: "Patient and object key do not match" }, 403);
      }
      if (!await services.canAccess(patientId)) return json({ error: "Forbidden" }, 403);
      const objectKey = body.objectKey as string;
      return json({ downloadUrl: await services.download(objectKey), objectKey });
    }
    if (body.action === "delete-objects") {
      if (!Array.isArray(body.objectKeys) || body.objectKeys.length > 1000) {
        return json({ error: "Expected at most 1000 object keys" }, 400);
      }
      const patientIds = body.objectKeys.map(patientFromKey);
      if (patientIds.some((id) => id === null)) return json({ error: "Invalid object key" }, 400);
      for (const patientId of new Set(patientIds)) {
        if (!await services.canAccess(patientId!)) return json({ error: "Forbidden" }, 403);
      }
      const keys = [...new Set(body.objectKeys as string[])];
      if (keys.length) await services.remove(keys);
      return json({ success: true, deleted: keys.length });
    }
    if (body.action === "delete-patient-folder") {
      const { patientId } = body;
      if (typeof patientId !== "string" || !uuid.test(patientId)) return json({ error: "Invalid patientId" }, 400);
      if (!await services.canAccess(patientId)) return json({ error: "Forbidden" }, 403);
      // Prevent deleting files that still have live patient records.
      if (await services.patientExists(patientId)) return json({ error: "Delete the patient record before storage cleanup" }, 409);
      return json({ success: true, totalDeleted: await services.removeFolder(patientId) });
    }
    return json({ error: "Unknown action" }, 400);
  } catch {
    return json({ error: "Storage operation failed" }, 500);
  }
}
