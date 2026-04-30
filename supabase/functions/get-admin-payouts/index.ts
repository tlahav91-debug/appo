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

  const { data: rows, error: qErr } = await serviceClient
    .from("payout_requests")
    .select("id, creator_id, amount_scrolls, requested_at, creator_profiles!payout_requests_creator_id_fkey(display_name)")
    .eq("status", "pending")
    .order("requested_at", { ascending: true })
    .limit(1000);

  if (qErr) return json({ error: qErr.message }, 500);

  const payouts = (rows ?? []).map((row: Record<string, unknown>) => ({
    id: row.id,
    creator_id: row.creator_id,
    creator_name: (row.creator_profiles as { display_name?: string } | null)?.display_name ?? "Unknown",
    amount_scrolls: row.amount_scrolls,
    requested_at: row.requested_at,
  }));

  return json({ payouts });
});
