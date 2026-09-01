import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectsCommand,
  ListObjectsV2Command,
} from "npm:@aws-sdk/client-s3@^3.600.0";
import { getSignedUrl } from "npm:@aws-sdk/s3-request-presigner@^3.600.0";
import { createClient } from "npm:@supabase/supabase-js@^2.45.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Global singleton client to avoid re-instantiation overhead on every request
const accountId = (Deno.env.get("R2_ACCOUNT_ID") ?? "").trim();
const accessKeyId = (Deno.env.get("R2_ACCESS_KEY_ID") ?? "").trim();
const secretAccessKey = (Deno.env.get("R2_SECRET_ACCESS_KEY") ?? "").trim();
const bucketName = (Deno.env.get("R2_BUCKET_NAME") ?? "").trim();

const s3Client = new S3Client({
  region: "auto",
  endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId,
    secretAccessKey,
  },
});

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

function inferContentType(fileName: string): string {
  const ext = fileName.split(".").pop()?.toLowerCase();
  switch (ext) {
    case "pdf":
      return "application/pdf";
    case "jpg":
    case "jpeg":
      return "image/jpeg";
    case "png":
      return "image/png";
    case "webp":
      return "image/webp";
    case "svg":
      return "image/svg+xml";
    case "txt":
      return "text/plain";
    default:
      return "application/octet-stream";
  }
}

function sanitizeFileName(fileName: string): string {
  return fileName.replace(/[^a-zA-Z0-9._-]/g, "_");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!accountId || !accessKeyId || !secretAccessKey || !bucketName) {
      return new Response(
        JSON.stringify({ error: "R2 storage configuration missing on server" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });

    const body = await req.json().catch(() => ({}));
    const { action, patientId, fileName, contentType, objectKey, objectKeys } = body;

    const checkPatientAccess = async (targetPatientId: string): Promise<boolean> => {
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidRegex.test(targetPatientId)) return false;

      const { data, error } = await supabase.rpc("can_current_staff_access_patient", {
        p_patient_id: targetPatientId,
      });
      return !error && data === true;
    };

    switch (action) {
      case "get-upload-url": {
        if (!patientId || !fileName) {
          return new Response(
            JSON.stringify({ error: "Missing patientId or fileName" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const hasAccess = await checkPatientAccess(patientId);
        if (!hasAccess) {
          return new Response(
            JSON.stringify({ error: "Forbidden: No permission to access patient" }),
            { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const sanitized = sanitizeFileName(fileName);
        const stamp = Date.now().toString();
        const generatedKey = `${patientId}/${stamp}_${sanitized}`;
        const mimeType = contentType || inferContentType(fileName);

        const command = new PutObjectCommand({
          Bucket: bucketName,
          Key: generatedKey,
          ContentType: mimeType,
        });

        const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn: 300 });

        return new Response(
          JSON.stringify({
            uploadUrl,
            objectKey: generatedKey,
            contentType: mimeType,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "get-download-url": {
        let targetPatientId = patientId;
        const targetKey = objectKey;

        if (!targetKey) {
          return new Response(
            JSON.stringify({ error: "Missing objectKey" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        if (!targetPatientId) {
          targetPatientId = targetKey.split("/")[0];
        }

        const hasAccess = await checkPatientAccess(targetPatientId);
        if (!hasAccess) {
          return new Response(
            JSON.stringify({ error: "Forbidden: No permission to access patient" }),
            { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const command = new GetObjectCommand({
          Bucket: bucketName,
          Key: targetKey,
        });

        const downloadUrl = await getSignedUrl(s3Client, command, { expiresIn: 900 });

        return new Response(
          JSON.stringify({ downloadUrl, objectKey: targetKey }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "delete-objects": {
        const keys: string[] = Array.isArray(objectKeys) ? objectKeys : [];
        if (keys.length === 0) {
          return new Response(
            JSON.stringify({ success: true, deleted: 0 }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const patientIds = Array.from(new Set(keys.map((k) => k.split("/")[0])));
        for (const pid of patientIds) {
          const hasAccess = await checkPatientAccess(pid);
          if (!hasAccess) {
            return new Response(
              JSON.stringify({ error: `Forbidden: No permission for patient ${pid}` }),
              { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
          }
        }

        const deleteCommand = new DeleteObjectsCommand({
          Bucket: bucketName,
          Delete: {
            Objects: keys.map((k) => ({ Key: k })),
            Quiet: true,
          },
        });

        await s3Client.send(deleteCommand);

        return new Response(
          JSON.stringify({ success: true, deleted: keys.length }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "delete-patient-folder": {
        if (!patientId) {
          return new Response(
            JSON.stringify({ error: "Missing patientId" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const hasAccess = await checkPatientAccess(patientId);
        if (!hasAccess) {
          return new Response(
            JSON.stringify({ error: "Forbidden: No permission to access patient" }),
            { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        let continuationToken: string | undefined = undefined;
        let totalDeleted = 0;

        do {
          const listCommand = new ListObjectsV2Command({
            Bucket: bucketName,
            Prefix: `${patientId}/`,
            ContinuationToken: continuationToken,
          });

          const listRes = await s3Client.send(listCommand);
          if (listRes.Contents && listRes.Contents.length > 0) {
            const toDelete = listRes.Contents.filter((c) => c.Key).map((c) => ({
              Key: c.Key!,
            }));

            if (toDelete.length > 0) {
              await s3Client.send(
                new DeleteObjectsCommand({
                  Bucket: bucketName,
                  Delete: { Objects: toDelete, Quiet: true },
                })
              );
              totalDeleted += toDelete.length;
            }
          }
          continuationToken = listRes.NextContinuationToken;
        } while (continuationToken);

        return new Response(
          JSON.stringify({ success: true, totalDeleted }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      default:
        return new Response(
          JSON.stringify({ error: `Unknown action: ${action}` }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
  } catch (error) {
    const err = error as Error;
    return new Response(
      JSON.stringify({ error: err.message ?? "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
