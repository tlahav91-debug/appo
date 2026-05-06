// [EDGE-FN] claim-marathon-reward — validates series completion within marathon window, grants coins

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

  let body: { marathon_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const { marathon_id } = body;
  if (!marathon_id) return json({ error: "marathon_id is required" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Fetch marathon
  const { data: marathon } = await supabase
    .from("marathon_events")
    .select("id, series_id, title, starts_at, ends_at, reward_coins, reward_collectible_id, is_active")
    .eq("id", marathon_id)
    .maybeSingle();

  if (!marathon) return json({ error: "Marathon not found" }, 404);
  if (!marathon.is_active) return json({ error: "Marathon is not active" }, 400);

  const now = new Date();
  if (now < new Date(marathon.starts_at)) return json({ error: "Marathon has not started yet" }, 400);
  if (now > new Date(marathon.ends_at)) return json({ error: "Marathon has ended" }, 400);

  // Idempotency: already claimed
  const { data: existing } = await supabase
    .from("marathon_completions")
    .select("reward_claimed_at")
    .eq("user_id", userId)
    .eq("marathon_id", marathon_id)
    .maybeSingle();

  if (existing?.reward_claimed_at) {
    return json({ granted: false, already_claimed: true });
  }

  // Verify the series is fully completed (all episodes watched)
  const { data: episodes } = await supabase
    .from("episodes")
    .select("id")
    .eq("series_id", marathon.series_id);

  if (!episodes || episodes.length === 0) {
    return json({ error: "Series has no episodes" }, 400);
  }

  const { data: progress } = await supabase
    .from("watch_progress")
    .select("episode_id, completed")
    .eq("user_id", userId)
    .eq("series_id", marathon.series_id);

  const completedIds = new Set(
    (progress ?? []).filter((p) => p.completed).map((p) => p.episode_id),
  );
  const allComplete = episodes.every((ep) => completedIds.has(ep.id));
  if (!allComplete) return json({ error: "Series not fully completed yet" }, 400);

  // Insert completion row — ignoreDuplicates makes PK conflict a no-op, preventing double-grant
  const { data: claimRows, error: claimErr } = await supabase
    .from("marathon_completions")
    .upsert(
      { user_id: userId, marathon_id, reward_claimed_at: now.toISOString() },
      { onConflict: "user_id,marathon_id", ignoreDuplicates: true },
    )
    .select("user_id");
  if (claimErr) return json({ error: "Failed to record completion" }, 500);
  // If the PK conflict fired, no row was returned — another request already claimed
  if (!claimRows || claimRows.length === 0) {
    return json({ granted: false, already_claimed: true });
  }

  // Credit coins atomically via increment_currency RPC
  const serviceClient = supabase;
  const { error: coinsErr } = await serviceClient.rpc("increment_currency", {
    uid: userId,
    d_coins: marathon.reward_coins,
    d_gems: 0,
  });
  if (coinsErr) {
    console.error("increment_currency failed:", coinsErr.message);
    return json({ error: "Failed to credit coins" }, 500);
  }

  await serviceClient.from("currency_ledger").insert({
    user_id: userId,
    currency_type: "scrolls",
    delta: marathon.reward_coins,
    reason: "marathon_reward",
    reference_id: marathon_id,
    idempotency_key: `${userId}:marathon:${marathon_id}`,
  });

  // Mint collectible reward if configured
  let collectibleGranted = false;
  if (marathon.reward_collectible_id) {
    const { error: mintErr } = await supabase
      .from("user_collectibles")
      .insert({ user_id: userId, collectible_id: marathon.reward_collectible_id });
    collectibleGranted = !mintErr;
  }

  return json({
    granted: true,
    coins_granted: marathon.reward_coins,
    collectible_granted: collectibleGranted,
  });
});
