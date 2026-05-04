// [EDGE-FN] snapshot-weekly-xp — bulk idempotent XP snapshot for weekly leaderboard

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const authHeader = req.headers.get("Authorization") ?? "";
  if (authHeader !== `Bearer ${serviceKey}`) return json({ error: "Forbidden" }, 403);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceClient = createClient(supabaseUrl, serviceKey);

  // Compute Monday of current week (UTC)
  const now = new Date();
  now.setUTCHours(0, 0, 0, 0);
  now.setUTCDate(now.getUTCDate() - ((now.getUTCDay() + 6) % 7));
  const weekStart = now.toISOString().substring(0, 10);

  // Fetch all profiles
  const { data: profiles, error: profilesErr } = await serviceClient
    .from("profiles")
    .select("id, xp")
    .limit(10000);
  if (profilesErr || !profiles) return json({ error: "Failed to fetch profiles" }, 500);

  if (profiles.length === 0) return json({ snapshotted: 0, week_start: weekStart });

  const rows = profiles.map((p: { id: string; xp: number }) => ({
    user_id: p.id,
    week_start: weekStart,
    xp_at_start: p.xp ?? 0,
  }));

  // ignoreDuplicates: re-running mid-week is a no-op for already-snapshotted users
  await serviceClient
    .from("weekly_xp_snapshots")
    .upsert(rows, { onConflict: "user_id,week_start", ignoreDuplicates: true });

  return json({ snapshotted: rows.length, week_start: weekStart });
});
