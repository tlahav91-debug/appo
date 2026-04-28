import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const adminSecret = req.headers.get("x-admin-secret");
  if (!adminSecret || adminSecret !== Deno.env.get("ADMIN_SECRET")) {
    return json({ error: "Unauthorized" }, 401);
  }

  let body: { payout_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { payout_id } = body;
  if (!payout_id) return json({ error: "payout_id is required" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: payout } = await supabase
    .from("creator_payouts")
    .select("*")
    .eq("id", payout_id)
    .maybeSingle();

  if (!payout) return json({ error: "Payout not found" }, 404);
  if (payout.status !== "pending") return json({ error: "Payout is not pending" }, 409);

  // Mark as processing
  const { error: processingErr } = await supabase
    .from("creator_payouts").update({ status: "processing" }).eq("id", payout_id);
  if (processingErr) return json({ error: processingErr.message }, 500);

  const stripeKey = Deno.env.get("STRIPE_SECRET_KEY")!;
  const amountCents = Math.round(Number(payout.amount_usd) * 100);

  // Look up Stripe Connect account ID for creator (stored in creator_profiles.stripe_account_id)
  const { data: creatorProfile } = await supabase
    .from("creator_profiles")
    .select("stripe_account_id")
    .eq("id", payout.creator_id)
    .maybeSingle();

  if (!creatorProfile?.stripe_account_id) {
    const { error: failErr } = await supabase
      .from("creator_payouts").update({ status: "failed" }).eq("id", payout_id);
    if (failErr) console.error("Failed to mark payout as failed:", failErr.message);
    return json({ error: "No Stripe account connected for this creator" }, 400);
  }

  // Initiate Stripe transfer
  const stripeRes = await fetch("https://api.stripe.com/v1/transfers", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${stripeKey}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      amount: String(amountCents),
      currency: "usd",
      destination: creatorProfile.stripe_account_id,
      description: `AppLoop payout ${payout.period_start} to ${payout.period_end}`,
    }),
  });

  const stripeData = await stripeRes.json();
  if (!stripeRes.ok) {
    const { error: failErr } = await supabase
      .from("creator_payouts").update({ status: "failed" }).eq("id", payout_id);
    if (failErr) console.error("Failed to mark payout as failed:", failErr.message);
    return json({ error: stripeData.error?.message ?? "Stripe transfer failed" }, 500);
  }

  // Mark paid
  const { error: paidErr } = await supabase.from("creator_payouts").update({
    status: "paid",
    stripe_transfer_id: stripeData.id,
  }).eq("id", payout_id);
  if (paidErr) {
    // Money moved but DB not updated — log critically
    console.error(`CRITICAL: Stripe transfer ${stripeData.id} succeeded but DB update failed:`, paidErr.message);
  }

  await supabase.from("creator_notifications").insert({
    user_id: payout.creator_id,
    type: "payout_processed",
    title: "Payout processed!",
    body: `$${Number(payout.amount_usd).toFixed(2)} has been sent to your account.`,
    metadata: { payout_id: payout.id, amount_usd: payout.amount_usd },
  });

  return json({ ok: true, transfer_id: stripeData.id });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
