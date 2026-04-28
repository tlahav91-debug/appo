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

  // Verify the JWT and get the user via the anon client (respects RLS)
  const anonClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await anonClient.auth.getUser();
  if (authError || !user) return json({ error: "Unauthorized" }, 401);

  const body = await req.json().catch(() => null);
  const { episode_id } = body ?? {};

  if (!episode_id) {
    return json({ error: "episode_id is required" }, 400);
  }

  // Use service_role client to bypass RLS for the INSERT
  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Look up the collectible for this episode
  const { data: collectible, error: lookupError } = await serviceClient
    .from("collectibles")
    .select("id")
    .eq("episode_id", episode_id)
    .maybeSingle();

  if (lookupError) return json({ error: lookupError.message }, 500);
  if (!collectible) return json({ error: "No collectible found for this episode" }, 404);

  const collectibleId = collectible.id as string;

  // Check if user already owns this collectible
  const { data: existing } = await serviceClient
    .from("user_collectibles")
    .select("collectible_id")
    .eq("user_id", user.id)
    .eq("collectible_id", collectibleId)
    .maybeSingle();

  if (existing) {
    return json({ collectible_id: collectibleId, already_owned: true });
  }

  // Insert — idempotent via ON CONFLICT DO NOTHING
  const { error: insertError } = await serviceClient
    .from("user_collectibles")
    .insert({
      user_id: user.id,
      collectible_id: collectibleId,
      earned_at: new Date().toISOString(),
    });

  if (insertError) return json({ error: insertError.message }, 500);

  return json({ collectible_id: collectibleId, already_owned: false });
});
