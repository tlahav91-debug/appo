import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

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
  const body = await req.json().catch(() => ({}));
  const type: string = body.type;
  if (type !== "free" && type !== "paid") {
    return json({ error: "type must be 'free' or 'paid'" }, 400);
  }

  const now = new Date();
  const tomorrow = new Date(now.getTime() + 86400000).toISOString().split("T")[0];
  const yesterday = new Date(now.getTime() - 86400000).toISOString().split("T")[0];

  // Verify streak is actually broken (no check-in today or yesterday)
  const { data: recentRow } = await supabaseAdmin
    .from("daily_check_ins")
    .select("id")
    .eq("user_id", userId)
    .gte("checked_in_at", `${yesterday}T00:00:00Z`)
    .lt("checked_in_at", `${tomorrow}T00:00:00Z`)
    .maybeSingle();

  if (recentRow) return json({ error: "Streak is not broken" }, 409);

  // Read profile
  const { data: profile } = await supabaseAdmin
    .from("profiles")
    .select("streak_shield_available, gems")
    .eq("id", userId)
    .single();

  if (!profile) return json({ error: "Profile not found" }, 404);

  if (type === "free") {
    if (!profile.streak_shield_available) {
      return json({ error: "No free shield available" }, 402);
    }
    await supabaseAdmin
      .from("profiles")
      .update({ streak_shield_available: false })
      .eq("id", userId);
  } else {
    // paid — 50 gems
    if ((profile.gems ?? 0) < 50) {
      return json({ error: "Insufficient gems", required: 50, current: profile.gems ?? 0 }, 402);
    }
    await supabaseAdmin.rpc("increment_currency", {
      uid: userId,
      d_coins: 0,
      d_gems: -50,
    });
  }

  // Get last streak_day to restore one step forward
  const { data: lastRow } = await supabaseAdmin
    .from("daily_check_ins")
    .select("streak_day, checked_in_at")
    .eq("user_id", userId)
    .order("checked_in_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const restoredStreakDay = lastRow
    ? (lastRow.streak_day < 7 ? lastRow.streak_day + 1 : 1)
    : 1;

  // Insert yesterday's check-in as the restored row
  const { error: insertErr } = await supabaseAdmin
    .from("daily_check_ins")
    .insert({
      user_id: userId,
      streak_day: restoredStreakDay,
      reward_coins: 0,
      reward_gems: 0,
      checked_in_at: `${yesterday}T12:00:00Z`,
    });

  if (insertErr) {
    const status = (insertErr as { code?: string }).code === "23505" ? 409 : 500;
    const msg = status === 409 ? "Shield already used" : "Restore failed";
    return json({ error: msg }, status);
  }

  // Remove any scheduled streak_reminder push for this user
  await supabaseAdmin
    .from("scheduled_push_notifications")
    .delete()
    .eq("user_id", userId)
    .eq("type", "streak_reminder");

  return json({ restored: true, streak_day: restoredStreakDay, type });
});
