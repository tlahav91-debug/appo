// [EDGE-FN] record-choice — records a user's episode choice and credits coins

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DEFAULT_COIN_REWARD = 10;

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { episode_id?: string; choice_id?: string; idempotency_key?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const { episode_id, choice_id, idempotency_key } = body;
  if (!episode_id || !choice_id || !idempotency_key) {
    return json({ error: "episode_id, choice_id, and idempotency_key are required" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Idempotency: if coin ledger row already exists, return early
  const { data: existingLedger } = await supabase
    .from("currency_ledger")
    .select("balance_after, delta")
    .eq("idempotency_key", idempotency_key)
    .maybeSingle();

  if (existingLedger) {
    return json({
      choice_id,
      coins_earned: existingLedger.delta,
      new_balance: existingLedger.balance_after,
      idempotent: true,
    }, 200);
  }

  // Verify the choice belongs to the episode and fetch reward amount
  const { data: choice } = await supabase
    .from("episode_choices")
    .select("id, label, reward_coins, episode_id")
    .eq("id", choice_id)
    .eq("episode_id", episode_id)
    .maybeSingle();

  if (!choice) return json({ error: "Choice not found for this episode" }, 404);

  // Verify episode exists and check if it's free
  const { data: episode } = await supabase
    .from("episodes")
    .select("id, is_free")
    .eq("id", episode_id)
    .maybeSingle();

  if (!episode) return json({ error: "Episode not found" }, 404);

  // Verify unlock if episode is not free
  if (!episode.is_free) {
    const { data: unlock } = await supabase
      .from("episode_unlocks")
      .select("id")
      .eq("user_id", userId)
      .eq("episode_id", episode_id)
      .maybeSingle();

    if (!unlock) {
      return json({ error: "Episode not unlocked", code: "EPISODE_LOCKED" }, 403);
    }
  }

  // Insert user_episode_choices — ignore conflict (idempotent choice recording)
  const { error: choiceInsertErr } = await supabase
    .from("user_episode_choices")
    .insert({ user_id: userId, episode_id, choice_id });

  if (choiceInsertErr && !choiceInsertErr.message.includes("duplicate")) {
    return json({ error: "Failed to record choice" }, 500);
  }

  // Fetch current coin balance
  const { data: profile } = await supabase
    .from("profiles")
    .select("coins")
    .eq("id", userId)
    .single();

  if (!profile) return json({ error: "Profile not found" }, 404);

  const reward = choice.reward_coins > 0 ? choice.reward_coins : DEFAULT_COIN_REWARD;
  const newBalance = profile.coins + reward;

  // Insert ledger row (idempotency_key UNIQUE constraint is the final guard)
  const { error: ledgerErr } = await supabase.from("currency_ledger").insert({
    user_id: userId,
    currency_type: "scrolls",
    delta: reward,
    balance_after: newBalance,
    reason: "episode_choice",
    idempotency_key,
    reference_id: choice_id,
  });

  if (ledgerErr) {
    // Unique violation — concurrent call won; return that row
    const { data: raceRow } = await supabase
      .from("currency_ledger")
      .select("balance_after, delta")
      .eq("idempotency_key", idempotency_key)
      .single();
    return json({
      choice_id,
      coins_earned: raceRow?.delta ?? reward,
      new_balance: raceRow?.balance_after ?? newBalance,
      idempotent: true,
    }, 200);
  }

  // Update profile coins cache
  await supabase
    .from("profiles")
    .update({ coins: newBalance })
    .eq("id", userId);

  return json({ choice_id, coins_earned: reward, new_balance: newBalance }, 200);
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
