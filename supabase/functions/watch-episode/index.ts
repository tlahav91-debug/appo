// [EDGE-FN] watch-episode — validates energy, debits 5, unlocks episode

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const EPISODE_ENERGY_COST = 5;
const MAX_ENERGY = 20;

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { episode_id?: string; request_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const { episode_id, request_id } = body;
  if (!episode_id || !request_id) {
    return json({ error: "episode_id and request_id are required" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Idempotency: return early if this exact request_id already completed
  const { data: existingByRequest } = await supabase
    .from("episode_unlocks")
    .select("id")
    .eq("user_id", userId)
    .eq("episode_id", episode_id)
    .eq("reference_id", request_id)
    .maybeSingle();

  if (existingByRequest) {
    return json({ unlocked: true, already_unlocked: true }, 200);
  }

  // Also return early if episode already unlocked by any prior call
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
  const { data: episode } = await supabase
    .from("episodes")
    .select("id, is_free, energy_cost")
    .eq("id", episode_id)
    .maybeSingle();

  if (!episode) return json({ error: "Episode not found" }, 404);

  // Fetch profile
  const { data: profile } = await supabase
    .from("profiles")
    .select("current_energy, last_refill_at")
    .eq("id", userId)
    .single();

  if (!profile) return json({ error: "Profile not found" }, 404);

  // Lazy refill calculation
  const now = Date.now();
  const lastRefillMs = new Date(profile.last_refill_at).getTime();
  const hoursElapsed = Math.floor((now - lastRefillMs) / 3_600_000);
  const refilledEnergy = Math.min(MAX_ENERGY, profile.current_energy + hoursElapsed);

  // Advance last_refill_at by credited hours (don't drift if already at max)
  const hoursConsumedByRefill = refilledEnergy - profile.current_energy;
  const advancedRefillAt = refilledEnergy === MAX_ENERGY
    ? new Date(now).toISOString()
    : new Date(lastRefillMs + hoursConsumedByRefill * 3_600_000).toISOString();

  // Free episode: persist refill state but no energy debit
  if (episode.is_free) {
    await supabase.from("profiles")
      .update({ current_energy: refilledEnergy, last_refill_at: advancedRefillAt })
      .eq("id", userId);

    await supabase.from("episode_unlocks").insert({
      user_id: userId,
      episode_id,
      energy_cost_paid: 0,
      reference_id: request_id,
    });

    return json({ unlocked: true, energy_remaining: refilledEnergy }, 200);
  }

  // Paid episode: check sufficient energy
  const cost = episode.energy_cost ?? EPISODE_ENERGY_COST;
  if (refilledEnergy < cost) {
    return json({ code: "INSUFFICIENT_ENERGY", current: refilledEnergy, required: cost }, 402);
  }

  const newEnergy = refilledEnergy - cost;

  // Optimistic-lock UPDATE: only succeeds if current_energy hasn't changed since we read it
  // This prevents double-debit from concurrent requests
  const { data: updatedRows, error: updateErr } = await supabase
    .from("profiles")
    .update({ current_energy: newEnergy, last_refill_at: advancedRefillAt })
    .eq("id", userId)
    .eq("current_energy", profile.current_energy)  // optimistic lock
    .select("id");

  if (updateErr || !updatedRows || updatedRows.length === 0) {
    // Another concurrent request updated energy first — ask client to retry
    return json({ code: "ENERGY_CONFLICT", message: "Energy state changed, please retry" }, 409);
  }

  // Insert unlock row — ON CONFLICT handles the rare race where both pass optimistic lock
  const { error: unlockErr } = await supabase.from("episode_unlocks").insert({
    user_id: userId,
    episode_id,
    energy_cost_paid: cost,
    reference_id: request_id,
  });

  if (unlockErr) {
    // UNIQUE constraint fired — episode was unlocked by the concurrent request
    // Revert the energy debit since the unlock already exists
    await supabase.from("profiles")
      .update({ current_energy: refilledEnergy, last_refill_at: advancedRefillAt })
      .eq("id", userId);
    return json({ unlocked: true, already_unlocked: true }, 200);
  }

  await supabase.from("energy_log").insert({
    user_id: userId,
    delta: -cost,
    balance_after: newEnergy,
    reason: "episode_watch",
    reference_id: episode_id,
  });

  // Best-effort Drama Pass attribution + milestone notifications — fire-and-forget
  (async () => {
    const { data: passProfile } = await supabase
      .from('profiles')
      .select('drama_pass_active')
      .eq('id', userId)
      .single();

    const { data: ep } = await supabase
      .from('episodes')
      .select('creator_id')
      .eq('id', episode_id)
      .single();

    // Drama Pass attribution (PRD-047)
    if (passProfile?.drama_pass_active && ep?.creator_id) {
      await supabase.from('pass_watch_events').upsert(
        { user_id: userId, episode_id, creator_id: ep.creator_id },
        { onConflict: 'user_id,episode_id', ignoreDuplicates: true }
      );
    }

    // Milestone check — best effort
    if (ep?.creator_id) {
      const { count: totalViews } = await supabase
        .from("episode_unlocks")
        .select("id", { count: "exact", head: true })
        .eq("episode_id", episode_id);

      const thresholds = [
        { count: 100, type: "milestone_100_views", label: "100" },
        { count: 1000, type: "milestone_1k_views", label: "1,000" },
        { count: 10000, type: "milestone_10k_views", label: "10,000" },
      ];

      for (const t of thresholds) {
        if ((totalViews ?? 0) >= t.count) {
          // Check if milestone notification already sent
          const { data: existing } = await supabase
            .from("creator_notifications")
            .select("id")
            .eq("user_id", ep.creator_id)
            .eq("type", t.type)
            .contains("metadata", { episode_id })
            .maybeSingle();
          if (!existing) {
            await supabase.from("creator_notifications").insert({
              user_id: ep.creator_id,
              type: t.type,
              title: `${t.label} views milestone!`,
              body: `Your episode has reached ${t.label} views. Keep it up!`,
              metadata: { episode_id },
            });
          }
        }
      }
    }
  })();

  return json({ unlocked: true, energy_remaining: newEnergy }, 200);
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
