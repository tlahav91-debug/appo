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
  if (insertErr) return json({ error: "Failed to record achievement" }, 500);

  // Credit XP
  const xpReward = XP_REWARDS[achievement_key];
  const { data: profile } = await serviceClient
    .from("profiles")
    .select("xp")
    .eq("id", userId)
    .single();
  if (profile) {
    await serviceClient
      .from("profiles")
      .update({ xp: (profile.xp ?? 0) + xpReward })
      .eq("id", userId);
  }

  return json({ granted: true, achievement_key, xp_awarded: xpReward });
});
