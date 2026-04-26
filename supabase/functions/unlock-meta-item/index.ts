// [EDGE-FN] unlock-meta-item — spends gems to unlock a meta item (room, outfit, mood)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CATALOG: Record<string, Record<string, number>> = {
  room:   { apartment: 0, penthouse: 50, mansion: 120, yacht: 200, chalet: 150, island: 350 },
  outfit: { casual: 0, glam: 30, streetwear: 45, formal: 80, fantasy: 120 },
  mood:   { chill: 0, excited: 20, dramatic: 20, mysterious: 35, boss: 50 },
};

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { item_type?: string; item_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const { item_type, item_id } = body;

  // Validate item_type and item_id exist in catalog
  if (!item_type || !CATALOG[item_type]) {
    return json({ error: "Invalid item_type" }, 400);
  }
  if (!item_id || CATALOG[item_type][item_id] === undefined) {
    return json({ error: "Invalid item_id" }, 400);
  }

  const cost = CATALOG[item_type][item_id];

  // Free items don't need DB unlock — equip them directly
  if (cost === 0) {
    return json({ unlocked: true, gems_remaining: -1 });
  }

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Validate JWT and get user
  const { data: { user }, error: authErr } = await supabaseAdmin.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Check if already unlocked
  const { data: existing } = await supabaseAdmin
    .from("meta_unlocks")
    .select("id")
    .eq("user_id", userId)
    .eq("item_type", item_type)
    .eq("item_id", item_id)
    .maybeSingle();

  if (existing) {
    return json({ unlocked: true, already_owned: true });
  }

  // Fetch current gem balance
  const { data: profile } = await supabaseAdmin
    .from("profiles")
    .select("gems")
    .eq("id", userId)
    .single();

  if (!profile) return json({ error: "Profile not found" }, 404);
  if (profile.gems < cost) return json({ error: "Insufficient gems" }, 402);

  const newGems = profile.gems - cost;
  const idempotencyKey = `meta_unlock_${userId}_${item_type}_${item_id}`;

  // Insert ledger row first
  await supabaseAdmin.from("currency_ledger").insert({
    user_id: userId,
    currency_type: "gems",
    delta: -cost,
    balance_after: newGems,
    reason: "meta_unlock",
    idempotency_key: idempotencyKey,
    reference_id: item_id,
  }).maybeSingle(); // ignore duplicate if ledger already exists (race condition)

  // Atomic gem deduct with optimistic lock — WHERE gems = profile.gems prevents going negative in a race
  const { data: updated } = await supabaseAdmin
    .from("profiles")
    .update({ gems: newGems })
    .eq("id", userId)
    .eq("gems", profile.gems) // optimistic lock
    .select("id");

  if (!updated || updated.length === 0) {
    // Rollback ledger entry
    await supabaseAdmin
      .from("currency_ledger")
      .delete()
      .eq("idempotency_key", idempotencyKey);
    return json({ error: "Concurrent update — retry" }, 409);
  }

  // Insert meta unlock record
  const { error: unlockErr } = await supabaseAdmin
    .from("meta_unlocks")
    .insert({ user_id: userId, item_type, item_id });

  if (unlockErr) {
    // Rollback gems and ledger
    await supabaseAdmin
      .from("profiles")
      .update({ gems: profile.gems })
      .eq("id", userId);
    await supabaseAdmin
      .from("currency_ledger")
      .delete()
      .eq("idempotency_key", idempotencyKey);
    return json({ error: unlockErr.message }, 500);
  }

  // Fetch updated gem balance
  const { data: refreshed } = await supabaseAdmin
    .from("profiles")
    .select("gems")
    .eq("id", userId)
    .single();

  return json({ unlocked: true, gems_remaining: refreshed?.gems ?? newGems });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
