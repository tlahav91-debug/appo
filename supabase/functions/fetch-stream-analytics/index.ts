import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

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

  let body: { cf_stream_id?: string; date_from?: string; date_to?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { cf_stream_id, date_from, date_to } = body;

  // Graceful fallback when no stream ID provided
  if (!cf_stream_id) {
    return json({ view_count: 0, avg_completion_pct: 0 });
  }

  const accountId = Deno.env.get("CF_STREAM_ACCOUNT_ID") ?? "";
  const apiToken = Deno.env.get("CF_STREAM_API_TOKEN") ?? "";

  if (!accountId || !apiToken) {
    return json({ view_count: 0, avg_completion_pct: 0 });
  }

  try {
    // Build query string manually — URLSearchParams percent-encodes brackets
    // which CF's API does not accept. Use repeated metrics[] params.
    const qsParts = [
      "metrics[]=totalImpressions",
      "metrics[]=viewerPercentage",
      "filters[0][key]=videoUID",
      "filters[0][operator]==",
      `filters[0][value]=${encodeURIComponent(cf_stream_id)}`,
    ];
    if (date_from) qsParts.push(`since=${date_from}`);
    if (date_to) qsParts.push(`until=${date_to}`);
    const qs = qsParts.join("&");

    const cfRes = await fetch(
      `https://api.cloudflare.com/client/v4/accounts/${accountId}/stream/analytics/views?${qs}`,
      { headers: { Authorization: `Bearer ${apiToken}` } },
    );

    if (!cfRes.ok) {
      return json({ view_count: 0, avg_completion_pct: 0 });
    }

    const data = await cfRes.json();
    const totals = data?.result?.totals ?? {};
    const viewCount = Math.round(totals.totalImpressions ?? 0);
    const avgCompletion = parseFloat(
      (totals.viewerPercentage ?? 0).toFixed(2),
    );

    return json({ view_count: viewCount, avg_completion_pct: avgCompletion });
  } catch {
    // Never surface CF errors to caller — return zeroes
    return json({ view_count: 0, avg_completion_pct: 0 });
  }
});
