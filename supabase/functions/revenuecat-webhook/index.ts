// [EDGE-FN] revenuecat-webhook — handles IAP and subscription events from RevenueCat

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEM_PACKS: Record<string, number> = {
  "drama_gems_100":  100,
  "drama_gems_500":  500,
  "drama_gems_1500": 1500,
};

const DRAMA_PASS_PRODUCT   = "drama_pass_monthly";
const STARTER_PACK_PRODUCT = "drama_starter_pack";
const STARTER_PACK_GEMS    = 500;
const STARTER_PACK_COINS   = 200;

const GEM_CREDIT_EVENTS      = new Set(["INITIAL_PURCHASE", "NON_SUBSCRIPTION_PURCHASE"]);
const PASS_ACTIVATE_EVENTS   = new Set(["INITIAL_PURCHASE", "RENEWAL"]);
const PASS_DEACTIVATE_EVENTS = new Set(["EXPIRATION"]);

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
  if (!webhookSecret || authHeader !== `Bearer ${webhookSecret}`) {
    return json({ error: "Unauthorized" }, 401);
  }

  let payload: { event?: { type?: string; app_user_id?: string; product_id?: string; transaction_id?: string } };
  try { payload = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const event = payload.event;
  if (!event) return json({ error: "Missing event" }, 400);

  const { type, app_user_id, product_id, transaction_id } = event;
  if (!type || !app_user_id || !product_id) {
    return json({ error: "Missing required event fields" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ── Drama Pass subscription ──────────────────────────────────────────────
  if (product_id === DRAMA_PASS_PRODUCT) {
    if (PASS_ACTIVATE_EVENTS.has(type)) {
      await supabase.from("profiles").update({ drama_pass_active: true }).eq("id", app_user_id);
      return json({ status: "ok", drama_pass_active: true }, 200);
    }
    if (PASS_DEACTIVATE_EVENTS.has(type)) {
      await supabase.from("profiles").update({ drama_pass_active: false }).eq("id", app_user_id);
      return json({ status: "ok", drama_pass_active: false }, 200);
    }
    return json({ status: "ignored", type }, 200);
  }

  // ── Starter Pack (gems + coins bundle) ──────────────────────────────────
  if (product_id === STARTER_PACK_PRODUCT) {
    if (!GEM_CREDIT_EVENTS.has(type)) return json({ status: "ignored", type }, 200);
    if (!transaction_id) return json({ error: "Missing transaction_id" }, 400);
    return await handleStarterPack(supabase, app_user_id, transaction_id);
  }

  // ── Gem pack one-time purchase ───────────────────────────────────────────
  const gemAmount = GEM_PACKS[product_id];
  if (!gemAmount) return json({ status: "ignored", reason: "unknown_product", product_id }, 200);
  if (!GEM_CREDIT_EVENTS.has(type)) return json({ status: "ignored", type }, 200);
  if (!transaction_id) return json({ error: "Missing transaction_id" }, 400);
  return await handleGemPack(supabase, app_user_id, product_id, gemAmount, transaction_id);
});

async function handleGemPack(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  productId: string,
  gemAmount: number,
  txId: string,
) {
  const { data: existing } = await supabase
    .from("currency_ledger").select("id, balance_after").eq("idempotency_key", txId).maybeSingle();
  if (existing) return json({ status: "already_processed", balance_after: existing.balance_after }, 200);

  const { data: profile } = await supabase.from("profiles").select("gems").eq("id", userId).single();
  if (!profile) return json({ error: "Profile not found" }, 404);

  const newBalance = profile.gems + gemAmount;
  const { error: ledgerErr } = await supabase.from("currency_ledger").insert({
    user_id: userId, currency_type: "gems", delta: gemAmount,
    balance_after: newBalance, reason: "iap_purchase", idempotency_key: txId, reference_id: productId,
  });
  if (ledgerErr) {
    const { data: raceRow } = await supabase.from("currency_ledger").select("balance_after").eq("idempotency_key", txId).single();
    return json({ status: "ok", balance_after: raceRow?.balance_after ?? newBalance }, 200);
  }
  await supabase.from("profiles").update({ gems: newBalance }).eq("id", userId);
  return json({ status: "ok", gems_credited: gemAmount, balance_after: newBalance }, 200);
}

async function handleStarterPack(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  txId: string,
) {
  const gemKey   = txId;
  const coinsKey = `${txId}_coins`;

  // Idempotency via gems ledger key
  const { data: existing } = await supabase
    .from("currency_ledger").select("id").eq("idempotency_key", gemKey).maybeSingle();
  if (existing) return json({ status: "already_processed" }, 200);

  const { data: profile } = await supabase.from("profiles").select("gems, coins").eq("id", userId).single();
  if (!profile) return json({ error: "Profile not found" }, 404);

  const newGems  = profile.gems  + STARTER_PACK_GEMS;
  const newCoins = profile.coins + STARTER_PACK_COINS;

  // Insert gems ledger row
  const { error: gemsErr } = await supabase.from("currency_ledger").insert({
    user_id: userId, currency_type: "gems", delta: STARTER_PACK_GEMS,
    balance_after: newGems, reason: "starter_pack", idempotency_key: gemKey, reference_id: STARTER_PACK_PRODUCT,
  });
  if (gemsErr && !gemsErr.code?.includes("23505")) {
    return json({ error: "Failed to credit gems" }, 500);
  }

  // Insert coins ledger row
  await supabase.from("currency_ledger").insert({
    user_id: userId, currency_type: "scrolls", delta: STARTER_PACK_COINS,
    balance_after: newCoins, reason: "starter_pack", idempotency_key: coinsKey, reference_id: STARTER_PACK_PRODUCT,
  });

  // Update profile
  await supabase.from("profiles").update({
    gems: newGems, coins: newCoins, starter_pack_purchased_at: new Date().toISOString(),
  }).eq("id", userId);

  return json({ status: "ok", gems_credited: STARTER_PACK_GEMS, coins_credited: STARTER_PACK_COINS }, 200);
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
