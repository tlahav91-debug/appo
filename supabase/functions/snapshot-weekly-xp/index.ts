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

  // Fetch all profiles using keyset pagination to handle more than 10k users
  const batchSize = 1000;
  let lastId = "00000000-0000-0000-0000-000000000000";
  let totalSnapshotted = 0;
  let batch: { id: string; xp: number }[];

  do {
    const { data, error: profilesErr } = await serviceClient
      .from("profiles")
      .select("id, xp")
      .gt("id", lastId)
      .order("id")
      .limit(batchSize);

    if (profilesErr) return json({ error: "Failed to fetch profiles" }, 500);

    batch = data ?? [];

    if (batch.length > 0) {
      const rows = batch.map((p) => ({
        user_id: p.id,
        week_start: weekStart,
        xp_at_start: p.xp ?? 0,
      }));

      // ignoreDuplicates: re-running mid-week is a no-op for already-snapshotted users
      await serviceClient
        .from("weekly_xp_snapshots")
        .upsert(rows, { onConflict: "user_id,week_start", ignoreDuplicates: true });

      totalSnapshotted += rows.length;
      lastId = batch[batch.length - 1].id;
    }
  } while (batch.length === batchSize);

  return json({ snapshotted: totalSnapshotted, week_start: weekStart });
});
