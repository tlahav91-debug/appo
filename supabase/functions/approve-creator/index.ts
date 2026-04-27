import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  // Admin secret auth
  const adminSecret = req.headers.get("x-admin-secret");
  if (!adminSecret || adminSecret !== Deno.env.get("ADMIN_SECRET")) {
    return json({ error: "Unauthorized" }, 401);
  }

  let body: { user_id?: string; approved?: boolean; rejection_reason?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { user_id, approved, rejection_reason } = body;
  if (!user_id || approved === undefined) {
    return json({ error: "user_id and approved are required" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const newStatus = approved ? "approved" : "rejected";

  const { data: updated, error: cpErr } = await supabase
    .from("creator_profiles")
    .update({
      status: newStatus,
      rejection_reason: approved ? null : (rejection_reason ?? "Application not approved."),
    })
    .eq("id", user_id)
    .select("id")
    .maybeSingle();

  if (cpErr) return json({ error: cpErr.message }, 500);
  if (!updated) return json({ error: "Creator profile not found" }, 404);

  const { error: profErr } = await supabase.from("profiles")
    .update({ is_creator: approved })
    .eq("id", user_id);

  if (profErr) {
    // Best-effort rollback
    await supabase.from("creator_profiles")
      .update({ status: "pending" })
      .eq("id", user_id);
    return json({ error: profErr.message }, 500);
  }

  return json({ ok: true });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
