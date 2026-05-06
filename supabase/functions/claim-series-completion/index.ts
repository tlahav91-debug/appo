// [EDGE-FN] claim-series-completion — grants coins + XP once per user/series on full completion

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const COINS_REWARD = 100;
const XP_REWARD = 50;

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { series_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const { series_id } = body;
  if (!series_id) return json({ error: "series_id is required" }, 400);

  // Validate JWT with anon client
  const anonClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
  );
  const { data: { user }, error: authErr } = await anonClient.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Service-role client for all DB operations
  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Fetch all episodes for the series
  const { data: episodes, error: epErr } = await serviceClient
    .from("episodes")
    .select("id")
    .eq("series_id", series_id);

  if (epErr) return json({ error: "Failed to fetch episodes" }, 500);
  if (!episodes || episodes.length === 0) return json({ error: "Series not found or has no episodes" }, 404);

  // Fetch watch_progress for user + series
  const { data: progress, error: progressErr } = await serviceClient
    .from("watch_progress")
    .select("episode_id, completed")
    .eq("user_id", userId)
    .eq("series_id", series_id);

  if (progressErr) return json({ error: "Failed to fetch watch progress" }, 500);

  // Check every episode has a matching completed=true row
  const completedIds = new Set(
    (progress ?? [])
      .filter((p) => p.completed === true)
      .map((p) => p.episode_id),
  );

  const allComplete = episodes.every((ep) => completedIds.has(ep.id));
  if (!allComplete) return json({ error: "NOT_COMPLETE" }, 400);

  // Upsert into series_completions — ignoreDuplicates detects new vs existing
  const { count, error: upsertErr } = await serviceClient
    .from("series_completions")
    .upsert(
      { user_id: userId, series_id, coins_granted: COINS_REWARD, xp_granted: XP_REWARD },
      { onConflict: "user_id,series_id", ignoreDuplicates: true, count: "exact" },
    );

  if (upsertErr) return json({ error: "Failed to record completion" }, 500);

  // Already claimed — return early without re-granting
  if (count === 0) {
    return json({
      already_claimed: true,
      coins_granted: 0,
      xp_granted: 0,
      leveled_up: false,
      new_fan_level: null,
    }, 200);
  }

  // Newly claimed — grant XP then credit coins
  let leveledUp = false;
  let newFanLevel: number | null = null;

  // Apply Drama Pass 2x XP bonus
  const { data: passProfile } = await serviceClient
    .from("profiles")
    .select("drama_pass_active")
    .eq("id", userId)
    .single();
  const xpAmount = passProfile?.drama_pass_active ? XP_REWARD * 2 : XP_REWARD;

  const { data: xpData, error: xpErr } = await serviceClient.rpc("grant_xp", {
    p_user_id: userId,
    p_amount: xpAmount,
    p_source: "series_completion",
  });
  if (xpErr) {
    console.error("grant_xp failed:", xpErr);
  } else if (xpData) {
    leveledUp = xpData.leveled_up ?? false;
    newFanLevel = xpData.new_fan_level ?? null;
  }

  // Fetch current coin balance
  const { data: profile, error: profileErr } = await serviceClient
    .from("profiles")
    .select("coins")
    .eq("id", userId)
    .single();

  if (profileErr || !profile) {
    console.error("Profile fetch failed:", profileErr);
    return json({ error: "Profile not found" }, 404);
  }

  const newBalance = profile.coins + COINS_REWARD;

  // Insert currency_ledger row
  const { error: ledgerErr } = await serviceClient.from("currency_ledger").insert({
    user_id: userId,
    currency_type: "scrolls",
    delta: COINS_REWARD,
    balance_after: newBalance,
    reason: "series_completion",
    reference_id: series_id,
    idempotency_key: `${userId}:series_completion:${series_id}`,
  });

  if (ledgerErr) {
    console.error("currency_ledger insert failed:", ledgerErr);
  }

  // Update profile coins — always attempted regardless of ledger outcome
  const { error: updateErr } = await serviceClient
    .from("profiles")
    .update({ coins: newBalance })
    .eq("id", userId);

  if (updateErr) {
    console.error("profiles.coins update failed:", updateErr);
  }

  // Grant achievements: first_series (1st completion) and series_5 (5th completion)
  const achievementsGranted: string[] = [];
  // Keep in sync with XP_REWARDS in grant-achievement/index.ts
  const achievementXp: Record<string, number> = { first_series: 50, series_5: 150 };

  const { count: completionCount, error: countErr } = await serviceClient
    .from("series_completions")
    .select("*", { count: "exact", head: true })
    .eq("user_id", userId);

  if (!countErr) {
    const keysToCheck: string[] = [];
    if ((completionCount ?? 0) === 1) keysToCheck.push("first_series");
    if ((completionCount ?? 0) >= 5) keysToCheck.push("series_5");

    for (const key of keysToCheck) {
      const { data: existing } = await serviceClient
        .from("user_achievements")
        .select("achievement_key")
        .eq("user_id", userId)
        .eq("achievement_key", key)
        .maybeSingle();
      if (!existing) {
        const { error: achErr } = await serviceClient
          .from("user_achievements")
          .insert({ user_id: userId, achievement_key: key });
        // PK conflict (23505) means a concurrent request already granted it — not an error
        if (!achErr || achErr.code === "23505") {
          if (!achErr) achievementsGranted.push(key);
          const { data: achXpData } = await serviceClient.rpc("grant_xp", {
            p_user_id: userId,
            p_amount: achievementXp[key],
            p_source: "achievement",
          });
          if (achXpData?.leveled_up) leveledUp = true;
          if (achXpData?.new_fan_level) newFanLevel = achXpData.new_fan_level;
        }
      }
    }
  } else {
    console.error("series_completions count query failed:", countErr);
  }

  return json({
    already_claimed: false,
    coins_granted: COINS_REWARD,
    xp_granted: xpAmount,
    leveled_up: leveledUp,
    new_fan_level: newFanLevel,
    achievements_granted: achievementsGranted,
    drama_pass_bonus: passProfile?.drama_pass_active ?? false,
  }, 200);
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
