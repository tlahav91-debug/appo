// [EDGE-FN] unlock-episode-coins — spends coins to permanently unlock a paid episode

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

  let body: { episode_id?: string; request_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const { episode_id, request_id } = body;
  if (!episode_id || !request_id) {
    return json({ error: "episode_id and request_id are required" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Idempotency: already unlocked by any prior call
  const { data: priorUnlock } = await supabase
    .from("episode_unlocks")
    .select("id")
    .eq("user_id", userId)
    .eq("episode_id", episode_id)
    .maybeSingle();
  if (priorUnlock) return json({ unlocked: true, already_unlocked: true });

  // Fetch episode and validate it has a coin cost
  const { data: episode } = await supabase
    .from("episodes")
    .select("id, coin_cost")
    .eq("id", episode_id)
    .maybeSingle();
  if (!episode) return json({ error: "Episode not found" }, 404);
  if (!episode.coin_cost || episode.coin_cost <= 0) {
    return json({ error: "This episode cannot be unlocked with coins" }, 400);
  }

  const cost = episode.coin_cost as number;

  // Read then conditional update — optimistic lock prevents concurrent double-spend
  const { data: profile } = await supabase
    .from("profiles")
    .select("coins")
    .eq("id", userId)
    .single();
  if (!profile) return json({ error: "Profile not found" }, 404);
  if ((profile.coins ?? 0) < cost) {
    return json({ code: "INSUFFICIENT_COINS", required: cost, current: profile.coins ?? 0 }, 402);
  }
  const coinsAfterDebit = profile.coins - cost;
  const { data: debited, error: debitErr } = await supabase
    .from("profiles")
    .update({ coins: coinsAfterDebit })
    .eq("id", userId)
    .eq("coins", profile.coins) // optimistic lock — fails if balance changed concurrently
    .select("coins")
    .maybeSingle();
  if (debitErr || !debited) {
    return json({ code: "COIN_CONFLICT", message: "Balance changed, please retry" }, 409);
  }

  // Record unlock
  const { error: unlockErr } = await supabase
    .from("episode_unlocks")
    .insert({ user_id: userId, episode_id, energy_cost_paid: 0, reference_id: request_id });

  if (unlockErr) {
    if (unlockErr.code === "23505") return json({ unlocked: true, already_unlocked: true });
    // Refund coins on unlock record failure
    await supabase.from("profiles").update({ coins: debited.coins + cost }).eq("id", userId);
    return json({ error: "Failed to record unlock" }, 500);
  }

  // Log to currency ledger
  const { data: finalProfile } = await supabase
    .from("profiles")
    .select("coins")
    .eq("id", userId)
    .single();

  await supabase.from("currency_ledger").insert({
    user_id: userId,
    currency_type: "scrolls",
    delta: -cost,
    balance_after: finalProfile?.coins ?? 0,
    reason: "episode_coin_unlock",
    reference_id: episode_id,
    idempotency_key: `${userId}:coin_unlock:${episode_id}`,
  });

  return json({ unlocked: true, already_unlocked: false, coins_remaining: finalProfile?.coins ?? 0 });
});
