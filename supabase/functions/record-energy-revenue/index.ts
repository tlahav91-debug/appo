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

  // Find the episode's creator via content_submissions
  const { data: submission } = await supabase
    .from("content_submissions")
    .select("creator_id")
    .eq("series_id", (
      await supabase.from("episodes").select("series_id").eq("id", episode_id).maybeSingle()
    ).data?.series_id)
    .eq("status", "approved")
    .limit(1)
    .maybeSingle();

  // If no creator found (e.g. platform-owned content), skip silently
  if (!submission?.creator_id) return json({ ok: true, credited: false });

  const revenueUsd = energy_spent * ENERGY_USD_RATE * CREATOR_SHARE;
  const today = new Date().toISOString().split("T")[0];

  const { error } = await supabase.from("creator_earnings").upsert(
    {
      creator_id: submission.creator_id,
      episode_id,
      date: today,
      energy_gate_revenue_usd: revenueUsd,
    },
    {
      onConflict: "creator_id,episode_id,date",
      ignoreDuplicates: false,
    }
  );

  // Note: upsert increments require a DB function for atomic add; this inserts new row per day
  if (error) return json({ error: error.message }, 500);
  return json({ ok: true, credited: true, amount_usd: revenueUsd });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
