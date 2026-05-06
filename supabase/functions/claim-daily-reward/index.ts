// [EDGE-FN] claim-daily-reward — idempotent daily reward claim with streak multiplier

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const REWARDS = [
  { coins: 10, gems: 0, xp: 0 },  // day 1
  { coins: 15, gems: 0, xp: 0 },  // day 2
  { coins: 20, gems: 0, xp: 0 },  // day 3
  { coins: 25, gems: 0, xp: 0 },  // day 4
  { coins: 0,  gems: 1, xp: 0 },  // day 5
  { coins: 30, gems: 0, xp: 0 },  // day 6
  { coins: 0,  gems: 2, xp: 50 }, // day 7
];

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function computeStreak(checkIns: { checked_in_at: string }[]): number {
  if (!checkIns?.length) return 0;
  const dates = [...new Set(checkIns.map((c) => c.checked_in_at.substring(0, 10)))]
    .sort()
    .reverse();
  const today = new Date().toISOString().substring(0, 10);
  const yesterday = new Date(Date.now() - 86400000).toISOString().substring(0, 10);
  if (dates[0] !== today && dates[0] !== yesterday) return 0;
  let streak = 1;
  for (let i = 1; i < dates.length; i++) {
    const prev = new Date(dates[i - 1]);
    const curr = new Date(dates[i]);
    const diff = (prev.getTime() - curr.getTime()) / 86400000;
    if (diff === 1) streak++;
    else break;
  }
  return streak;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Validate JWT to get userId
  const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  const serviceClient = createClient(supabaseUrl, serviceKey);

  // Ensure a cycle row exists for this user (insert if missing, ignore if present)
  await serviceClient.from("daily_reward_cycles").upsert(
    { user_id: userId, cycle_day: 1 },
    { onConflict: "user_id", ignoreDuplicates: true }
  );

  // Fetch current cycle state to read cycle_day and check idempotency
  const { data: cycleRow, error: cycleErr } = await serviceClient
    .from("daily_reward_cycles")
    .select("cycle_day, last_claimed_at")
    .eq("user_id", userId)
    .single();
  if (cycleErr || !cycleRow) return json({ error: "Failed to fetch cycle" }, 500);

  const cycleDay: number = cycleRow.cycle_day;
  const today = new Date().toISOString().substring(0, 10);
  const lastClaimed: string | null = cycleRow.last_claimed_at;

  // Fetch streak (before today's check-in so multiplier reflects yesterday's state)
  const { data: checkIns } = await serviceClient
    .from("daily_check_ins")
    .select("checked_in_at")
    .eq("user_id", userId)
    .order("checked_in_at", { ascending: false })
    .limit(60);
  const streak = computeStreak(checkIns ?? []);

  const baseReward = REWARDS[cycleDay - 1];
  const multiplier = streak >= 7 ? 2 : 1;
  const reward = {
    coins: baseReward.coins * multiplier,
    gems: baseReward.gems,
    xp: baseReward.xp,
  };

  // Early return for obvious already-claimed (avoids DB write attempt)
  if (lastClaimed != null && lastClaimed.substring(0, 10) === today) {
    return json({ claimed_today: true, cycle_day: cycleDay, reward, streak, already_claimed: true });
  }

  // Atomic claim guard: only advance the row when last_claimed_at is not today.
  // If two concurrent requests race here, only one will match the WHERE clause.
  const nextDay = cycleDay === 7 ? 1 : cycleDay + 1;
  const { data: claimRows } = await serviceClient
    .from("daily_reward_cycles")
    .update({
      cycle_day: nextDay,
      last_claimed_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq("user_id", userId)
    .or(`last_claimed_at.is.null,last_claimed_at.lt.${today}T00:00:00.000Z`)
    .select("cycle_day");

  // If no row was updated, another concurrent request already claimed today
  if (!claimRows || claimRows.length === 0) {
    return json({ claimed_today: true, cycle_day: cycleDay, reward, streak, already_claimed: true });
  }

  // Fetch current profile values for safe increment
  const { data: profile, error: profileErr } = await serviceClient
    .from("profiles")
    .select("scrolls, gems, xp")
    .eq("id", userId)
    .single();
  if (profileErr || !profile) return json({ error: "Failed to fetch profile" }, 500);

  // Credit rewards
  await serviceClient.from("profiles").update({
    scrolls: (profile.scrolls ?? 0) + reward.coins,
    gems: (profile.gems ?? 0) + reward.gems,
    xp: (profile.xp ?? 0) + reward.xp,
  }).eq("id", userId);

  // Insert check-in
  await serviceClient.from("daily_check_ins").insert({
    user_id: userId,
    checked_in_at: new Date().toISOString(),
  });

  // Grant streak achievements at 7 and 30 day thresholds
  const newStreak = streak + 1;
  const streakAchievements: Record<number, string> = { 7: "streak_7", 30: "streak_30" };
  const streakAchievementXp: Record<string, number> = { streak_7: 30, streak_30: 100 };
  for (const [threshold, key] of Object.entries(streakAchievements)) {
    if (newStreak >= Number(threshold)) {
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
        if (!achErr) {
          await serviceClient.rpc("grant_xp", {
            p_user_id: userId,
            p_amount: streakAchievementXp[key],
            p_source: "achievement",
          });
        }
        // 23505 = concurrent insert already granted it — no action needed
      }
    }
  }

  return json({
    claimed_today: true,
    cycle_day: cycleDay,
    reward,
    streak: newStreak,
    already_claimed: false,
  });
});
