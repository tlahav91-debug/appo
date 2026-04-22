// [EDGE-FN] revenuecat-webhook — handles IAP and subscription events from RevenueCat

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEM_PACKS: Record<string, number> = {
  "drama_gems_100":  100,
  "drama_gems_500":  500,
  "drama_gems_1200": 1200,
  "drama_gems_3000": 3000,
};

const DRAMA_PASS_PRODUCT = "drama_pass_monthly";

const GEM_CREDIT_EVENTS  = new Set(["INITIAL_PURCHASE", "NON_SUBSCRIPTION_PURCHASE"]);
const PASS_ACTIVATE_EVENTS = new Set(["INITIAL_PURCHASE", "RENEWAL"]);
const PASS_DEACTIVATE_EVENTS = new Set(["EXPIRATION"]);

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
  if (!webhookSecret || authHeader !== `Bearer ${webhookSecret}`) {
    return json({ error: "Unauthorized" }, 401);
  }

  let payload: {
    event?: {
      type?: string;
      app_user_id?: string;
      product_id?: string;
      transaction_id?: string;
    };
  };
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

  // ── Drama Pass subscription ──────────────────────────────────────────────────
  if (product_id === DRAMA_PASS_PRODUCT) {
    if (PASS_ACTIVATE_EVENTS.has(type)) {
      await supabase
        .from("profiles")
        .update({ drama_pass_active: true })
        .eq("id", app_user_id);
      return json({ status: "ok", drama_pass_active: true }, 200);
    }
    if (PASS_DEACTIVATE_EVENTS.has(type)) {
      await supabase
        .from("profiles")
        .update({ drama_pass_active: false })
        .eq("id", app_user_id);
      return json({ status: "ok", drama_pass_active: false }, 200);
    }
    // CANCELLATION etc. — let expiration handle the deactivation
    return json({ status: "ignored", type }, 200);
  }

  // ── Gem pack one-time purchase ───────────────────────────────────────────────
  const gemAmount = GEM_PACKS[product_id];
  if (!gemAmount) {
    return json({ status: "ignored", reason: "unknown_product", product_id }, 200);
  }

  if (!GEM_CREDIT_EVENTS.has(type)) {
    return json({ status: "ignored", type }, 200);
  }

  if (!transaction_id) {
    return json({ error: "Missing transaction_id" }, 400);
  }

  // Idempotency check
  const { data: existing } = await supabase
    .from("currency_ledger")
    .select("id, balance_after")
    .eq("idempotency_key", transaction_id)
    .maybeSingle();

  if (existing) {
    return json({ status: "already_processed", balance_after: existing.balance_after }, 200);
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("gems")
    .eq("id", app_user_id)
    .single();

  if (!profile) return json({ error: "Profile not found" }, 404);

  const newBalance = profile.gems + gemAmount;

  const { error: ledgerErr } = await supabase.from("currency_ledger").insert({
    user_id: app_user_id,
    currency_type: "gems",
    delta: gemAmount,
    balance_after: newBalance,
    reason: "iap_purchase",
    idempotency_key: transaction_id,
    reference_id: product_id,
  });

  if (ledgerErr) {
    const { data: raceRow } = await supabase
      .from("currency_ledger")
      .select("balance_after")
      .eq("idempotency_key", transaction_id)
      .single();
    return json({ status: "ok", balance_after: raceRow?.balance_after ?? newBalance }, 200);
  }

  await supabase
    .from("profiles")
    .update({ gems: newBalance })
    .eq("id", app_user_id);

  return json({ status: "ok", gems_credited: gemAmount, balance_after: newBalance }, 200);
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
