import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Unauthorized" }, 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return json({ error: "Unauthorized" }, 401);

  const body = await req.json().catch(() => null);
  const { item_id } = body ?? {};
  if (!item_id) return json({ error: "item_id is required" }, 400);

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Fetch item — validate ownership, not claimed, not expired
  const { data: item, error: fetchErr } = await admin
    .from("inbox_items")
    .select("id, user_id, reward_coins, reward_gems, claimed, expires_at")
    .eq("id", item_id)
    .eq("user_id", user.id)
    .single();

  if (fetchErr || !item) return json({ error: "Item not found" }, 404);
  if (item.claimed) return json({ error: "Already claimed" }, 409);
  if (item.expires_at && new Date(item.expires_at) < new Date()) return json({ error: "Item expired" }, 410);

  // Mark claimed — use .select() so we can detect 0 rows matched (race condition guard)
  const { data: claimData, error: claimErr } = await admin
    .from("inbox_items")
    .update({ claimed: true })
    .eq("id", item_id)
    .eq("claimed", false)
    .select("id");

  if (claimErr) return json({ error: "Claim failed — retry" }, 409);
  if (!claimData || claimData.length === 0) return json({ error: "Already claimed" }, 409);

  // Credit rewards if any
  if (item.reward_coins > 0 || item.reward_gems > 0) {
    const { data: profile } = await admin.from("profiles").select("coins, gems").eq("id", user.id).single();
    if (profile) {
      await admin.from("profiles").update({
        coins: (profile.coins ?? 0) + item.reward_coins,
        gems: (profile.gems ?? 0) + item.reward_gems,
      }).eq("id", user.id);
    }
  }

  return json({ claimed: true, coins_earned: item.reward_coins, gems_earned: item.reward_gems });
});
