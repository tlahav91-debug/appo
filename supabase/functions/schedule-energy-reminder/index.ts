// [EDGE-FN] schedule-energy-reminder — upserts a scheduled push for when energy is full

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// 1 energy unit refills every 1 hour (matches energy_provider.dart Duration(hours: 1))
const REFILL_SECONDS_PER_UNIT = 3600;

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { energy_current?: number; energy_max?: number };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const { energy_current, energy_max } = body;
  if (energy_current === undefined || energy_max === undefined) {
    return json({ error: "energy_current and energy_max are required" }, 400);
  }

  if (energy_current >= energy_max) {
    return json({ skipped: true, reason: "energy_already_full" });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Check notification preference — notification_prefs is a JSONB column on profiles
  // Absent energy_reminder key is treated as opted-in (true)
  const { data: profile } = await supabase
    .from("profiles")
    .select("notification_prefs")
    .eq("id", userId)
    .maybeSingle();

  if (profile?.notification_prefs?.energy_reminder === false) {
    return json({ skipped: true, reason: "pref_disabled" });
  }

  // Check push token exists
  const { data: tokenRow } = await supabase
    .from("push_tokens")
    .select("token")
    .eq("user_id", userId)
    .maybeSingle();

  if (!tokenRow?.token) {
    return json({ skipped: true, reason: "no_push_token" });
  }

  const unitsNeeded = energy_max - energy_current;
  const secondsUntilFull = unitsNeeded * REFILL_SECONDS_PER_UNIT;
  const scheduledFor = new Date(Date.now() + secondsUntilFull * 1000).toISOString();

  const payload = {
    title: "⚡ You're back to full energy!",
    body: "Tap to keep watching.",
    data: { screen: "/home" },
  };

  const { error: upsertErr } = await supabase
    .from("scheduled_push_notifications")
    .upsert(
      { user_id: userId, type: "energy_refilled", scheduled_for: scheduledFor, payload, sent_at: null },
      { onConflict: "user_id,type" },
    );

  if (upsertErr) return json({ error: "Failed to schedule reminder" }, 500);

  return json({ scheduled_for: scheduledFor });
});
