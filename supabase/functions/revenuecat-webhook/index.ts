// [EDGE-FN] revenuecat-webhook — credits gems on IAP purchase events from RevenueCat

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEM_PACKS: Record<string, number> = {
  "drama_gems_100":  100,
  "drama_gems_500":  500,
  "drama_gems_1200": 1200,
  "drama_gems_3000": 3000,
};

const CREDIT_EVENTS = new Set([
  "INITIAL_PURCHASE",
  "NON_SUBSCRIPTION_PURCHASE",
]);

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  // Verify RevenueCat webhook secret
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

  // Only credit on purchase events
  if (!type || !CREDIT_EVENTS.has(type)) {
    return json({ status: "ignored", type }, 200);
  }

  if (!app_user_id || !product_id || !transaction_id) {
    return json({ error: "Missing required event fields" }, 400);
  }

  const gemAmount = GEM_PACKS[product_id];
  if (!gemAmount) {
    return json({ error: `Unknown product: ${product_id}` }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Idempotency: check if transaction already processed
  const { data: existing } = await supabase
    .from("currency_ledger")
    .select("id, balance_after")
    .eq("idempotency_key", transaction_id)
    .maybeSingle();

  if (existing) {
    return json({ status: "already_processed", balance_after: existing.balance_after }, 200);
  }

  // Fetch current gem balance
  const { data: profile } = await supabase
    .from("profiles")
    .select("gems")
    .eq("id", app_user_id)
    .single();

  if (!profile) return json({ error: "Profile not found" }, 404);

  const newBalance = profile.gems + gemAmount;

  // Insert ledger row
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
    // Race: another webhook beat us; return the winning row
    const { data: raceRow } = await supabase
      .from("currency_ledger")
      .select("balance_after")
      .eq("idempotency_key", transaction_id)
      .single();
    return json({ status: "ok", balance_after: raceRow?.balance_after ?? newBalance }, 200);
  }

  // Update profile gems cache
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
