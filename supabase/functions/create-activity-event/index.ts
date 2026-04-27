// [EDGE-FN] create-activity-event — upsert a watch activity event for the calling user

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { episode_id?: string; series_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { episode_id, series_id } = body;
  if (!episode_id) return json({ error: "episode_id required" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // getUser() validates the JWT against Supabase Auth on the service-role client —
  // this is the correct server-side pattern; auth.currentUser is always null on server clients
  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  const { error } = await supabase.from("activity_events").upsert(
    { user_id: user.id, episode_id, series_id: series_id ?? null },
    { onConflict: "user_id,episode_id", ignoreDuplicates: false }
  );

  if (error) return json({ error: error.message }, 500);
  return json({ ok: true });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
