// [EDGE-FN] join-race — enroll the calling user in a race (idempotent)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { race_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { race_id } = body;
  if (!race_id) return json({ error: "race_id required" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  // Verify race exists and is active
  const { data: race } = await supabase
    .from("races")
    .select("id, ends_at, is_active")
    .eq("id", race_id)
    .maybeSingle();

  if (!race || !race.is_active || new Date(race.ends_at) <= new Date()) {
    return json({ error: "Race not available" }, 404);
  }

  const { error } = await supabase.from("race_participants").insert({
    user_id: user.id,
    race_id,
  });

  // 23505 = unique_violation — user already joined
  if (error && !error.code?.includes("23505")) {
    return json({ error: "Failed to join race" }, 500);
  }

  return json({ joined: true });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
