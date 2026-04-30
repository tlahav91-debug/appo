import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const serviceClient = createClient(url, serviceKey);

  const { data: { user }, error: authErr } = await serviceClient.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  const { data: profile } = await serviceClient
    .from("profiles")
    .select("is_admin")
    .eq("id", user.id)
    .maybeSingle();
  if (!profile?.is_admin) return json({ error: "Forbidden" }, 403);

  let body: { submission_id?: string; reason?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { submission_id, reason } = body;
  if (!submission_id) return json({ error: "submission_id is required" }, 400);

  const { data: existing } = await serviceClient
    .from("content_submissions")
    .select("id, status, creator_id, title")
    .eq("id", submission_id)
    .maybeSingle();

  if (!existing) return json({ error: "Submission not found" }, 404);
  if (existing.status !== "submitted") return json({ error: "Submission is not in submitted status" }, 409);

  const rejectionReason = reason ?? "Submission did not meet content guidelines.";

  const { error } = await serviceClient
    .from("content_submissions")
    .update({
      status: "rejected",
      rejection_reason: rejectionReason,
      reviewed_at: new Date().toISOString(),
    })
    .eq("id", submission_id);

  if (error) return json({ error: error.message }, 500);

  try {
    await serviceClient.from("creator_notifications").insert({
      user_id: existing.creator_id,
      type: "content_rejected",
      title: "Content not approved",
      body: `Your episode "${existing.title}" was not approved. Reason: ${rejectionReason}`,
      metadata: { submission_id, rejection_reason: rejectionReason },
    });
  } catch (notifErr) {
    console.error("Failed to insert content_rejected notification:", notifErr);
  }

  return json({ ok: true });
});
