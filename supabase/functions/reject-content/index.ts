import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const adminSecret = req.headers.get("x-admin-secret");
  if (!adminSecret || adminSecret !== Deno.env.get("ADMIN_SECRET")) {
    return json({ error: "Unauthorized" }, 401);
  }

  let body: { submission_id?: string; reason?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { submission_id, reason } = body;
  if (!submission_id) return json({ error: "submission_id is required" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: existing } = await supabase
    .from("content_submissions")
    .select("id, status")
    .eq("id", submission_id)
    .maybeSingle();

  if (!existing) return json({ error: "Submission not found" }, 404);
  if (existing.status !== "submitted") return json({ error: "Submission is not in submitted status" }, 409);

  const { error } = await supabase
    .from("content_submissions")
    .update({
      status: "rejected",
      rejection_reason: reason ?? "Submission did not meet content guidelines.",
      reviewed_at: new Date().toISOString(),
    })
    .eq("id", submission_id);

  if (error) return json({ error: error.message }, 500);
  return json({ ok: true });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
