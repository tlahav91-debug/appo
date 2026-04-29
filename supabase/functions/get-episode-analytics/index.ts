import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return json({ error: "Unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Validate JWT and get user
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: authErr } = await userClient.auth.getUser();
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  let body: { submission_id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { submission_id } = body;
  if (!submission_id) return json({ error: "submission_id required" }, 400);

  const serviceClient = createClient(supabaseUrl, serviceKey);

  // Verify the submission belongs to the requesting user
  const { data: submission, error: subErr } = await serviceClient
    .from("content_submissions")
    .select("id, title, episode_number, cf_stream_id, status, series_id, series(title)")
    .eq("id", submission_id)
    .eq("creator_id", user.id)
    .maybeSingle();

  if (subErr || !submission) {
    return json({ error: "Episode not found or access denied" }, 404);
  }

  // Fetch last 30 daily analytics snapshots
  const { data: analytics, error: analyticsErr } = await serviceClient
    .from("creator_episode_analytics")
    .select("date, view_count, avg_completion_pct, revenue_scrolls")
    .eq("submission_id", submission_id)
    .order("date", { ascending: false })
    .limit(30);

  if (analyticsErr) return json({ error: "Failed to fetch analytics" }, 500);

  const rows = (analytics ?? []) as Array<{
    date: string;
    view_count: number;
    avg_completion_pct: number;
    revenue_scrolls: number;
  }>;

  const totalViews = rows.reduce((s, r) => s + r.view_count, 0);
  const totalScrolls = rows.reduce((s, r) => s + r.revenue_scrolls, 0);
  const avgCompletion = rows.length
    ? parseFloat(
        (rows.reduce((s, r) => s + Number(r.avg_completion_pct), 0) / rows.length).toFixed(2),
      )
    : 0;

  const seriesData = submission.series as { title?: string } | null;

  return json({
    episode: {
      title: submission.title,
      episode_number: submission.episode_number,
      series_title: seriesData?.title ?? "",
      status: submission.status,
      cf_stream_id: submission.cf_stream_id,
    },
    analytics: rows,
    summary: {
      total_views: totalViews,
      avg_completion_pct: avgCompletion,
      total_scrolls: totalScrolls,
    },
  });
});
