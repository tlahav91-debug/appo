import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { title?: string; description?: string; genre?: string; episode_number?: number; thumbnail_url?: string; file_size?: number };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { title, description, genre, episode_number = 1, thumbnail_url, file_size } = body;
  if (!title) return json({ error: "title is required" }, 400);
  if (!file_size || file_size <= 0) return json({ error: "file_size is required" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Validate JWT
  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  // Check creator is approved
  const { data: profile } = await supabase
    .from("profiles")
    .select("is_creator")
    .eq("id", user.id)
    .maybeSingle();

  if (!profile?.is_creator) return json({ error: "CREATOR_NOT_APPROVED" }, 403);

  // Get Cloudflare Stream signed upload URL
  const cfAccountId = Deno.env.get("CF_ACCOUNT_ID")!;
  const cfApiToken = Deno.env.get("CF_STREAM_API_TOKEN")!;

  const cfRes = await fetch(
    `https://api.cloudflare.com/client/v4/accounts/${cfAccountId}/stream?direct_user=true`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${cfApiToken}`,
        "Tus-Resumable": "1.0.0",
        "Upload-Length": String(file_size),
        "Upload-Metadata": `name ${btoa(title)}`,
      },
    }
  );

  if (!cfRes.ok) {
    console.error("Cloudflare error:", await cfRes.text());
    return json({ error: "Failed to get upload URL" }, 500);
  }

  const uploadUrl = cfRes.headers.get("Location");
  const streamId = cfRes.headers.get("Stream-Media-Id");

  if (!uploadUrl || !streamId) return json({ error: "Invalid Cloudflare response" }, 500);

  // Create draft submission
  const { data: submission, error: insertErr } = await supabase
    .from("content_submissions")
    .insert({
      creator_id: user.id,
      title: title.trim(),
      description: description?.trim(),
      genre,
      episode_number,
      thumbnail_url,
      cf_stream_id: streamId,
      status: "draft",
    })
    .select("id")
    .single();

  if (insertErr) return json({ error: insertErr.message }, 500);

  return json({ upload_url: uploadUrl, stream_id: streamId, submission_id: submission.id });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
