import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Energy cost → USD conversion: 1 energy unit ≈ $0.05 (rough equivalent)
const ENERGY_USD_RATE = 0.05;
const CREATOR_SHARE = 0.60;

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const adminSecret = req.headers.get("x-admin-secret");
  if (!adminSecret || adminSecret !== Deno.env.get("ADMIN_SECRET")) {
    return json({ error: "Unauthorized" }, 401);
  }

  let body: { episode_id?: string; energy_spent?: number };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { episode_id, energy_spent = 1 } = body;
  if (!episode_id) return json({ error: "episode_id is required" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Direct lookup: episodes.creator_id (set at approval time)
  const { data: episode } = await supabase
    .from("episodes")
    .select("creator_id")
    .eq("id", episode_id)
    .maybeSingle();

  if (!episode?.creator_id) return json({ ok: true, credited: false });
  const creatorId = episode.creator_id;

  const revenueUsd = energy_spent * ENERGY_USD_RATE * CREATOR_SHARE;
  const today = new Date().toISOString().split("T")[0];

  const { error } = await supabase.rpc("increment_energy_revenue", {
    p_creator_id: creatorId,
    p_episode_id: episode_id,
    p_date: today,
    p_amount: revenueUsd,
  });

  if (error) return json({ error: error.message }, 500);
  return json({ ok: true, credited: true, amount_usd: revenueUsd });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
