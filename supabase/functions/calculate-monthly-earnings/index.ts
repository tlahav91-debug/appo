import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MIN_PAYOUT_USD = 10;

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const adminSecret = req.headers.get("x-admin-secret");
  if (!adminSecret || adminSecret !== Deno.env.get("ADMIN_SECRET")) {
    return json({ error: "Unauthorized" }, 401);
  }

  let body: { period_start?: string; period_end?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { period_start, period_end } = body;
  if (!period_start || !period_end) {
    return json({ error: "period_start and period_end are required (YYYY-MM-DD)" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Sum earnings per creator for the period
  const { data: earnings } = await supabase
    .from("creator_earnings")
    .select("creator_id, energy_gate_revenue_usd, subscription_share_usd")
    .gte("date", period_start)
    .lte("date", period_end);

  if (!earnings) return json({ error: "Failed to fetch earnings" }, 500);

  // TODO(PRD-047): subscription_share_usd always 0 until subscription attribution is built
  // Aggregate per creator
  const totals = new Map<string, number>();
  for (const row of earnings) {
    const prev = totals.get(row.creator_id) ?? 0;
    totals.set(
      row.creator_id,
      prev + Number(row.energy_gate_revenue_usd) + Number(row.subscription_share_usd)
    );
  }

  const payouts: { creator_id: string; amount: number }[] = [];
  for (const [creator_id, amount] of totals.entries()) {
    if (amount >= MIN_PAYOUT_USD) {
      payouts.push({ creator_id, amount });
    }
  }

  if (payouts.length === 0) return json({ ok: true, payouts_created: 0 });

  const { error: insertErr } = await supabase.from("creator_payouts").upsert(
    payouts.map(p => ({
      creator_id: p.creator_id,
      period_start,
      period_end,
      amount_usd: p.amount.toFixed(2),
      status: "pending",
    })),
    { onConflict: "creator_id,period_start,period_end", ignoreDuplicates: true }
  );

  if (insertErr) return json({ error: insertErr.message }, 500);

  return json({ ok: true, payouts_created: payouts.length });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
