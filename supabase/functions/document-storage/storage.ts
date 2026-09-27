import {
  S3Client, HeadObjectCommand, PutObjectCommand, GetObjectCommand, DeleteObjectsCommand, ListObjectsV2Command,
} from "npm:@aws-sdk/client-s3@^3.600.0";
import { getSignedUrl } from "npm:@aws-sdk/s3-request-presigner@^3.600.0";
import { FetchHttpHandler } from "npm:@smithy/fetch-http-handler@5.8.0";

const bucket = (Deno.env.get("R2_BUCKET_NAME") ?? "").trim();
const client = new S3Client({
  // Avoid Deno's Node HTTP stream adapter, which can crash on R2 HEAD replies.
  requestHandler: new FetchHttpHandler(),
  region: "auto",
  endpoint: `https://${(Deno.env.get("R2_ACCOUNT_ID") ?? "").trim()}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: (Deno.env.get("R2_ACCESS_KEY_ID") ?? "").trim(),
    secretAccessKey: (Deno.env.get("R2_SECRET_ACCESS_KEY") ?? "").trim(),
  },
});
export async function upload(key: string, contentType: string): Promise<string> {
  return await getSignedUrl(client, new PutObjectCommand({
    Bucket: bucket, Key: key, ContentType: contentType,
  }), { expiresIn: 300 });
}
export async function download(key: string): Promise<string> {
  return await getSignedUrl(client, new GetObjectCommand({ Bucket: bucket, Key: key }), { expiresIn: 900 });
}
export async function remove(keys: string[]): Promise<void> {
  const result = await client.send(new DeleteObjectsCommand({
    Bucket: bucket, Delete: { Objects: keys.map((Key) => ({ Key })), Quiet: true },
  }));
  if (result.Errors?.length) throw new Error("Storage deletion was incomplete");
}
export async function removeFolder(patientId: string): Promise<number> {
  let continuationToken: string | undefined;
  let totalDeleted = 0;
  do {
    const page = await client.send(new ListObjectsV2Command({
      Bucket: bucket, Prefix: `${patientId}/`, ContinuationToken: continuationToken,
    }));
    const keys = (page.Contents ?? []).flatMap((item) => item.Key ? [item.Key] : []);
    if (keys.length) { await remove(keys); totalDeleted += keys.length; }
    continuationToken = page.NextContinuationToken;
  } while (continuationToken);
  return totalDeleted;
}

export async function size(key: string): Promise<number | null> {
  try {
    const result = await client.send(new HeadObjectCommand({ Bucket: bucket, Key: key }));
    return result.ContentLength ?? null;
  } catch (error) {
    if ((error as { $metadata?: { httpStatusCode?: number } }).$metadata?.httpStatusCode === 404) return null;
    throw error;
  }
}
