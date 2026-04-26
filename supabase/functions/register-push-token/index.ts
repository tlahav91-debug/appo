// [EDGE-FN] register-push-token — upserts FCM token for the authenticated user

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
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  const body = await req.json().catch(() => null);
  const { token, platform } = body ?? {};
  if (!token || !["ios", "android"].includes(platform)) {
    return json({ error: "token and platform (ios|android) are required" }, 400);
  }

  const { error } = await supabase
    .from("push_tokens")
    .upsert(
      { user_id: user.id, token, platform, updated_at: new Date().toISOString() },
      { onConflict: "user_id,token" },
    );

  if (error) return json({ error: error.message }, 500);
  return json({ registered: true });
});
