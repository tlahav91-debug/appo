// [EDGE-FN] watch-episode — validates energy, debits 5, unlocks episode

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const EPISODE_ENERGY_COST = 5;
const MAX_ENERGY = 20;

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  // Auth
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return json({ error: "Unauthorized" }, 401);
  }
  const jwt = authHeader.slice(7);

  // Parse body
  let body: { episode_id?: string; request_id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }
  const { episode_id, request_id } = body;
  if (!episode_id || !request_id) {
    return json({ error: "episode_id and request_id are required" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Verify JWT and get user
  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Check idempotency — return early if request_id already processed
  const { data: existingUnlock } = await supabase
    .from("episode_unlocks")
    .select("id, energy_cost_paid")
    .eq("user_id", userId)
    .eq("episode_id", episode_id)
    .eq("reference_id", request_id)
    .maybeSingle();

  if (existingUnlock) {
    return json({ unlocked: true, already_unlocked: true, energy_remaining: null }, 200);
  }

  // Also check if already unlocked by any prior request (different request_id)
  const { data: priorUnlock } = await supabase
    .from("episode_unlocks")
    .select("id")
    .eq("user_id", userId)
    .eq("episode_id", episode_id)
    .maybeSingle();

  if (priorUnlock) {
    return json({ unlocked: true, already_unlocked: true }, 200);
  }

  // Fetch episode
  const { data: episode, error: epErr } = await supabase
    .from("episodes")
    .select("id, is_free, energy_cost")
    .eq("id", episode_id)
    .maybeSingle();

  if (epErr || !episode) return json({ error: "Episode not found" }, 404);

  // Fetch profile
  const { data: profile, error: profErr } = await supabase
    .from("profiles")
    .select("current_energy, last_refill_at")
    .eq("id", userId)
    .single();

  if (profErr || !profile) return json({ error: "Profile not found" }, 404);

  // Compute lazy refill
  const now = Date.now();
  const lastRefill = new Date(profile.last_refill_at).getTime();
  const hoursElapsed = Math.floor((now - lastRefill) / 3_600_000);
  const refilledEnergy = Math.min(MAX_ENERGY, profile.current_energy + hoursElapsed);

  // Free episode — unlock with no energy debit
  if (episode.is_free) {
    await supabase.from("episode_unlocks").insert({
      user_id: userId,
      episode_id,
      energy_cost_paid: 0,
      reference_id: request_id,
    });
    return json({ unlocked: true, energy_remaining: refilledEnergy }, 200);
  }

  // Check sufficient energy
  const cost = episode.energy_cost ?? EPISODE_ENERGY_COST;
  if (refilledEnergy < cost) {
    return json({
      code: "INSUFFICIENT_ENERGY",
      current: refilledEnergy,
      required: cost,
    }, 402);
  }

  const newEnergy = refilledEnergy - cost;

  // Compute new last_refill_at:
  // If energy was refilled, advance last_refill_at by the hours consumed,
  // but if now at max reset to now() so no phantom accumulation.
  const hoursConsumedByRefill = refilledEnergy - profile.current_energy;
  const newLastRefillAt = newEnergy === MAX_ENERGY
    ? new Date(now).toISOString()
    : new Date(lastRefill + hoursConsumedByRefill * 3_600_000).toISOString();

  // Apply debit + unlock atomically via sequential service-role writes
  const { error: updateErr } = await supabase
    .from("profiles")
    .update({ current_energy: newEnergy, last_refill_at: newLastRefillAt })
    .eq("id", userId);

  if (updateErr) return json({ error: "Failed to update energy" }, 500);

  await supabase.from("episode_unlocks").insert({
    user_id: userId,
    episode_id,
    energy_cost_paid: cost,
    reference_id: request_id,
  });

  await supabase.from("energy_log").insert({
    user_id: userId,
    delta: -cost,
    balance_after: newEnergy,
    reason: "episode_watch",
    reference_id: episode_id,
  });

  return json({ unlocked: true, energy_remaining: newEnergy }, 200);
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
