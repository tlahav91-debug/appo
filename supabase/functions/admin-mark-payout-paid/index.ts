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

  let body: { request_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { request_id } = body;
  if (!request_id) return json({ error: "request_id is required" }, 400);

  const { data: existing } = await serviceClient
    .from("payout_requests")
    .select("id, status, creator_id, amount_scrolls")
    .eq("id", request_id)
    .maybeSingle();

  if (!existing) return json({ error: "Payout request not found" }, 404);
  if (existing.status !== "pending") return json({ error: "Payout already processed" }, 409);

  const { error } = await serviceClient
    .from("payout_requests")
    .update({ status: "paid", paid_at: new Date().toISOString() })
    .eq("id", request_id);

  if (error) return json({ error: error.message }, 500);

  try {
    await serviceClient.from("creator_notifications").insert({
      user_id: existing.creator_id,
      type: "payout_processed",
      title: "Payout processed!",
      body: `Your payout of ${existing.amount_scrolls} 🪙 has been processed.`,
      metadata: { request_id },
    });
  } catch (notifErr) {
    console.error("Failed to insert payout_processed notification:", notifErr);
  }

  return json({ ok: true });
});
