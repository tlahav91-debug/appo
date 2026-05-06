import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

const EPISODE_ACHIEVEMENT_XP: Record<string, number> = {
  first_episode: 10,
  episodes_10: 25,
  episodes_50: 50,
};

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Unauthorized" }, 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return json({ error: "Unauthorized" }, 401);

  const body = await req.json().catch(() => null);
  const { episode_id, series_id, progress_pct, completed = false } = body ?? {};

  if (!episode_id || !series_id || progress_pct === undefined) {
    return json({ error: "episode_id, series_id, progress_pct are required" }, 400);
  }
  if (typeof progress_pct !== "number" || progress_pct < 0 || progress_pct > 100) {
    return json({ error: "progress_pct must be 0–100" }, 400);
  }

  const { error } = await supabase.from("watch_progress").upsert({
    user_id: user.id,
    series_id,
    episode_id,
    progress_pct,
    completed,
    last_watched_at: new Date().toISOString(),
  }, { onConflict: "user_id,episode_id" });

  if (error) return json({ error: error.message }, 500);

  // Grant episode-count achievements when a new completion is recorded
  if (completed) {
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { count: completedCount } = await serviceClient
      .from("watch_progress")
      .select("*", { count: "exact", head: true })
      .eq("user_id", user.id)
      .eq("completed", true);

    const thresholds: Record<number, string> = {
      1: "first_episode",
      10: "episodes_10",
      50: "episodes_50",
    };

    for (const [threshold, key] of Object.entries(thresholds)) {
      if ((completedCount ?? 0) >= Number(threshold)) {
        const { data: existing } = await serviceClient
          .from("user_achievements")
          .select("achievement_key")
          .eq("user_id", user.id)
          .eq("achievement_key", key)
          .maybeSingle();
        if (!existing) {
          const { error: achErr } = await serviceClient
            .from("user_achievements")
            .insert({ user_id: user.id, achievement_key: key });
          if (!achErr) {
            await serviceClient.rpc("grant_xp", {
              p_user_id: user.id,
              p_amount: EPISODE_ACHIEVEMENT_XP[key],
              p_source: "achievement",
            });
          }
          // 23505 = concurrent insert already granted it — no action needed
        }
      }
    }
  }

  return json({ ok: true });
});
