import { createClient } from "npm:@supabase/supabase-js@^2.45.0";
import { handleStorageRequest } from "./handler.ts";
import { upload, download, remove, removeFolder } from "./storage.ts";

Deno.serve((req: Request) => {
  // Every database request uses the caller's JWT and RLS, never a service key.
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
      auth: { persistSession: false },
    },
  );
  return handleStorageRequest(req, {
    canAccess: async (patientId) => {
      const { data, error } = await supabase.rpc("can_current_staff_access_patient", {
        p_patient_id: patientId,
      });
      return !error && data === true;
    },
    patientExists: async (patientId) => {
      const { data, error } = await supabase.from("patients")
        .select("id").eq("id", patientId).maybeSingle();
      if (error) throw error;
      return data !== null;
    },
    upload, download, remove, removeFolder,
  });
});
