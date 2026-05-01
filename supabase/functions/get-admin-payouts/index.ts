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
    .select("id, creator_id, amount_scrolls, requested_at")
    .eq("status", "pending")
    .order("requested_at", { ascending: true })
    .limit(1000);

  if (qErr) return json({ error: qErr.message }, 500);

  const creatorIds = [...new Set((rows ?? []).map((r: Record<string, unknown>) => r.creator_id as string))];

  const { data: creatorRows } = creatorIds.length > 0
    ? await serviceClient.from("creator_profiles").select("id, display_name").in("id", creatorIds)
    : { data: [] };

  const creatorMap = new Map((creatorRows ?? []).map((c: { id: string; display_name: string }) => [c.id, c.display_name]));

  const payouts = (rows ?? []).map((row: Record<string, unknown>) => ({
    id: row.id,
    creator_id: row.creator_id,
    creator_name: creatorMap.get(row.creator_id as string) ?? "Unknown",
    amount_scrolls: row.amount_scrolls,
    requested_at: row.requested_at,
  }));

  return json({ payouts });
});
