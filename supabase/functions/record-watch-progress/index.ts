import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

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
  return json({ ok: true });
});
