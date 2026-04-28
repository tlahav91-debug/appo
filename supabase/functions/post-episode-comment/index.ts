import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Unauthorized" }, 401);

  // Validate JWT with anon client
  const anonClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await anonClient.auth.getUser();
  if (authError || !user) return json({ error: "Unauthorized" }, 401);

  const body = await req.json().catch(() => null);
  const { episode_id, body: rawBody } = body ?? {};

  if (!episode_id || typeof episode_id !== "string") {
    return json({ error: "episode_id is required" }, 400);
  }

  const trimmedBody = typeof rawBody === "string" ? rawBody.trim() : "";
  if (trimmedBody.length < 1 || trimmedBody.length > 500) {
    return json({ error: "body must be between 1 and 500 characters" }, 400);
  }

  // Use service_role client for DB writes
  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Verify episode exists
  const { data: episode, error: episodeError } = await serviceClient
    .from("episodes")
    .select("id")
    .eq("id", episode_id)
    .single();

  if (episodeError || !episode) {
    return json({ error: "Episode not found" }, 404);
  }

  // Insert comment
  const { data: comment, error: insertError } = await serviceClient
    .from("episode_comments")
    .insert({
      episode_id,
      user_id: user.id,
      body: trimmedBody,
    })
    .select("id, episode_id, user_id, body, created_at")
    .single();

  if (insertError || !comment) {
    return json({ error: insertError?.message ?? "Insert failed" }, 500);
  }

  return json(comment, 201);
});
