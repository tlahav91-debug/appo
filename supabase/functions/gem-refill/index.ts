// [EDGE-FN] gem-refill — spends 50 gems to instantly refill energy to 20

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEM_REFILL_COST = 50;
const MAX_ENERGY = 20;

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
  const userId = user.id;

  const { data: profile } = await supabase
    .from("profiles")
    .select("current_energy, last_refill_at, gems")
    .eq("id", userId)
    .single();

  if (!profile) return json({ error: "Profile not found" }, 404);

  const now = Date.now();
  const hoursElapsed = Math.floor((now - new Date(profile.last_refill_at).getTime()) / 3_600_000);
  const refilledEnergy = Math.min(MAX_ENERGY, profile.current_energy + hoursElapsed);

  if (refilledEnergy >= MAX_ENERGY) {
    return json({ code: "ENERGY_FULL", energy: MAX_ENERGY }, 400);
  }

  if (profile.gems < GEM_REFILL_COST) {
    return json({ code: "INSUFFICIENT_GEMS", gems: profile.gems, required: GEM_REFILL_COST }, 402);
  }

  const energyGained = MAX_ENERGY - refilledEnergy;
  const newGems = profile.gems - GEM_REFILL_COST;
  const idempotencyKey = `gem_refill_${userId}_${now}`;

  // Insert ledger row first
  await supabase.from("currency_ledger").insert({
    user_id: userId,
    currency_type: "gems",
    delta: -GEM_REFILL_COST,
    balance_after: newGems,
    reason: "energy_refill",
    idempotency_key: idempotencyKey,
  });

  // Conditional UPDATE — WHERE gems >= GEM_REFILL_COST prevents going negative in a race
  const { data: updated } = await supabase
    .from("profiles")
    .update({ current_energy: MAX_ENERGY, gems: newGems, last_refill_at: new Date(now).toISOString() })
    .eq("id", userId)
    .gte("gems", GEM_REFILL_COST)  // BUG-003 fix: atomic guard
    .select("id");

  if (!updated || updated.length === 0) {
    // Concurrent debit already consumed the gems — roll back ledger entry
    await supabase.from("currency_ledger")
      .delete()
      .eq("idempotency_key", idempotencyKey);
    return json({ code: "INSUFFICIENT_GEMS", gems: 0, required: GEM_REFILL_COST }, 402);
  }

  await supabase.from("energy_log").insert({
    user_id: userId,
    delta: energyGained,
    balance_after: MAX_ENERGY,
    reason: "gem_refill",
  });

  return json({ energy_remaining: MAX_ENERGY, gems_remaining: newGems }, 200);
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
