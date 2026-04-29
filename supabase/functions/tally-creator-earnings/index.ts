import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!serviceKey || authHeader !== `Bearer ${serviceKey}`) {
    return json({ error: "Service role required" }, 401);
  }

  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    serviceKey,
  );

  // Fetch all approved submissions with a series_id
  const { data: submissions, error: fetchErr } = await serviceClient
    .from("content_submissions")
    .select("id, creator_id, series_id, cf_stream_id")
    .eq("status", "approved")
    .not("series_id", "is", null);

  if (fetchErr) return json({ error: "Failed to fetch submissions" }, 500);
  if (!submissions?.length) return json({ tallied: 0 });

  const now = new Date();
  const todayStr = now.toISOString().substring(0, 10);
  const periodStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const periodStr = periodStart.toISOString().substring(0, 10);

  const SCROLLS_PER_10_STREAMS = 1;
  let tallied = 0;

  for (const s of submissions as Array<Record<string, unknown>>) {
    // Fetch real play counts from CF Stream via fetch-stream-analytics
    const fnRes = await serviceClient.functions.invoke("fetch-stream-analytics", {
      body: {
        cf_stream_id: s.cf_stream_id ?? null,
        date_from: periodStr,
        date_to: todayStr,
      },
    });

    const streamData = (fnRes.data ?? { view_count: 0, avg_completion_pct: 0 }) as {
      view_count: number;
      avg_completion_pct: number;
    };

    const streamCount = streamData.view_count;
    const avgCompletion = streamData.avg_completion_pct;
    const revenueScrolls = Math.floor(streamCount / 10) * SCROLLS_PER_10_STREAMS;

    // Upsert daily analytics snapshot
    await serviceClient.from("creator_episode_analytics").upsert(
      {
        creator_id: s.creator_id,
        submission_id: s.id,
        date: todayStr,
        view_count: streamCount,
        avg_completion_pct: avgCompletion,
        revenue_scrolls: revenueScrolls,
      },
      { onConflict: "submission_id,date", ignoreDuplicates: false },
    );

    // Upsert monthly earnings rollup
    await serviceClient.from("creator_earnings").upsert(
      {
        creator_id: s.creator_id,
        series_id: s.series_id,
        submission_id: s.id,
        period: periodStr,
        stream_count: streamCount,
        revenue_scrolls: revenueScrolls,
        avg_completion_pct: avgCompletion,
      },
      { onConflict: "submission_id,period", ignoreDuplicates: false },
    );

    tallied++;
  }

  return json({ tallied });
});
