// [EDGE-FN] grant-achievement — idempotent achievement grant with XP reward

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const XP_REWARDS: Record<string, number> = {
  first_episode: 10,
  episodes_10: 25,
  episodes_50: 50,
  streak_7: 30,
  streak_30: 100,
  first_series: 50,
  series_5: 150,
};

const VALID_KEYS = new Set(Object.keys(XP_REWARDS));

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function computeStreak(isoDates: string[]): number {
  const dates = [...new Set(isoDates.map((d) => d.slice(0, 10)))].sort((a, b) =>
    b.localeCompare(a)
  );
  if (dates.length === 0) return 0;
  const today = new Date().toISOString().slice(0, 10);
  const yesterday = new Date(Date.now() - 86_400_000).toISOString().slice(0, 10);
  if (dates[0] !== today && dates[0] !== yesterday) return 0;
  let streak = 1;
  for (let i = 1; i < dates.length; i++) {
    const prev = new Date(dates[i - 1]).getTime();
    const curr = new Date(dates[i]).getTime();
    if (Math.round((prev - curr) / 86_400_000) === 1) streak++;
    else break;
  }
  return streak;
}

async function verifyCondition(
  serviceClient: ReturnType<typeof createClient>,
  userId: string,
  key: string,
): Promise<boolean> {
  switch (key) {
    case "first_episode":
    case "episodes_10":
    case "episodes_50": {
      const required = key === "first_episode" ? 1 : key === "episodes_10" ? 10 : 50;
      const { count } = await serviceClient
        .from("watch_progress")
        .select("*", { count: "exact", head: true })
        .eq("user_id", userId)
        .eq("completed", true);
      return (count ?? 0) >= required;
    }
    case "streak_7":
    case "streak_30": {
      const required = key === "streak_7" ? 7 : 30;
      const { data: checkIns } = await serviceClient
        .from("daily_check_ins")
        .select("checked_in_at")
        .eq("user_id", userId)
        .order("checked_in_at", { ascending: false })
        .limit(60);
      if (!checkIns || checkIns.length === 0) return false;
      return computeStreak(checkIns.map((c) => c.checked_in_at as string)) >= required;
    }
    case "first_series":
    case "series_5": {
      const required = key === "first_series" ? 1 : 5;
      const { count } = await serviceClient
        .from("series_completions")
        .select("*", { count: "exact", head: true })
        .eq("user_id", userId);
      return (count ?? 0) >= required;
    }
    default:
      return false;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { achievement_key?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const { achievement_key } = body;
  if (!achievement_key) return json({ error: "achievement_key is required" }, 400);
  if (!VALID_KEYS.has(achievement_key)) return json({ error: "Unknown achievement_key" }, 400);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Validate JWT
  const anonClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!);
  const { data: { user }, error: authErr } = await anonClient.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  const serviceClient = createClient(supabaseUrl, serviceKey);

  // Server-side condition verification — prevents self-granting unearned achievements
  const conditionMet = await verifyCondition(serviceClient, userId, achievement_key);
  if (!conditionMet) return json({ error: "Condition not met" }, 403);

  // Idempotency check
  const { data: existing } = await serviceClient
    .from("user_achievements")
    .select("achievement_key")
    .eq("user_id", userId)
    .eq("achievement_key", achievement_key)
    .maybeSingle();

  if (existing) return json({ granted: false, already_earned: true });

  // Insert achievement row
  const { error: insertErr } = await serviceClient
    .from("user_achievements")
    .insert({ user_id: userId, achievement_key });
  if (insertErr) {
    // PK conflict: a concurrent request already granted it
    if (insertErr.code === "23505") return json({ granted: false, already_earned: true });
    return json({ error: "Failed to record achievement" }, 500);
  }

  // Credit XP via RPC so fan_level is recalculated atomically
  const xpReward = XP_REWARDS[achievement_key];
  let leveledUp = false;
  let newFanLevel: number | null = null;
  const { data: xpData } = await serviceClient.rpc("grant_xp", {
    p_user_id: userId,
    p_amount: xpReward,
    p_source: "achievement",
  });
  if (xpData) {
    leveledUp = xpData.leveled_up ?? false;
    newFanLevel = xpData.new_fan_level ?? null;
  }

  return json({ granted: true, achievement_key, xp_awarded: xpReward, leveled_up: leveledUp, new_fan_level: newFanLevel });
});
