// [EDGE-FN] update-notification-prefs — merges notification preference toggles for authenticated user

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const VALID_KEYS = new Set(["new_episodes", "streak_reminder", "creator_updates", "inbox_rewards"]);

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

  let body: { prefs?: Record<string, unknown> };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { prefs } = body;
  if (!prefs || typeof prefs !== "object" || Array.isArray(prefs)) {
    return json({ error: "prefs object is required" }, 400);
  }

  const invalidKeys = Object.keys(prefs).filter((k) => !VALID_KEYS.has(k));
  if (invalidKeys.length > 0) {
    return json({ error: `Unknown preference keys: ${invalidKeys.join(", ")}` }, 400);
  }
  const invalidValues = Object.entries(prefs).filter(([, v]) => typeof v !== "boolean");
  if (invalidValues.length > 0) {
    return json({ error: "All preference values must be boolean" }, 400);
  }

  const anonClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
  );
  const { data: { user }, error: authErr } = await anonClient.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: current, error: fetchErr } = await serviceClient
    .from("profiles")
    .select("notification_prefs")
    .eq("id", userId)
    .single();

  if (fetchErr || !current) return json({ error: "Profile not found" }, 404);

  const merged = { ...(current.notification_prefs ?? {}), ...prefs };

  const { error: updateErr } = await serviceClient
    .from("profiles")
    .update({ notification_prefs: merged })
    .eq("id", userId);

  if (updateErr) return json({ error: "Failed to update preferences" }, 500);

  return json({ updated: true, prefs: merged });
});
