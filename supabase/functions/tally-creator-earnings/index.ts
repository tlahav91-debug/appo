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

  if (!authHeader.includes(serviceKey)) {
    return json({ error: "Service role required" }, 401);
  }

  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    serviceKey,
  );

  // Fetch all approved submissions that have a series_id
  const { data: submissions, error: fetchErr } = await serviceClient
    .from("content_submissions")
    .select("id, creator_id, series_id, episode_number")
    .eq("status", "approved")
    .not("series_id", "is", null);

  if (fetchErr) return json({ error: "Failed to fetch submissions" }, 500);
  if (!submissions?.length) return json({ tallied: 0 });

  const period = new Date();
  period.setDate(1);
  const periodStr = period.toISOString().substring(0, 10);

  const SCROLLS_PER_10_STREAMS = 1;

  const upserts = submissions.map((s: Record<string, unknown>) => {
    // Placeholder stream count — replace with Cloudflare Stream API in PRD-069
    const streamCount = Math.floor(Math.random() * 500) + 10;
    const revenueScrolls = Math.floor(streamCount / 10) * SCROLLS_PER_10_STREAMS;
    return {
      creator_id: s.creator_id,
      series_id: s.series_id,
      submission_id: s.id,
      period: periodStr,
      stream_count: streamCount,
      revenue_scrolls: revenueScrolls,
    };
  });

  const { error: upsertErr } = await serviceClient
    .from("creator_earnings")
    .upsert(upserts, { onConflict: "submission_id,period", ignoreDuplicates: false });

  if (upsertErr) return json({ error: "Upsert failed: " + upsertErr.message }, 500);

  return json({ tallied: upserts.length });
});
