import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const adminSecret = req.headers.get("x-admin-secret");
  if (!adminSecret || adminSecret !== Deno.env.get("ADMIN_SECRET")) {
    return json({ error: "Unauthorized" }, 401);
  }

  let body: {
    submission_id?: string;
    is_free?: boolean;
    episode_order?: number;
    series_id?: string;
    new_series_title?: string;
  };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { submission_id, is_free = false, episode_order = 1, series_id, new_series_title } = body;
  if (!submission_id) return json({ error: "submission_id is required" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Fetch submission
  const { data: sub } = await supabase
    .from("content_submissions")
    .select("*")
    .eq("id", submission_id)
    .maybeSingle();

  if (!sub) return json({ error: "Submission not found" }, 404);

  // Optimistic lock: atomically flip status to 'approved' only if still 'submitted'
  const { data: locked, error: lockErr } = await supabase
    .from("content_submissions")
    .update({ status: "approved", reviewed_at: new Date().toISOString() })
    .eq("id", submission_id)
    .eq("status", "submitted")
    .select("id")
    .maybeSingle();

  if (lockErr) return json({ error: lockErr.message }, 500);
  if (!locked) return json({ error: "Submission already processed" }, 409);

  // Now safe to create series/episode — lock is held

  // Resolve or create series
  let resolvedSeriesId = series_id;
  if (!resolvedSeriesId && new_series_title) {
    // Series INSERT — remove creator_id and thumbnail_url:
    const { data: newSeries, error: seriesErr } = await supabase
      .from("series")
      .insert({
        title: new_series_title,
        description: sub.description ?? "",
        genre: sub.genre ?? "",
      })
      .select("id")
      .single();
    if (seriesErr) return json({ error: seriesErr.message }, 500);
    resolvedSeriesId = newSeries.id;
  }

  if (!resolvedSeriesId) return json({ error: "series_id or new_series_title is required" }, 400);

  // Build video URL from Cloudflare Stream
  const cfCustomerSubdomain = Deno.env.get("CF_CUSTOMER_SUBDOMAIN") ?? "";
  const videoUrl = sub.cf_stream_id
    ? `https://customer-${cfCustomerSubdomain}.cloudflarestream.com/${sub.cf_stream_id}/manifest/video.m3u8`
    : "";

  // Episode INSERT — add creator_id:
  const { data: episode, error: epErr } = await supabase
    .from("episodes")
    .insert({
      series_id: resolvedSeriesId,
      title: sub.title,
      episode_number: episode_order,
      video_url: videoUrl,
      thumbnail_url: sub.thumbnail_url ?? "",
      is_free,
      creator_id: sub.creator_id,  // new column
    })
    .select("id")
    .single();

  if (epErr) return json({ error: epErr.message }, 500);

  // Notify creator — best-effort, do not propagate failures
  try {
    await supabase.from("creator_notifications").insert({
      user_id: sub.creator_id,
      type: "content_approved",
      title: "Content approved!",
      body: `Your episode "${sub.title}" has been approved and is now live.`,
      metadata: { submission_id },
    });
  } catch (notifErr) {
    console.error("Failed to insert content_approved notification:", notifErr);
  }

  // Notify followers (best-effort)
  await fetch(`${Deno.env.get("SUPABASE_URL")}/functions/v1/notify-followers`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-admin-secret": Deno.env.get("ADMIN_SECRET") ?? "",
    },
    body: JSON.stringify({
      creator_id: sub.creator_id,
      episode_title: sub.title,
    }),
  }).catch(() => {}); // fire and forget

  return json({ ok: true, episode_id: episode.id, series_id: resolvedSeriesId });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
