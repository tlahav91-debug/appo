// [EDGE-FN] ad-reward — grants energy or coins after a rewarded ad view

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MAX_ADS_PER_DAY = 5;
const AD_ENERGY_REWARD = 2;
const AD_COINS_REWARD = 50;
const MAX_ENERGY = 20;

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { reward_type?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }
  const { reward_type } = body;
  if (reward_type !== "energy" && reward_type !== "coins") {
    return json({ error: "reward_type must be 'energy' or 'coins'" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Count today's ad views
  const todayStart = new Date();
  todayStart.setUTCHours(0, 0, 0, 0);

  const { count: viewsToday } = await supabase
    .from("ad_views")
    .select("*", { count: "exact", head: true })
    .eq("user_id", userId)
    .gte("viewed_at", todayStart.toISOString());

  if ((viewsToday ?? 0) >= MAX_ADS_PER_DAY) {
    return json({ code: "AD_CAP_REACHED", views_today: MAX_ADS_PER_DAY }, 403);
  }

  const newViewCount = (viewsToday ?? 0) + 1;

  // Fetch profile
  const { data: profile } = await supabase
    .from("profiles")
    .select("current_energy, last_refill_at, coins")
    .eq("id", userId)
    .single();

  if (!profile) return json({ error: "Profile not found" }, 404);

  // Lazy refill
  const now = Date.now();
  const hoursElapsed = Math.floor((now - new Date(profile.last_refill_at).getTime()) / 3_600_000);
  const refilledEnergy = Math.min(MAX_ENERGY, profile.current_energy + hoursElapsed);

  // Record ad view first
  await supabase.from("ad_views").insert({
    user_id: userId,
    reward_type,
    reward_amount: reward_type === "energy" ? AD_ENERGY_REWARD : AD_COINS_REWARD,
  });

  if (reward_type === "energy") {
    const newEnergy = Math.min(MAX_ENERGY, refilledEnergy + AD_ENERGY_REWARD);
    const hoursConsumed = refilledEnergy - profile.current_energy;
    const lastRefill = new Date(profile.last_refill_at).getTime();
    const newLastRefillAt = newEnergy === MAX_ENERGY
      ? new Date(now).toISOString()
      : new Date(lastRefill + hoursConsumed * 3_600_000).toISOString();

    await supabase.from("profiles")
      .update({ current_energy: newEnergy, last_refill_at: newLastRefillAt })
      .eq("id", userId);

    await supabase.from("energy_log").insert({
      user_id: userId,
      delta: AD_ENERGY_REWARD,
      balance_after: newEnergy,
      reason: "ad_reward",
    });

    return json({
      reward_type: "energy",
      reward_amount: AD_ENERGY_REWARD,
      energy_remaining: newEnergy,
      ad_views_today: newViewCount,
    }, 200);
  } else {
    // Coins reward
    const idempotencyKey = `ad_reward_${userId}_${todayStart.toISOString()}_${newViewCount}`;
    const newCoins = profile.coins + AD_COINS_REWARD;

    await supabase.from("currency_ledger").insert({
      user_id: userId,
      currency_type: "scrolls",
      delta: AD_COINS_REWARD,
      balance_after: newCoins,
      reason: "ad_reward",
      idempotency_key: idempotencyKey,
    });

    await supabase.from("profiles")
      .update({ coins: newCoins })
      .eq("id", userId);

    return json({
      reward_type: "coins",
      reward_amount: AD_COINS_REWARD,
      energy_remaining: refilledEnergy,
      ad_views_today: newViewCount,
    }, 200);
  }
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
