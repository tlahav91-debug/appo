// [EDGE-FN] claim-quest-reward — credit gems+coins for a completed lava quest (idempotent)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { quest_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { quest_id } = body;
  if (!quest_id) return json({ error: "quest_id required" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Fetch quest
  const { data: quest } = await supabase
    .from("lava_quests")
    .select("id, reward_gems, reward_coins, ends_at, is_active")
    .eq("id", quest_id)
    .maybeSingle();

  if (!quest || !quest.is_active) return json({ error: "Quest not found" }, 404);
  if (new Date(quest.ends_at) <= new Date()) return json({ error: "Quest expired" }, 410);

  // Fetch user progress
  const { data: progress } = await supabase
    .from("user_quest_progress")
    .select("completed_at, reward_claimed_at")
    .eq("user_id", userId)
    .eq("quest_id", quest_id)
    .maybeSingle();

  if (!progress?.completed_at) return json({ error: "Quest not completed" }, 403);

  // Idempotent: already claimed
  if (progress.reward_claimed_at) {
    return json({ gems_earned: quest.reward_gems, coins_earned: quest.reward_coins, idempotent: true }, 200);
  }

  // Fetch current balances
  const { data: profile } = await supabase
    .from("profiles")
    .select("gems, coins")
    .eq("id", userId)
    .single();

  if (!profile) return json({ error: "Profile not found" }, 404);

  const txId = `quest_${quest_id}_${userId}`;
  const newGems = profile.gems + quest.reward_gems;
  const newCoins = profile.coins + quest.reward_coins;

  // Credit gems
  await supabase.from("currency_ledger").insert({
    user_id: userId,
    currency_type: "gems",
    delta: quest.reward_gems,
    balance_after: newGems,
    reason: "quest_reward",
    idempotency_key: `${txId}_gems`,
    reference_id: quest_id,
  });

  // Credit coins
  await supabase.from("currency_ledger").insert({
    user_id: userId,
    currency_type: "scrolls",
    delta: quest.reward_coins,
    balance_after: newCoins,
    reason: "quest_reward",
    idempotency_key: `${txId}_coins`,
    reference_id: quest_id,
  });

  // Update profile balances + mark claimed atomically
  await Promise.all([
    supabase.from("profiles")
      .update({ gems: newGems, coins: newCoins })
      .eq("id", userId),
    supabase.from("user_quest_progress")
      .update({ reward_claimed_at: new Date().toISOString() })
      .eq("user_id", userId)
      .eq("quest_id", quest_id),
  ]);

  return json({ gems_earned: quest.reward_gems, coins_earned: quest.reward_coins });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
