// [EDGE-FN] record-premium-choice — deducts coins and records a premium choice selection

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  // BUG-006 fix: request_id removed — idempotency is keyed on userId+episode+choice
  let body: { episode_id?: string; choice_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const { episode_id, choice_id } = body;
  if (!episode_id || !choice_id) {
    return json({ error: "episode_id and choice_id are required" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // BUG-001 fix: verify episode is unlocked, consistent with record-choice
  const { data: episode } = await supabase
    .from("episodes")
    .select("id, is_free")
    .eq("id", episode_id)
    .maybeSingle();

  if (!episode) return json({ error: "Episode not found" }, 404);

  if (!episode.is_free) {
    const { data: unlock } = await supabase
      .from("episode_unlocks")
      .select("id")
      .eq("user_id", userId)
      .eq("episode_id", episode_id)
      .maybeSingle();
    if (!unlock) return json({ error: "Episode not unlocked", code: "EPISODE_LOCKED" }, 403);
  }

  // Fetch the choice to validate it is premium and get cost
  const { data: choice } = await supabase
    .from("episode_choices")
    .select("id, is_premium, premium_coin_cost")
    .eq("id", choice_id)
    .eq("episode_id", episode_id)
    .maybeSingle();

  if (!choice) return json({ error: "Choice not found" }, 404);
  if (!choice.is_premium || choice.premium_coin_cost <= 0) {
    return json({ error: "This choice is not a premium choice" }, 400);
  }

  const cost = choice.premium_coin_cost as number;

  // Idempotency: check if already recorded
  const idempotencyKey = `${userId}:premium_choice:${episode_id}:${choice_id}`;
  const { data: existing } = await supabase
    .from("currency_ledger")
    .select("id")
    .eq("idempotency_key", idempotencyKey)
    .maybeSingle();
  if (existing) return json({ choice_recorded: true, already_recorded: true, coins_spent: cost });

  // Check and debit coins — optimistic lock prevents concurrent double-spend
  const { data: profile } = await supabase
    .from("profiles")
    .select("coins")
    .eq("id", userId)
    .single();
  if (!profile) return json({ error: "Profile not found" }, 404);
  if ((profile.coins ?? 0) < cost) {
    return json({ code: "INSUFFICIENT_COINS", required: cost, current: profile.coins ?? 0 }, 402);
  }

  const coinsAfter = profile.coins - cost;
  const { data: debited, error: debitErr } = await supabase
    .from("profiles")
    .update({ coins: coinsAfter })
    .eq("id", userId)
    .eq("coins", profile.coins) // optimistic lock
    .select("coins")
    .maybeSingle();

  if (debitErr || !debited) {
    return json({ code: "COIN_CONFLICT", message: "Balance changed, please retry" }, 409);
  }

  // Ledger row (also serves as idempotency record)
  const { error: ledgerErr } = await supabase.from("currency_ledger").insert({
    user_id: userId,
    currency_type: "scrolls",
    delta: -cost,
    balance_after: debited.coins,
    reason: "premium_choice",
    idempotency_key: idempotencyKey,
    reference_id: choice_id,
  });

  if (ledgerErr) {
    if (ledgerErr.code === "23505") {
      return json({ choice_recorded: true, already_recorded: true, coins_spent: cost });
    }
    // BUG-004 fix: atomic refund via RPC avoids clobbering concurrent coin grants
    await supabase.rpc("increment_currency", { uid: userId, d_coins: cost, d_gems: 0 });
    return json({ error: "Failed to record choice" }, 500);
  }

  // BUG-003 fix: handle user_episode_choices insert errors explicitly
  const { error: choiceInsertErr } = await supabase.from("user_episode_choices").insert({
    user_id: userId,
    episode_id,
    choice_id,
  });

  if (choiceInsertErr && choiceInsertErr.code !== "23505") {
    // Non-duplicate insert failure — atomic refund and surface error
    await supabase.rpc("increment_currency", { uid: userId, d_coins: cost, d_gems: 0 });
    return json({ error: "Failed to record choice" }, 500);
  }

  return json({ choice_recorded: true, already_recorded: false, coins_spent: cost });
});
