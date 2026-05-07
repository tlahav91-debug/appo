import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

// Escalating rewards per streak day (7-day cycle)
const STREAK_REWARDS: { coins: number; gems: number }[] = [
  { coins: 20,  gems: 0  }, // Day 1
  { coins: 30,  gems: 0  }, // Day 2
  { coins: 50,  gems: 2  }, // Day 3
  { coins: 75,  gems: 0  }, // Day 4
  { coins: 100, gems: 5  }, // Day 5
  { coins: 150, gems: 0  }, // Day 6
  { coins: 75,  gems: 10 }, // Day 7
];

serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const jwt = req.headers.get("Authorization")?.replace("Bearer ", "");
  if (!jwt) return json({ error: "Unauthorized" }, 401);

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { data: { user }, error: authErr } = await supabaseAdmin.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  const userId = user.id;
  const now = new Date();
  const today = now.toISOString().split("T")[0];
  const tomorrow = new Date(now.getTime() + 86400000).toISOString().split("T")[0];

  // Check already claimed today — use exclusive tomorrow boundary (BUG-027-H-1 fix)
  const { data: todayRow } = await supabaseAdmin
    .from("daily_check_ins")
    .select("id")
    .eq("user_id", userId)
    .gte("checked_in_at", `${today}T00:00:00Z`)
    .lt("checked_in_at", `${tomorrow}T00:00:00Z`)
    .maybeSingle();

  if (todayRow) return json({ error: "Already claimed today" }, 409);

  // Get last check-in to compute streak
  const { data: lastRow } = await supabaseAdmin
    .from("daily_check_ins")
    .select("checked_in_at, streak_day")
    .eq("user_id", userId)
    .order("checked_in_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  let streakDay = 1;
  if (lastRow) {
    const lastDate = new Date(lastRow.checked_in_at).toISOString().split("T")[0];
    const yesterday = new Date(now.getTime() - 86400000).toISOString().split("T")[0];
    if (lastDate === yesterday) {
      streakDay = lastRow.streak_day < 7 ? lastRow.streak_day + 1 : 1;
    }
  }

  const reward = STREAK_REWARDS[streakDay - 1];

  // Read drama_pass_active only — do NOT read coins/gems to avoid stale read
  const { data: profile } = await supabaseAdmin
    .from("profiles")
    .select("drama_pass_active")
    .eq("id", userId)
    .single();

  const multiplier = profile?.drama_pass_active ? 2 : 1;
  const coinsEarned = reward.coins * multiplier;
  const gemsEarned = reward.gems * multiplier;

  // Insert check-in — unique index on (user_id, checked_in_at::date) guards against race
  const { error: insertErr } = await supabaseAdmin
    .from("daily_check_ins")
    .insert({ user_id: userId, streak_day: streakDay, reward_coins: coinsEarned, reward_gems: gemsEarned });

  if (insertErr) {
    // Unique violation (23505) = concurrent claim — return 409 not 500 (BUG-027-H-1 fix)
    const status = (insertErr as { code?: string }).code === "23505" ? 409 : 500;
    const msg = status === 409 ? "Already claimed today" : "Claim failed";
    return json({ error: msg }, status);
  }

  // Atomic increment — avoids lost-update race condition (BUG-027-C-1 fix)
  await supabaseAdmin.rpc("increment_currency", {
    uid: userId,
    d_coins: coinsEarned,
    d_gems: gemsEarned,
  });

  // Grant streak shield on day-7 cycle completion
  if (streakDay === 7) {
    await supabaseAdmin
      .from("profiles")
      .update({ streak_shield_available: true })
      .eq("id", userId);
  }

  return json({
    claimed: true,
    streak_day: streakDay,
    coins_earned: coinsEarned,
    gems_earned: gemsEarned,
    shield_granted: streakDay === 7,
  });
});
