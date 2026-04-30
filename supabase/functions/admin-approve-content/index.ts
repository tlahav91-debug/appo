import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const serviceClient = createClient(url, serviceKey);

  const { data: { user }, error: authErr } = await serviceClient.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  const { data: profile } = await serviceClient
    .from("profiles")
    .select("is_admin")
    .eq("id", user.id)
    .maybeSingle();
  if (!profile?.is_admin) return json({ error: "Forbidden" }, 403);

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

  const { data: sub } = await serviceClient
    .from("content_submissions")
    .select("*")
    .eq("id", submission_id)
    .maybeSingle();

  if (!sub) return json({ error: "Submission not found" }, 404);

  const { data: locked, error: lockErr } = await serviceClient
    .from("content_submissions")
    .update({ status: "approved", reviewed_at: new Date().toISOString() })
    .eq("id", submission_id)
    .eq("status", "submitted")
    .select("id")
    .maybeSingle();

  if (lockErr) return json({ error: lockErr.message }, 500);
  if (!locked) return json({ error: "Submission already processed" }, 409);

  let resolvedSeriesId = series_id;
  if (!resolvedSeriesId && new_series_title) {
    const { data: newSeries, error: seriesErr } = await serviceClient
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

  const cfCustomerSubdomain = Deno.env.get("CF_CUSTOMER_SUBDOMAIN") ?? "";
  const videoUrl = sub.cf_stream_id
    ? `https://customer-${cfCustomerSubdomain}.cloudflarestream.com/${sub.cf_stream_id}/manifest/video.m3u8`
    : "";

  const { data: episode, error: epErr } = await serviceClient
    .from("episodes")
    .insert({
      series_id: resolvedSeriesId,
      title: sub.title,
      episode_number: episode_order,
      video_url: videoUrl,
      thumbnail_url: sub.thumbnail_url ?? "",
      is_free,
      creator_id: sub.creator_id,
    })
    .select("id")
    .single();

  if (epErr) return json({ error: epErr.message }, 500);

  try {
    await serviceClient.from("creator_notifications").insert({
      user_id: sub.creator_id,
      type: "content_approved",
      title: "Content approved!",
      body: `Your episode "${sub.title}" has been approved and is now live.`,
      metadata: { submission_id },
    });
  } catch (notifErr) {
    console.error("Failed to insert content_approved notification:", notifErr);
  }

  await fetch(`${url}/functions/v1/notify-followers`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-admin-secret": Deno.env.get("ADMIN_SECRET") ?? "",
    },
    body: JSON.stringify({
      creator_id: sub.creator_id,
      episode_title: sub.title,
    }),
  }).catch(() => {});

  return json({ ok: true, episode_id: episode.id, series_id: resolvedSeriesId });
});
